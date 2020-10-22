//
//  AZxhrTransport.m
//  AZSocketIO
//
//  Created by Patrick Shields on 5/15/12.
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

#import "AZxhrTransport.h"
#import "AFHTTPSessionManager.h"
#import "AZSocketIOTransportDelegate.h"

@interface AZxhrTransport ()
@property(nonatomic, weak)id<AZSocketIOTransportDelegate> delegate;
@property(nonatomic, readwrite, assign)BOOL connected;
@end

@implementation AZxhrTransport
@synthesize client;
@synthesize secureConnections;
@synthesize delegate;
@synthesize connected;
- (void)connect
{
    [self.client GET:@""
          parameters:nil
             headers:nil
            progress:nil
             success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.connected = YES;
        if ([self.delegate respondsToSelector:@selector(didOpen)]) {
            [self.delegate didOpen];
        }
        NSString *responseString = [self stringFromData:responseObject];
        NSArray *messages = [responseString componentsSeparatedByString:@"\ufffd"];
        if ([messages count] > 0) {
            for (NSString *message in messages) {
                [self.delegate didReceiveMessage:message];
            }
        } else {
            [self.delegate didReceiveMessage:responseString];
        }
        
        if (self.connected) {
            [self connect];
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        [self.delegate didFailWithError:error];
        if ([self.delegate respondsToSelector:@selector(didClose)]) {
            [self.delegate didClose];
        }
    }];
    
}
- (void)disconnect
{
    [self.client.operationQueue cancelAllOperations];
    [self.client GET:@"?disconnect"
          parameters:nil
             headers:nil
            progress:nil
             success:nil
             failure:nil];
    
    self.connected = NO;
    if ([self.delegate respondsToSelector:@selector(didClose)]) {
        [self.delegate didClose];
    }
}
- (void)send:(NSString*)msg
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.client.baseURL];
    request.HTTPMethod = @"POST";
    [request setHTTPBody:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    
    [self.client dataTaskWithRequest:request
                      uploadProgress:nil
                    downloadProgress:nil
                   completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        if (error) {
            [self.delegate didFailWithError:error];
        } else if ([self.delegate respondsToSelector:@selector(didSendMessage)]) {
            [self.delegate didSendMessage];
        }
    }];
    
}
- (id)initWithDelegate:(id<AZSocketIOTransportDelegate>)_delegate secureConnections:(BOOL)_secureConnections
{
    self = [super init];
    if (self) {
        self.connected = NO;
        self.delegate = _delegate;
        self.secureConnections = _secureConnections;
        
        NSString *protocolString = self.secureConnections ? @"https://" : @"http://";
        NSString *urlString = [NSString stringWithFormat:@"%@%@:%@/socket.io/1/xhr-polling/%@",
                               protocolString, [self.delegate host], [self.delegate port],
                               [self.delegate sessionId]];
        self.client = [[AFHTTPSessionManager alloc] initWithBaseURL:[NSURL URLWithString:urlString]];
        
        self.client.requestSerializer.stringEncoding = NSUTF8StringEncoding;
        self.client.responseSerializer = [AFHTTPResponseSerializer serializer];
        //self.client.responseSerializer.serializer = NSUTF8StringEncoding;
    }
    return self;
}
- (NSString *)stringFromData:(NSData *)data
{
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}
@end
