//
//  AZWebsocketTransport.m
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright 2012 Patrick Shields
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "AZWebsocketTransport.h"
#import "AZSocketIOTransportDelegate.h"
#import "SRWebSocket.h"


@interface AZWebsocketTransport () <SRWebSocketDelegate>
@property(nonatomic, strong) SRWebSocket *websocket;
@property(nonatomic, weak) id<AZSocketIOTransportDelegate> delegate;
@property(nonatomic, assign) BOOL connected;
@end

@implementation AZWebsocketTransport

@synthesize delegate          = _delegate;
@synthesize connected         = _connected;
@synthesize secureConnections = _secureConnections;

- (void)dealloc
{
    [self disconnect];
}

#pragma mark - AZSocketIOTransport

- (id)initWithDelegate:(id<AZSocketIOTransportDelegate>)delegate secureConnections:(BOOL)secureConnections
{
    self = [super init];
    if (self) {
        _connected = NO;
        
        _delegate          = delegate;
        _secureConnections = secureConnections;
        
        NSURLRequest *request = ({
            NSString *path = [NSString stringWithFormat:@"/socket.io/1/websocket/%@", [self.delegate sessionId]];
            NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
            urlComponents.scheme = secureConnections ? @"wss" : @"ws";
            urlComponents.host   = [_delegate host];
            urlComponents.port   = @([self.delegate port]);
            urlComponents.path   = path;
            
            [NSURLRequest requestWithURL:[urlComponents URL]];
        });
        
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
    if ([self.delegate respondsToSelector:@selector(didSendMessage)]) {
        [self.delegate didSendMessage];
    }
}
- (void)disconnect
{
    self.websocket.delegate = nil;
    [self.websocket close];
    self.websocket = nil;
    [self webSocket:self.websocket didCloseWithCode:0 reason:@"Client requested disconnect" wasClean:YES];
    self.connected = NO;
}

#pragma mark SRWebSocketDelegate
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(NSString *)message
{
    [self.delegate didReceiveMessage:message];
}
- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    self.connected = YES;
    if ([self.delegate respondsToSelector:@selector(didOpen)]) {
        [self.delegate didOpen];
    }
}
- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    if (!self.connected || wasClean) {
        if ([self.delegate respondsToSelector:@selector(didClose)]) {
            [self.delegate didClose];
        }
    } else { // Socket disconnections can be errors, but with socket.io was clean always seems to be false, so we'll check on our own
        [self webSocket:webSocket didFailWithError:nil];
    }
}
- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    self.connected = NO;
    [self.delegate didFailWithError:error];
}
@end
