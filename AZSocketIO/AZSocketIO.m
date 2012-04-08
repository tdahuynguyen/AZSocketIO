//
//  AZSocketIO.m
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Rally Software. All rights reserved.
//

#import "AZSocketIO.h"
#import "AFHTTPClient.h"
#import "AZSocketIOTransport.h"
#import "AZWebsocketTransport.h"
#import "AZSocketIOPacket.h"

#define PROTOCOL_VERSION @"1"

@interface AZSocketIO ()
@property(nonatomic, strong)ConnectedBlock connectionBlock;

@property(nonatomic, strong)AFHTTPClient *httpClient;
@property(nonatomic, strong)id<AZSocketIOTransport> transport;
@end

@implementation AZSocketIO
@synthesize host;
@synthesize port;
@synthesize transports;
@synthesize sessionId;
@synthesize connected;

@synthesize messageRecievedBlock;
@synthesize eventRecievedBlock;
@synthesize disconnectedBlock;

@synthesize connectionBlock;
@synthesize httpClient;
@synthesize transport;
- (id)initWithHost:(NSString *)_host andPort:(NSString *)_port
{
    self = [super init];
    if (self) {
        self.host = _host;
        self.port = _port;
        self.httpClient = [[AFHTTPClient alloc] initWithBaseURL:nil];
        self.connected = [[NSCondition alloc] init];
    }
    return self;
}

- (void)connectWithSuccess:(ConnectedBlock)success andFailure:(FailedConnectionBlock)failure
{
    self.connectionBlock = success;
    NSString *urlString = [NSString stringWithFormat:@"http://%@:%@/socket.io/%@", 
                           self.host, self.port, PROTOCOL_VERSION];
    [self.httpClient getPath:urlString
                  parameters:nil
                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                         NSString *response = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                         NSArray *msg = [response componentsSeparatedByString:@":"];
                         if ([msg count] < 4) {
                             NSLog(@"NO DIS IS BAD");
                         }
                         self.sessionId = [msg objectAtIndex:0];
                         self.transports = [[msg objectAtIndex:3] componentsSeparatedByString:@","];
                         [self connectViaTransport:[self.transports objectAtIndex:0]];
                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                         failure(error);
                     }];
}

- (void)connectViaTransport:(NSString*)transportType 
{
    if ([transportType isEqualToString:@"websocket"]) {
        self.transport = [[AZWebsocketTransport alloc] initWithDelegate:self];
        [self.transport connect];
    } else {
        NSLog(@"Transport not implemented");
    }
}


#pragma mark AZSocketIOTransportDelegate
- (void)didReceiveMessage:(NSString *)message
{
    AZSocketIOPacket *packet = [[AZSocketIOPacket alloc] initWithString:message];
    id outData;
    switch (packet.type) {
        case 0: //Disconnect
            [self.transport disconnect];
            break;
        case 1: //Connect
            if (self.connectionBlock) {
                self.connectionBlock();
                self.connectionBlock = nil;
            }
            break;
        case 2: //Heartbeat
            [self.transport send:message];
            break;
        case 3: //Message
            self.messageRecievedBlock(packet.data);
            break;
        case 4: //JSON message
            outData = [NSJSONSerialization JSONObjectWithData:[packet.data dataUsingEncoding:NSUTF8StringEncoding]        
                                                      options:NSJSONReadingMutableContainers 
                                                        error:nil];
            self.messageRecievedBlock(outData);
            break;
        case 5: //Event
            outData = [NSJSONSerialization JSONObjectWithData:[packet.data dataUsingEncoding:NSUTF8StringEncoding]        
                                                      options:NSJSONReadingMutableContainers 
                                                        error:nil];
            self.eventRecievedBlock([outData objectForKey:@"name"], [outData objectForKey:@"args"]);
            break;
        case 6: //ACK
            NSLog(@"ACK");
            break;
        case 7: //Error
            NSLog(@"Error");
            break;
        default:
            break;
    }
}

- (void)didClose
{
    if (self.disconnectedBlock) {
        self.disconnectedBlock();
    }
}

- (void)didOpen{}
@end
