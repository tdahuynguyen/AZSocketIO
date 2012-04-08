//
//  ISocketTransport.h
//  isocket
//
//  Created by Patrick Shields on 8/9/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZSocketIOTransportDelegate.h"

@protocol AZSocketIOTransport
@required
- (void)connect;
- (void)setDelegate:(id<AZSocketIOTransportDelegate>)delegate;
- (void)disconnect;
- (void)send:(NSString*)msg;
- (id)initWithDelegate:(id<AZSocketIOTransportDelegate>)delegate;
@end
