//
//  AZSocketIONamespaceTests.m
//  AZSocketIO
//
//  Created by Luca Bernardi on 22/04/13.
//  Copyright (c) 2013 Patrick Shields. All rights reserved.
//

#import "Kiwi.h"
#import "AZSocketIO.h"

NSString * const kNamespaceName = @"/test";

SPEC_BEGIN(NamespaceTest)

describe(@"The socket", ^{
    __block AZSocketIO *socket = nil;
    
    context(@"when created", ^{
        it(@"should be constructable", ^{
            socket = [[AZSocketIO alloc] initWithHost:@"localhost"
                                              andPort:@"9000"
                                               secure:NO
                                        withNamespace:kNamespaceName];
            [socket shouldNotBeNil];
        });
        it(@"should have the right namespace", ^{
            [[socket.endpoint should] equal:kNamespaceName];
        });
    });
    
    context(@"when connected", ^{
        __block NSString *name;
        __block NSNumber *connected;
        it(@"should connect", ^{
            [socket connectWithSuccess:^{
                connected = @(YES);
                socket.eventRecievedBlock = ^(NSString *_name, id _args) {
                    name = _name;
                };
            } andFailure:^(NSError *error) {
                connected = @(NO);
            }];
            
            [[expectFutureValue(connected) shouldEventually] equal:@(YES)];
            
        });
        it(@"recieves an initial event", ^{
            [[expectFutureValue(name) shouldEventually] equal:@"namspaced_event"];
        });
        it(@"should say it's connected", ^{
            [[theValue(socket.state) should] equal:@(AZSocketIOStateConnected)];
        });
    });
});
SPEC_END