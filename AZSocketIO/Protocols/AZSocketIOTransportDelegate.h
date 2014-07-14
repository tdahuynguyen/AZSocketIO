//
//  AZSocketIOTransportDelegate.h
//  AZSocketIO
//
//  Created by Patrick Shields on 8/9/11.
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

#import <Foundation/Foundation.h>

@protocol AZSocketIOTransport;

/**
 The `AZSocketIOTransportDelegate` protocol allows the adopting delegate to respond to messages from an `AZSocketIOTransport`.
 */
@protocol AZSocketIOTransportDelegate <NSObject>
@optional

///-------------------------------------------
/// @name Informing Delegate of Status Changes
///-------------------------------------------

/**
 Tells the delegate that the transport has opened.
 */
- (void)transportDidOpenConnection:(id<AZSocketIOTransport>)transport;

/**
 Tells the delegate that the transport has closed.
 */
- (void)transportDidCloseConnection:(id<AZSocketIOTransport>)transport;

/**
 Tells the delegate that the transport sent a message.
 */
- (void)transportDidSendMessage:(id <AZSocketIOTransport>)transport;

@required

/**
 Tells the delegate that the transport has failed.
 
 @param error An instance of `NSError` that describes the problem.
 */
- (void)transport:(id<AZSocketIOTransport>)transport didFailWithError:(NSError *)error;

///--------------------------------------------
/// @name Receiving Messages From the Transport
///--------------------------------------------

/**
 Tells the delegate that message was received.
 
 @param message An `NSString` containing the message data.
 */
- (void)transport:(id <AZSocketIOTransport>)transport didReceiveMessage:(NSString *)message;

///---------------------------------------------------------
/// @name Supplying Connection Information From the Delegate
///---------------------------------------------------------

/**
 Allows the transport to retrieve the hostname of the socket.io server.
 
 @return The socket.io server hostname.
 */
- (NSString*)host;

/**
 Allows the transport to retrieve the port the socket.io server is running on.
 
 @return The socket.io server port.
 */
- (uint16_t)port;

/**
 Allows the transport to retrieve the current session id.
 
 @return The current session Id.
 */
- (NSString*)sessionId;
@end
