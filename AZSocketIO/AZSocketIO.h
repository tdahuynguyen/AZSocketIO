//
//  AZSocketIO.h
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Rally Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZsocketIOTransportDelegate.h"

#define AZDOMAIN @"AZSocketIO"

typedef void (^MessageRecievedBlock)(id data);
typedef void (^EventRecievedBlock)(NSString *eventName, id data);
typedef void (^ConnectedBlock)();
typedef void (^FailedConnectionBlock)(NSError *error);
typedef void (^DisconnectedBlock)();

@interface AZSocketIO : NSObject <AZSocketIOTransportDelegate>
@property(nonatomic, strong)NSString *host;
@property(nonatomic, strong)NSString *port;
@property(nonatomic, strong)NSArray *transports;
@property(nonatomic, strong)NSString *sessionId;
@property(nonatomic, strong)NSCondition *connected;
@property(nonatomic, assign)NSInteger heartbeatInterval;
@property(nonatomic, assign)NSInteger disconnectInterval;

@property(nonatomic, copy)MessageRecievedBlock messageRecievedBlock;
@property(nonatomic, copy)EventRecievedBlock eventRecievedBlock;
@property(nonatomic, copy)DisconnectedBlock disconnectedBlock;
- (id)initWithHost:(NSString *)host andPort:(NSString *)port;
- (void)connectWithSuccess:(ConnectedBlock)success andFailure:(FailedConnectionBlock)failure;
- (BOOL)send:(id)data error:(NSError * __autoreleasing *)error;
- (BOOL)emit:(NSString *)name args:(id)args error:(NSError * __autoreleasing *)error;
@end
