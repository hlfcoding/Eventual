//
//  ETMonthHeaderView.h
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/6/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ETMonthHeaderView : UICollectionReusableView

@property (nonatomic, strong, setter = setMonthName:) NSString *monthName;

@end
