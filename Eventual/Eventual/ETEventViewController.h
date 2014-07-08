//
//  ETEventViewController.h
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/21/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EKEvent;

@interface ETEventViewController : UIViewController

@property (nonatomic, strong) EKEvent *event;

@end
