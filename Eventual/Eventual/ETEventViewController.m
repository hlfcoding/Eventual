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
#import "ETNavigationTitleScrollView.h"

// TODO: Date picker.
// TODO: Saving.
// TODO: Toolbar.

@interface ETEventViewController ()

<UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UILabel *dayLabel;
@property (strong, nonatomic) IBOutlet UITextView *descriptionView;
@property (strong, nonatomic) IBOutlet UIToolbar *editToolbar;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomEdgeConstraint;
@property (strong, nonatomic) IBOutlet ETNavigationTitleScrollView *titleView;

@property (strong, nonatomic) UIView *selectedTitleItem;
@property (strong, nonatomic) NSDateFormatter *dayFormatter;

@property (strong, nonatomic) NSString *todayIdentifier;
@property (strong, nonatomic) NSString *tomorrowIdentifier;
@property (strong, nonatomic) NSString *laterIdentifier;

- (IBAction)editDoneAction:(id)sender;

- (void)setUp;
- (void)setUpTitleView;
- (void)updateSubviews;
- (void)updateOnKeyboardAppearanceWithNotification:(NSNotification *)notification;

- (void)tearDown;

- (void)saveData;

- (NSDate *)dateFromDayIdentifier:(NSString *)identifier;

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
  [self tearDown];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
	// Do any additional setup after loading the view.
  [self setUpTitleView];
  ETAppDelegate *stylesheet = [UIApplication sharedApplication].delegate;
  self.dayLabel.textColor = stylesheet.lightGrayTextColor;
  self.titleView.textColor = stylesheet.darkGrayTextColor;
  self.selectedTitleItem = self.titleView.visibleItem;
  [self updateSubviews];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (context != ETContext) {
    return;
  }
  id previousValue = change[NSKeyValueChangeOldKey];
  id value = change[NSKeyValueChangeNewKey];
  if (object == self.titleView
      && [keyPath isEqualToString:NSStringFromSelector(@selector(visibleItem))]
      && value != previousValue
      ) {
    self.selectedTitleItem = (UIView *)value;
    [self updateSubviews];
  }
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
  self.dayFormatter = [[NSDateFormatter alloc] init];
  self.dayFormatter.dateFormat = @"MMMM d, y · EEEE";
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnKeyboardAppearanceWithNotification:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnKeyboardAppearanceWithNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)setUpTitleView
{
  self.todayIdentifier = NSLocalizedString(@"Today", nil);
  self.tomorrowIdentifier = NSLocalizedString(@"Tomorrow", nil);
  self.laterIdentifier = NSLocalizedString(@"Later", nil);
  self.titleView.accessibilityLabel = NSLocalizedString(ETEventScreenTitleLabel, nil);
  [self.titleView addItemOfType:ETNavigationItemTypeLabel withText:self.todayIdentifier];
  [self.titleView addItemOfType:ETNavigationItemTypeLabel withText:self.tomorrowIdentifier];
  [self.titleView addItemOfType:ETNavigationItemTypeButton withText:self.laterIdentifier];
  [self.titleView addObserver:self forKeyPath:NSStringFromSelector(@selector(visibleItem))
                      options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:ETContext];
  [self.titleView processItems];
}

- (void)updateSubviews
{
  NSString *dayIdentifier;
  if ([self.selectedTitleItem isKindOfClass:[UIButton class]]) {
    dayIdentifier = [(UIButton *)self.selectedTitleItem titleForState:UIControlStateNormal];
  } else {
    dayIdentifier = ((UILabel *)self.selectedTitleItem).text;
  }
  self.dayLabel.text = [self.dayFormatter stringFromDate:[self dateFromDayIdentifier:dayIdentifier]];
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

- (void)tearDown
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.titleView removeObserver:self forKeyPath:NSStringFromSelector(@selector(visibleItem)) context:ETContext];
}

- (void)saveData
{
  // TODO: Save.
  [self.navigationController popViewControllerAnimated:YES];
}

- (NSDate *)dateFromDayIdentifier:(NSString *)identifier
{
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *dayComponents = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit
                                                fromDate:[[NSDate alloc] init]];
  NSDate *date = [NSDate date];
  if ([identifier isEqualToString:self.tomorrowIdentifier]) {
    dayComponents.day = 1;
    dayComponents.month = 0;
    dayComponents.year = 0;
    date = [calendar dateByAddingComponents:dayComponents toDate:date options:0];
  }
  return date;
}

@end
