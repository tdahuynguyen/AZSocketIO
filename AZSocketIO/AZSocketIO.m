//
//  AZSocketIO.m
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Patrick Shields. All rights reserved.
//

#import "AZSocketIO.h"
#import "AFHTTPClient.h"
#import "AFJSONUtilities.h"
#import "AZSocketIOTransport.h"
#import "AZWebsocketTransport.h"
#import "AZSocketIOPacket.h"

#define PROTOCOL_VERSION @"1"

@interface AZSocketIO ()
@property(nonatomic, strong)ConnectedBlock connectionBlock;

@property(nonatomic, strong)AFHTTPClient *httpClient;
@property(nonatomic, strong)id<AZSocketIOTransport> transport;

@property(nonatomic, strong)NSMutableDictionary *ackCallbacks;
@property(nonatomic, assign)NSInteger ackCount;
@property(nonatomic, strong)NSTimer *heartbeatTimer;
@end

@implementation AZSocketIO
@synthesize host;
@synthesize port;
@synthesize transports;
@synthesize sessionId;
@synthesize heartbeatInterval;
@synthesize disconnectInterval;

@synthesize messageRecievedBlock;
@synthesize eventRecievedBlock;
@synthesize disconnectedBlock;
@synthesize errorMessageBlock;

@synthesize connectionBlock;
@synthesize httpClient;
@synthesize transport;

@synthesize ackCallbacks;
@synthesize ackCount;
@synthesize heartbeatTimer;

- (id)initWithHost:(NSString *)_host andPort:(NSString *)_port
{
    self = [super init];
    if (self) {
        self.host = _host;
        self.port = _port;
        self.httpClient = [[AFHTTPClient alloc] initWithBaseURL:nil];
        self.ackCallbacks = [NSMutableDictionary dictionary];       
        self.ackCount = 0;
    }
    return self;
}

#pragma mark connection management
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
                             NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
                             [errorDetail setValue:@"Server handshake message could not be decoded" forKey:NSLocalizedDescriptionKey];
                             failure([NSError errorWithDomain:AZDOMAIN code:100 userInfo:errorDetail]);
                         }
                         self.sessionId = [msg objectAtIndex:0];
                         self.heartbeatInterval = [[msg objectAtIndex:1] intValue];
                         self.disconnectInterval = [[msg objectAtIndex:2] intValue];
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

- (void)disconnect
{
    [self.transport disconnect];
}

#pragma mark data sending
- (BOOL)send:(id)data error:(NSError *__autoreleasing *)error ack:(ACKCallback)callback
{
    AZSocketIOPacket *packet = [[AZSocketIOPacket alloc] init];
    
    if (![data isKindOfClass:[NSString class]]) {
        NSData *jsonData = AFJSONEncode(data, error);
        if (jsonData == nil) {
            return NO;
        }
        
        packet.data = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        packet.type = JSON_MESSAGE;
    } else {
        packet.data = data;
        packet.type = MESSAGE;
    }
    
    if (callback != NULL) {
        packet.Id = [NSString stringWithFormat:@"%d", ackCount++];
        [self.ackCallbacks setObject:callback forKey:packet.Id];
        packet.Id = [packet.Id stringByAppendingString:@"+"];
    }
    
    return [self sendPacket:packet error:error];
}

- (BOOL)send:(id)data error:(NSError *__autoreleasing *)error
{        
    return [self send:data error:error ack:NULL];
}

- (BOOL)emit:(NSString *)name args:(id)args error:(NSError *__autoreleasing *)error ack:(ACKCallback)callback
{
    AZSocketIOPacket *packet = [[AZSocketIOPacket alloc] init];
    packet.type = EVENT;
    
    NSMutableDictionary *data = [NSMutableDictionary dictionaryWithObjectsAndKeys:name, @"name", args, @"args", nil];
    NSData *jsonData = AFJSONEncode(data, error);
    if (jsonData == nil) {
        return NO;
    }
    
    packet.data = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    packet.Id = [NSString stringWithFormat:@"%d", ackCount++];
    
    if (callback != NULL) {
        [self.ackCallbacks setObject:callback forKey:packet.Id];
        packet.Id = [packet.Id stringByAppendingString:@"+"];
    }
    
    return [self sendPacket:packet error:error];
}

- (BOOL)emit:(NSString *)name args:(id)args error:(NSError * __autoreleasing *)error
{
    return [self emit:name args:args error:error ack:NULL];
}

- (BOOL)sendPacket:(AZSocketIOPacket *)packet error:(NSError * __autoreleasing *)error
{
    if (self.transport && [self.transport isConnected]) {
        [self.transport send:[packet encode]];
    } else {
        if (error != NULL) {
            NSMutableDictionary *errorDetail = [NSMutableDictionary dictionary];
            [errorDetail setValue:@"Not yet connected" forKey:NSLocalizedDescriptionKey];
            *error = [NSError errorWithDomain:AZDOMAIN code:100 userInfo:errorDetail];
            return NO;
        }
    }
    
    return YES;
}

#pragma mark heartbeat
- (void)clearHeartbeatTimeout
{
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer = nil;
}
- (void)startHeartbeatTimeout
{
    [self clearHeartbeatTimeout];
    self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:self.heartbeatInterval
                                                           target:self
                                                         selector:@selector(heartbeatTimeout) 
                                                         userInfo:nil
                                                          repeats:NO];
}
- (void)heartbeatTimeout
{
    // TODO: Add reconnect support
    [self disconnect];
}
#pragma mark AZSocketIOTransportDelegate
- (void)didReceiveMessage:(NSString *)message
{
    [self startHeartbeatTimeout];
    AZSocketIOPacket *packet = [[AZSocketIOPacket alloc] initWithString:message];
    id outData; AZSocketIOACKMessage *ackMessage; ACKCallback callback;
    switch (packet.type) {
        case DISCONNECT:
            [self disconnect];
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
            outData = AFJSONDecode([packet.data dataUsingEncoding:NSUTF8StringEncoding], nil);
            self.messageRecievedBlock(outData);
            break;
        case EVENT:
            outData = AFJSONDecode([packet.data dataUsingEncoding:NSUTF8StringEncoding], nil);
            self.eventRecievedBlock([outData objectForKey:@"name"], [outData objectForKey:@"args"]);
            break;
        case ACK:
            ackMessage = [[AZSocketIOACKMessage alloc] initWithPacket:packet];
            callback = [self.ackCallbacks objectForKey:ackMessage.messageId];
            if (callback != NULL) {
                callback(ackMessage.args);
            }
            [self.ackCallbacks removeObjectForKey:ackMessage.messageId];
            break;
        case ERROR:
            if (self.errorMessageBlock) {
                self.errorMessageBlock(packet.data);
            }
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
