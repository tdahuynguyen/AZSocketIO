//
//  AZWebsocketTransport.m
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Rally Software. All rights reserved.
//

#import "AZWebsocketTransport.h"
#import "AZSocketIOTransportDelegate.h"

@interface AZWebsocketTransport ()
@property(nonatomic, strong)id<AZSocketIOTransportDelegate> delegate;
@end

@implementation AZWebsocketTransport
@synthesize websocket;
@synthesize delegate;

#pragma mark AZSocketIOTransport
- (id)initWithDelegate:(id<AZSocketIOTransportDelegate>)_delegate
{
    self = [super init];
    if (self) {
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
    [self.delegate didOpen];
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    [self.delegate didClose];
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    [self.delegate didFailWithError:error];
}
@end
