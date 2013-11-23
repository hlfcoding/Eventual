//
//  ETEventViewController.m
//  Eventual
//
//  Created by Nest Master on 11/21/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETEventViewController.h"

#import <EventKit/EKEvent.h>

#import "ETAppDelegate.h"

@interface ETEventViewController ()

<UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *dayLabel;
@property (strong, nonatomic) IBOutlet UITextView *descriptionView;
@property (strong, nonatomic) IBOutlet UIToolbar *editToolbar;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomEdgeConstraint;

- (IBAction)editDoneAction:(id)sender;

- (void)setUp;
- (void)updateSubviews;
- (void)updateOnKeyboardAppearanceWithNotification:(NSNotification *)notification;

- (void)saveData;

@end

@implementation ETEventViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) [self setUp];
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) [self setUp];
  return self;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view.
  ETAppDelegate *stylesheet = [UIApplication sharedApplication].delegate;
  self.dayLabel.textColor = stylesheet.lightGrayTextColor;
  [self updateSubviews];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - UITextViewDelegate

#pragma mark - Actions

- (IBAction)editDoneAction:(id)sender
{
  if ([self.descriptionView isFirstResponder]) {
    [self.descriptionView resignFirstResponder];
  }
  [self saveData];
}

#pragma mark - Public

#pragma mark - Private

- (void)setUp
{
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnKeyboardAppearanceWithNotification:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnKeyboardAppearanceWithNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)updateSubviews
{
  self.dayLabel.text = self.dayLabel.text.uppercaseString;
}

- (void)updateOnKeyboardAppearanceWithNotification:(NSNotification *)notification
{
  CGFloat constant = 0.0f;
  if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
    CGRect frame = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    constant = frame.size.height > frame.size.width ? frame.size.width : frame.size.height;
  }
  self.toolbarBottomEdgeConstraint.constant = constant;
  [self.view setNeedsUpdateConstraints];
  // TODO: Flawless animation sync.
  [UIView animateWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue]
                        delay:0.0f
                      options:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]
                   animations:^{ [self.view layoutIfNeeded]; }
                   completion:nil];
}

- (void)saveData
{
  // TODO: Save.
  [self.navigationController popViewControllerAnimated:YES];
}

@end
