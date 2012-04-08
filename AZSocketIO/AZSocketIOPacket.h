//
//  AZSocketIOPacket.h
//  AZSocketIO
//
//  Created by Patrick Shields on 4/7/12.
//  Copyright (c) 2012 Rally Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AZSocketIOPacket : NSObject
@property(nonatomic, assign)int type;
@property(nonatomic, strong)NSString *Id;
@property(nonatomic, assign)BOOL ack;
@property(nonatomic, strong)NSString *endpoint;
@property(nonatomic, strong)id data;

- (id)initWithString:(NSString *)packetString;
- (NSString *)encode;
@end
