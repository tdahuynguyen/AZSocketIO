//
//  AZSocketIO.h
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Patrick Shields. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZsocketIOTransportDelegate.h"

#define AZDOMAIN @"AZSocketIO"

typedef void (^MessageRecievedBlock)(id data);
typedef void (^EventRecievedBlock)(NSString *eventName, id data);
typedef void (^ConnectedBlock)();
typedef void (^FailedConnectionBlock)(NSError *error);
typedef void (^DisconnectedBlock)();
typedef void (^ErrorMessageBlock)(NSString *data);

typedef void (^ACKCallback)(NSArray *args);

@interface AZSocketIO : NSObject <AZSocketIOTransportDelegate>
@property(nonatomic, strong)NSString *host;
@property(nonatomic, strong)NSString *port;
@property(nonatomic, assign)BOOL secureConnections;
@property(nonatomic, strong)NSArray *transports;
@property(nonatomic, strong)NSString *sessionId;
@property(nonatomic, assign)NSInteger heartbeatInterval;
@property(nonatomic, assign)NSInteger disconnectInterval;

@property(nonatomic, readonly)BOOL isConnected;

@property(nonatomic, copy)MessageRecievedBlock messageRecievedBlock;
@property(nonatomic, copy)EventRecievedBlock eventRecievedBlock;
@property(nonatomic, copy)DisconnectedBlock disconnectedBlock;
@property(nonatomic, copy)ErrorMessageBlock errorMessageBlock;

- (id)initWithHost:(NSString *)host andPort:(NSString *)port;
- (void)connectWithSuccess:(void (^)())success andFailure:(void (^)(NSError *error))failure;
- (BOOL)send:(id)data error:(NSError *__autoreleasing *)error ack:(void (^)(NSArray *data))callback;
- (BOOL)send:(id)data error:(NSError * __autoreleasing *)error;
- (BOOL)emit:(NSString *)name args:(id)args error:(NSError *__autoreleasing *)error ack:(void (^)(NSArray *data))callback;
- (BOOL)emit:(NSString *)name args:(id)args error:(NSError * __autoreleasing *)error;
- (void)disconnect;

- (void)addCallbackForEventName:(NSString *)name callback:(void (^)(NSString *eventName, id data))block;
- (BOOL)removeCallbackForEvent:(NSString *)name callback:(void (^)(NSString *eventName, id data))block;
- (NSInteger)removeCallbacksForEvent:(NSString *)name;

#pragma mark overridden setters
- (void)setMessageRecievedBlock:(void (^)(id data))messageRecievedBlock;
- (void)setEventRecievedBlock:(void (^)(NSString *eventName, id data))eventRecievedBlock;
- (void)setDisconnectedBlock:(void (^)())disconnectedBlock;
- (void)setErrorMessageBlock:(void (^)(NSString *data))errorMessageBlock;
@end
