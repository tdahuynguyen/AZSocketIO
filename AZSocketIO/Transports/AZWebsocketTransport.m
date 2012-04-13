//
//  AZWebsocketTransport.m
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Patrick Shields. All rights reserved.
//

#import "AZWebsocketTransport.h"
#import "AZSocketIOTransportDelegate.h"

@interface AZWebsocketTransport ()
@property(nonatomic, strong)id<AZSocketIOTransportDelegate> delegate;
@property(nonatomic, readwrite, assign)BOOL connected;
@end

@implementation AZWebsocketTransport
@synthesize websocket;
@synthesize delegate;
@synthesize connected;

#pragma mark AZSocketIOTransport
- (id)initWithDelegate:(id<AZSocketIOTransportDelegate>)_delegate
{
    self = [super init];
    if (self) {
        self.connected = NO;
        self.delegate = _delegate;
        NSString *urlString = [NSString stringWithFormat:@"ws://%@:%@/socket.io/1/websocket/%@",
                         [self.delegate host], [self.delegate port], [self.delegate sessionId]];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
        self.websocket = [[SRWebSocket alloc] initWithURLRequest:request];
        self.websocket.delegate = self;
    }
    return self;
}
- (void)connect
{
    [self.websocket open];
}
- (void)send:(NSString *)msg
{
    [self.websocket send:msg];
}
- (void)disconnect
{
    [self.websocket close];
}

#pragma mark SRWebSocketDelegate
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString *)message
{
    [self.delegate didReceiveMessage:message];
}
- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    self.connected = YES;
    [self.delegate didOpen];
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    self.connected = NO;
    [self.delegate didClose];
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    self.connected = NO;
    [self.delegate didFailWithError:error];
}
@end
