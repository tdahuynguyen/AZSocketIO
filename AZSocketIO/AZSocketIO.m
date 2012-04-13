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

- (void)send:(id)data error:(NSError *__autoreleasing *)error
{        
    AZSocketIOPacket *packet = [[AZSocketIOPacket alloc] init];
    
    if (![data isKindOfClass:[NSString class]]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                           options:0
                                                             error:error];
        NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                     encoding:NSUTF8StringEncoding];
        packet.data = jsonString;
        packet.type = JSON_MESSAGE;
    } else {
        packet.data = data;
        packet.type = MESSAGE;
    }
    
    [self sendPacket:packet error:error];
}

- (void)emit:(NSString *)name args:(id)args error:(NSError * __autoreleasing *)error
{
    AZSocketIOPacket *packet = [[AZSocketIOPacket alloc] init];
    packet.type = EVENT;
    
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:name, @"name", args, @"args", nil];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                       options:0
                                                         error:error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData
                                                 encoding:NSUTF8StringEncoding];
    
    packet.data = jsonString;
    
    [self sendPacket:packet error:error];
}

- (void)sendPacket:(AZSocketIOPacket *)packet error:(NSError * __autoreleasing *)error
{
    if (self.transport && [self.transport isConnected]) {
        [self.transport send:[packet encode]];
    } else {
        NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
        [errorDetail setValue:@"Not yet connected" forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:AZDOMAIN code:100 userInfo:errorDetail];
    }
}
#pragma mark AZSocketIOTransportDelegate
- (void)didReceiveMessage:(NSString *)message
{
    AZSocketIOPacket *packet = [[AZSocketIOPacket alloc] initWithString:message];
    id outData;
    switch (packet.type) {
        case DISCONNECT:
            [self.transport disconnect];
            break;
        case CONNECT:
            if (self.connectionBlock) {
                self.connectionBlock();
                self.connectionBlock = nil;
            }
            break;
        case HEARTBEAT:
            [self.transport send:message];
            break;
        case MESSAGE:
            self.messageRecievedBlock(packet.data);
            break;
        case JSON_MESSAGE:
            outData = [NSJSONSerialization JSONObjectWithData:[packet.data dataUsingEncoding:NSUTF8StringEncoding]        
                                                      options:NSJSONReadingMutableContainers 
                                                        error:nil];
            self.messageRecievedBlock(outData);
            break;
        case EVENT:
            outData = [NSJSONSerialization JSONObjectWithData:[packet.data dataUsingEncoding:NSUTF8StringEncoding]        
                                                      options:NSJSONReadingMutableContainers 
                                                        error:nil];
            self.eventRecievedBlock([outData objectForKey:@"name"], [outData objectForKey:@"args"]);
            break;
        case ACK:
            NSLog(@"ACK");
            break;
        case ERROR:
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
