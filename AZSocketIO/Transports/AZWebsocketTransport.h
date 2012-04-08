//
//  AZWebsocketTransport.h
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Rally Software. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "AZSocketIOTransport.h"
#import "SRWebSocket.h"

@interface AZWebsocketTransport : NSObject <AZSocketIOTransport, SRWebSocketDelegate>
@property(nonatomic, strong)SRWebSocket *websocket;
@end
