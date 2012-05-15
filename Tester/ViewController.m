//
//  ViewController.m
//  Tester
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Patrick Shields. All rights reserved.
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
    __weak AZSocketIO *blockSocket = socket;
    [socket connectWithSuccess:^{
        NSLog(@"Hurray");
        [socket setEventRecievedBlock:^(NSString *eventName, id data) {
            self.name.text = eventName;
            self.args.text = [data description];
            [blockSocket send:@"Hi" error:nil];
        }];
    } andFailure:^(NSError *error) {
        NSLog(@"Boo: %@", error);
    }];
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
