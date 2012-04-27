//
//  AZSocketIOTests.m
//  AZSocketIO
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Patrick Shields. All rights reserved.
//

#import "Kiwi.h"
#import "AZSocketIO.h"

SPEC_BEGIN(Tests)
describe(@"The socket", ^{
    __block AZSocketIO *socket;
    context(@"before connection", ^{
        it(@"should be constructable", ^{
            socket = [[AZSocketIO alloc] initWithHost:@"localhost" andPort:@"9000"];
            [socket shouldNotBeNil];
        });
        it(@"should queue messages", ^{
            NSError *error = nil;
            [[theValue([socket send:@"Hi" error:&error]) should] beTrue];
            [error shouldBeNil];
        });
    });
    context(@"when connecting", ^{
        __block NSDictionary *args;
        __block NSNumber *connected;
        it(@"can connect", ^{
            [socket connectWithSuccess:^{
                connected = [NSNumber numberWithBool:YES];
                socket.eventRecievedBlock = ^(NSString *name, id _args) {
                    args = _args;
                };
            } andFailure:^(NSError *error) {
                connected = [NSNumber numberWithBool:NO];
            }];
            [[expectFutureValue(connected) shouldEventually] equal:[NSNumber numberWithBool:YES]];
        });
        it(@"recieves an initial event", ^{
            [[expectFutureValue(args) shouldEventually] beNonNil];
        });
    });
    context(@"after connecting", ^{
        it(@"can send a message and recieve the return val", ^{
            __block NSString *sent = @"FOO";
            __block NSString *recieved;
            socket.eventRecievedBlock = ^(NSString *name, id _args) {
                recieved = [_args objectAtIndex:0];
            };
            [socket send:sent error:nil];
            [[expectFutureValue(recieved) shouldEventually] equal:sent];
        });
        it(@"can send a json message and recieve the return val", ^{
            __block NSDictionary *sent = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];;
            __block NSDictionary *recieved;
            socket.eventRecievedBlock = ^(NSString *name, id _args) {
                recieved = [_args objectAtIndex:0];
            };
            [socket send:sent error:nil];
            [[expectFutureValue(recieved) shouldEventually] equal:sent];
        });
        it(@"can emit an event and recieve the return val", ^{
            __block NSString *name = @"ackLessEvent";
            __block NSArray *args = [NSArray arrayWithObject:@"bar"];
            __block NSString *recievedName;
            __block NSArray *recievedArgs;
            [socket addCallbackForEventName:name callback:^(NSString *eventName, id data) {
                recievedName = eventName;
                recievedArgs = data;
            }];
            [socket emit:name args:args error:nil];
            [[expectFutureValue(recievedName) shouldEventually] equal:name];
            [[expectFutureValue(recievedArgs) shouldEventually] equal:args];
        });
        it(@"can register an ack callback", ^{
            __block NSString *name;
            [socket emit:@"ackWithArg" args:@"kthx"
                   error:nil
                     ack:^(NSArray *args) {
                         name = [args objectAtIndex:0];
                     }];
            [[expectFutureValue(name) shouldEventually] equal:@"kthx"];
        });
        it(@"can recieve an empty ack callback", ^{
            __block BOOL empty;
            [socket emit:@"ackWithoutArgs" args:@"never going to see this"
                   error:nil
                     ack:^(NSArray *args) {
                         empty = (args == nil);
                     }];
            [[expectFutureValue(theValue(empty)) shouldEventually] beTrue];
        });
        it(@"can recieve an ack callback with multiple return values", ^{
            __block NSString *one;
            __block NSString *two;
            [socket emit:@"ackWithArgs" args:[NSArray arrayWithObjects:@"one", @"two", nil]
                   error:nil
                     ack:^(NSArray *args) {
                         one = [args objectAtIndex:0];
                         two = [args objectAtIndex:1];
                     }];
            [[expectFutureValue(one) shouldEventually] equal:@"one"];
            [[expectFutureValue(two) shouldEventually] equal:@"two"];
        });
    });
});
SPEC_END