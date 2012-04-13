//
//  AZWebsocketTransport.h
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Patrick Shields. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "AZSocketIOTransport.h"
#import "SRWebSocket.h"

@interface AZWebsocketTransport : NSObject <AZSocketIOTransport, SRWebSocketDelegate>
@property(nonatomic, strong)SRWebSocket *websocket;
@property(nonatomic, readonly, getter = isConnected)BOOL connected;
@end
