//
//  ViewController.m
//  Tester
//
//  Created by Patrick Shields on 4/6/12.
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

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize socket;
@synthesize name;
@synthesize args;
- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    socket = [[AZSocketIO alloc] initWithHost:@"localhost" andPort:@"9000"];
    //socket.transports = [NSMutableSet setWithObject:@"xhr-polling"];
    __weak UIViewController *blockSelf = self;
    [socket connectWithSuccess:^{
        NSLog(@"Hurray");
        [socket setEventRecievedBlock:^(NSString *eventName, id data) {
            self.name.text = eventName;
            self.args.text = [data description];
            [NSTimer scheduledTimerWithTimeInterval:1.0 target:blockSelf selector:@selector(sendTime) userInfo:nil repeats:NO];
        }];
    } andFailure:^(NSError *error) {
        NSLog(@"Boo: %@", error);
    }];
}

- (void)sendTime
{
    [socket send:[[NSDate new] description] error:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
