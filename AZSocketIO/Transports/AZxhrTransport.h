//
//  AZxhrTransport.h
//  AZSocketIO
//
//  Created by Patrick Shields on 5/15/12.
//  Copyright (c) 2012 Patrick Shields. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AZSocketIOTransport.h"
#import "AFHTTPClient.h"

@interface AZxhrTransport : NSObject <AZSocketIOTransport>
@property(nonatomic, strong)AFHTTPClient *client;
@end
