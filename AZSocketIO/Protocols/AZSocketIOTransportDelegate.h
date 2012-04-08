//
//  ISocketTransportDelegate.h
//  isocket
//
//  Created by Patrick Shields on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol AZSocketIOTransportDelegate
@optional
- (void)didFailWithError:(NSError*)error;
- (void)didOpen;
- (void)didClose;
- (void)didSendMessage;

@required
- (void)didReceiveMessage:(NSString*)message;
- (NSString*)host;
- (NSString*)port;
- (NSString*)sessionId;
@end
