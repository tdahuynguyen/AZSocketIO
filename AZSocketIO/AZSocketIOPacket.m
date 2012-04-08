//
//  AZSocketIOPacket.m
//  AZSocketIO
//
//  Created by Patrick Shields on 4/7/12.
//  Copyright (c) 2012 Rally Software. All rights reserved.
//

#import "AZSocketIOPacket.h"

@interface AZSocketIOPacket ()
+ (NSRegularExpression *)regex;
+ (NSString *)captureOrEmptyString:(NSString *)whole range:(NSRange)range;
@end

@implementation AZSocketIOPacket
@synthesize type;
@synthesize Id;
@synthesize ack;
@synthesize endpoint;
@synthesize data;

- (id)initWithString:(NSString *)packetString
{
    self = [super init];
    if (self) {
        NSTextCheckingResult *result = [[AZSocketIOPacket regex] firstMatchInString:packetString
                                                                            options:0 
                                                                              range:NSMakeRange(0, [packetString length])];
        
        NSString *typeString = [packetString substringWithRange:[result rangeAtIndex:1]];
        self.type = [typeString intValue];
        self.Id = [AZSocketIOPacket captureOrEmptyString:packetString range:[result rangeAtIndex:2]];
        
        if ([self.Id length] > 0) {
            self.ack = NO;
        } else {
            self.ack = YES;
        }
        
        self.endpoint =[AZSocketIOPacket captureOrEmptyString:packetString range:[result rangeAtIndex:4]];
        self.data = [AZSocketIOPacket captureOrEmptyString:packetString range:[result rangeAtIndex:5]];
    }
    return self;
}

+ (NSRegularExpression *)regex
{
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"([^:]+):([0-9]+)?(\\+)?:([^:]+)?:?([\\s\\S]*)?"
                                                          options:NSRegularExpressionCaseInsensitive
                                                            error:nil];
    });
    return regex;
}

+ (NSString *)captureOrEmptyString:(NSString *)whole range:(NSRange)range
{
    if (range.length <= 0) {
        return @"";
    } else {
        return [whole substringWithRange:range];
    }
}
@end
