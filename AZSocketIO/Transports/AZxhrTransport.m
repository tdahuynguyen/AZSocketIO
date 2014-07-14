//
//  AZXHRTransport.m
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

#import "AZXHRTransport.h"
#import <AFNetworking.h>
#import "AZSocketIOTransportDelegate.h"

@interface AZXHRTransport ()
@property(nonatomic, strong) AFHTTPRequestOperationManager *client;
@property(nonatomic, weak) id<AZSocketIOTransportDelegate> delegate;
@property(nonatomic, assign) BOOL connected;
@end


@implementation AZXHRTransport

@synthesize delegate          = _delegate;
@synthesize secureConnections = _secureConnections;

#pragma mark - Init & Dealloc

- (instancetype)init
{
    return [self initWithDelegate:nil secureConnections:NO];
}

#pragma mark - AZSocketIOTransport

- (instancetype)initWithDelegate:(id<AZSocketIOTransportDelegate>)delegate
               secureConnections:(BOOL)secureConnections
{
    self = [super init];
    if (self) {
        _delegate          = delegate;
        _secureConnections = secureConnections;
        _connected         = NO;

        NSURL *serverURL = ({
            NSString *path = [NSString stringWithFormat:@"/socket.io/1/xhr-polling/%@", [self.delegate sessionId]];
            NSURLComponents *urlComponents = [[NSURLComponents alloc] init];
            urlComponents.scheme = secureConnections ? @"https" : @"http";
            urlComponents.host   = [_delegate host];
            urlComponents.port   = @([self.delegate port]);
            urlComponents.path   = path;
            [urlComponents URL];
        });
        
        _client = [[AFHTTPRequestOperationManager alloc] initWithBaseURL:serverURL];
        _client.requestSerializer.stringEncoding  = NSUTF8StringEncoding;
        _client.responseSerializer                = [AFHTTPResponseSerializer serializer];
        _client.responseSerializer.stringEncoding = NSUTF8StringEncoding;
    }
    return self;
}

- (void)connect
{
    [self.client GET:@""
          parameters:nil
             success:^(AFHTTPRequestOperation *operation, id responseObject) {
                 self.connected = YES;
                 
                 id<AZSocketIOTransportDelegate> delegate = self.delegate;
                 
                 if ([delegate respondsToSelector:@selector(transportDidOpenConnection:)]) {
                     [delegate transportDidOpenConnection:self];
                 }
                 
                 NSString *responseString = [self stringFromData:responseObject];
                 NSArray *messages = [responseString componentsSeparatedByString:@"\ufffd"];
                 if ([messages count] > 0) {
                     for (NSString *message in messages) {
                         [delegate transport:self didReceiveMessage:message];
                     }
                 } else {
                     [delegate transport:self didReceiveMessage:responseString];
                 }
                 
                 if (self.connected) {
                     [self connect];
                 }
             }
             failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                 id<AZSocketIOTransportDelegate> delegate = self.delegate;
                 
                 [delegate transport:self didFailWithError:error];
                 
                 if ([delegate respondsToSelector:@selector(transportDidCloseConnection:)]) {
                     [delegate transportDidCloseConnection:nil];
                 }
             }];

}

- (void)disconnect
{
    [self.client.operationQueue cancelAllOperations];
    [self.client GET:@"?disconnect"
          parameters:nil
             success:nil
             failure:nil];
    
    self.connected = NO;
    id<AZSocketIOTransportDelegate> delegate = self.delegate;
    
    if ([delegate respondsToSelector:@selector(transportDidCloseConnection:)]) {
        [delegate transportDidCloseConnection:self];
    }
}

- (void)send:(NSString*)msg
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.client.baseURL];
    request.HTTPMethod = @"POST";
    [request setHTTPBody:[msg dataUsingEncoding:NSUTF8StringEncoding]];
    [request setValue:@"text/plain; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"Keep-Alive" forHTTPHeaderField:@"Connection"];
    
    [self.client HTTPRequestOperationWithRequest:request
                                         success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                             id<AZSocketIOTransportDelegate> delegate = self.delegate;
                                             if ([delegate respondsToSelector:@selector(transportDidSendMessage:)]) {
                                                 [delegate transportDidSendMessage:self];
                                             }
                                         }
                                         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                             id<AZSocketIOTransportDelegate> delegate = self.delegate;
                                             [delegate transport:self didFailWithError:error];
                                         }];
}

- (NSString *)stringFromData:(NSData *)data
{
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

@end
