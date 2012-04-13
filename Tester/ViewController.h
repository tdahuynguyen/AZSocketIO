//
//  ViewController.h
//  Tester
//
//  Created by Patrick Shields on 4/6/12.
//  Copyright (c) 2012 Patrick Shields. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AZSocketIO.h"

@interface ViewController : UIViewController
@property(nonatomic, strong)AZSocketIO *socket;
@property(nonatomic, strong)IBOutlet UILabel *name;
@property(nonatomic, strong)IBOutlet UILabel *args;
@end
