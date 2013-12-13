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
#import "ETEventManager.h"
#import "ETNavigationTitleScrollView.h"

// TODO: Date picker, lazy-loaded.
// TODO: Saving.
// TODO: Toolbar.

@interface ETEventViewController ()

<UITextViewDelegate>

@property (strong, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (strong, nonatomic) IBOutlet UILabel *dayLabel;
@property (strong, nonatomic) IBOutlet UITextView *descriptionView;
@property (strong, nonatomic) IBOutlet UIView *descriptionContainerView;
@property (strong, nonatomic) IBOutlet UIToolbar *editToolbar;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveItem;
@property (strong, nonatomic) IBOutlet ETNavigationTitleScrollView *titleView;
@property (nonatomic) BOOL isDatePickerVisible;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *datePickerDrawerHeightConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *toolbarBottomEdgeConstraint;

@property (strong, nonatomic) NSString *dayIdentifier;
@property (strong, nonatomic) NSDateFormatter *dayFormatter;
@property (strong, nonatomic) UIButton *laterItem;

@property (strong, nonatomic) NSString *todayIdentifier;
@property (strong, nonatomic) NSString *tomorrowIdentifier;
@property (strong, nonatomic) NSString *laterIdentifier;

@property (strong, nonatomic, setter = setCurrentInputView:) UIView *currentInputView;
@property (strong, nonatomic) UIView *previousInputView;
@property (nonatomic) BOOL shouldLockInputViewBuffer;

@property (strong, nonatomic) NSArray *eventKeyPathsToObserve;
@property (nonatomic) BOOL isDataValid;

- (IBAction)editDoneAction:(id)sender;
- (IBAction)datePickedAction:(id)sender;
- (void)laterItemAction:(id)sender;

- (void)setUp;
- (void)setUpEvent;
- (void)setUpNewEvent;
- (void)setUpTitleView;
- (void)setUpDescriptionView;
- (void)resetSubviews;
- (void)updateSubviews:(id)sender;
- (void)updateSubviewMasks;
- (void)updateOnKeyboardAppearanceWithNotification:(NSNotification *)notification;
- (void)updateLayoutWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options completion:(void (^)(BOOL finished))completion;
- (void)toggleDatePickerDrawerAppearance:(BOOL)visible;
- (void)toggleDescriptionTopMask:(BOOL)visible;

- (void)tearDown;

- (void)saveData;
- (void)validateData;
- (void)updateDayIdentifierToItem:(UIView *)item;

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
  [self resetSubviews];
  [self setUpNewEvent];
  [self setUpTitleView];
  [self setUpDescriptionView];
  ETAppDelegate *stylesheet = [UIApplication sharedApplication].delegate;
  self.dayLabel.textColor = stylesheet.lightGrayTextColor;
  self.titleView.textColor = stylesheet.darkGrayTextColor;
  [self updateDayIdentifierToItem:self.titleView.visibleItem];
  [self updateSubviews:self];
  [self updateSubviewMasks];
}

- (void)viewDidLayoutSubviews
{
  [self updateSubviewMasks];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (context != ETContext) return;
  id previousValue = change[NSKeyValueChangeOldKey];
  id value = change[NSKeyValueChangeNewKey];

  if (object == self.titleView
      && [keyPath isEqualToString:NSStringFromSelector(@selector(visibleItem))]
      && value != previousValue
      ) {

    [self updateDayIdentifierToItem:value];
    [self updateSubviews:object];

  } else if (object == self.event && value != previousValue) {

    [self validateData];

  }
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
  self.currentInputView = textView;
  [self toggleDatePickerDrawerAppearance:NO];
}

- (void)textViewDidChange:(UITextView *)textView
{
  self.event.title = textView.text;
  [self updateSubviews:textView];
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
  if (self.currentInputView == textView) self.currentInputView = nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if (scrollView != self.descriptionView
      || scrollView.contentOffset.y > 44.0f) {
    return;
  }
  BOOL shouldHideTopMask = (!self.descriptionView.text.length ||
                            scrollView.contentOffset.y <= fabsf(scrollView.scrollIndicatorInsets.top));
  [self toggleDescriptionTopMask:!shouldHideTopMask];
}

#pragma mark - Actions

- (IBAction)editDoneAction:(id)sender
{
  if ([self.descriptionView isFirstResponder]) {
    [self.descriptionView resignFirstResponder];
    if (self.currentInputView == self.descriptionView) self.currentInputView = nil;
  }
  [self saveData];
}

- (IBAction)datePickedAction:(id)sender
{
  self.event.startDate = self.datePicker.date;
  if (self.currentInputView == self.datePicker) self.currentInputView = nil;
  [self updateSubviews:sender];
}

- (void)laterItemAction:(id)sender
{
  BOOL didPickDate = self.isDatePickerVisible;
  if (didPickDate) {
    [self datePickedAction:sender];
  } else {
    [self toggleDatePickerDrawerAppearance:YES];
  }
}

#pragma mark - Public

#pragma mark - Private

- (void)setCurrentInputView:(UIView *)currentInputView
{
  // Guard.
  if (self.shouldLockInputViewBuffer || currentInputView == self.currentInputView) return;
  // Re-focus previously focused input.
  self.shouldLockInputViewBuffer = YES;
  if (!currentInputView && self.previousInputView) {
    if (self.previousInputView == self.descriptionView) {
      [self.descriptionView becomeFirstResponder];
    } else if (self.previousInputView == self.datePicker) {
      [self toggleDatePickerDrawerAppearance:YES];
    }
    // Update.
    _currentInputView = self.previousInputView;
  } else {
    // Blur currently focused input.
    if (self.currentInputView == self.descriptionView) {
      [self.descriptionView resignFirstResponder];
    } else if (self.currentInputView == self.datePicker) {
      [self toggleDatePickerDrawerAppearance:NO];
    }
    // Update.
    self.previousInputView = self.currentInputView;
    _currentInputView = currentInputView;
  }
  self.shouldLockInputViewBuffer = NO;
}

- (void)setUp
{
  // Note: This happens on init.
  self.eventKeyPathsToObserve = @[ NSStringFromSelector(@selector(title)), NSStringFromSelector(@selector(startDate)) ];
  self.dayFormatter = [[NSDateFormatter alloc] init];
  self.dayFormatter.dateFormat = @"MMMM d, y · EEEE";
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnKeyboardAppearanceWithNotification:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnKeyboardAppearanceWithNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)setUpEvent
{
  if (!self.event) return;
  for (NSString *keyPath in self.eventKeyPathsToObserve) {
    [self.event addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:ETContext];
  }
}

- (void)setUpNewEvent
{
  if (self.event) return;
  ETEventManager *eventManager = self.eventManager;
  self.event = [EKEvent eventWithEventStore:eventManager.store];
  [self setUpEvent];
}

- (void)setUpTitleView
{
  self.todayIdentifier = NSLocalizedString(@"Today", nil);
  self.tomorrowIdentifier = NSLocalizedString(@"Tomorrow", nil);
  self.laterIdentifier = NSLocalizedString(@"Later", nil);
  self.titleView.accessibilityLabel = NSLocalizedString(ETEventScreenTitleLabel, nil);
  UIView *item = [self.titleView addItemOfType:ETNavigationItemTypeLabel withText:self.todayIdentifier];
  item.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(ETDayOptionLabelFormat, nil), self.todayIdentifier];
  item = [self.titleView addItemOfType:ETNavigationItemTypeLabel withText:self.tomorrowIdentifier];
  item.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(ETDayOptionLabelFormat, nil), self.tomorrowIdentifier];
  item = [self.titleView addItemOfType:ETNavigationItemTypeButton withText:self.laterIdentifier];
  item.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(ETDayOptionLabelFormat, nil), self.laterIdentifier];
  self.laterItem = (UIButton *)item;
  [self.laterItem addTarget:self action:@selector(laterItemAction:) forControlEvents:UIControlEventTouchUpInside];
  [self.titleView addObserver:self forKeyPath:NSStringFromSelector(@selector(visibleItem))
                      options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:ETContext];
  [self.titleView processItems];
  self.datePicker.minimumDate = [self dateFromDayIdentifier:self.laterIdentifier];
}

- (void)setUpDescriptionView
{
  CAGradientLayer *maskLayer = [CAGradientLayer layer];
  self.descriptionContainerView.layer.mask = maskLayer;
  [self toggleDescriptionTopMask:NO];
  self.descriptionView.contentInset = UIEdgeInsetsMake(-10.0f, 0.0f, 0.0f, 0.0f);
  self.descriptionView.scrollIndicatorInsets = UIEdgeInsetsMake(10.0f, 0.0f, 10.0f, 0.0f);
}

- (void)resetSubviews
{
  self.dayLabel.text = nil;
  self.descriptionView.text = nil;
}

- (void)updateSubviews:(id)sender
{
  ETAppDelegate *stylesheet = [UIApplication sharedApplication].delegate;
  if (sender == self.titleView) {
    BOOL shouldExpandDatePicker = self.dayIdentifier == self.laterIdentifier;
    [self toggleDatePickerDrawerAppearance:shouldExpandDatePicker];
  }
  NSString *dayText = [self.dayFormatter stringFromDate:self.event.startDate];
  if (dayText) {
    self.dayLabel.text = dayText.uppercaseString;
  }

  UIColor *saveItemColor = nil;
  if (self.isDataValid) {
    saveItemColor = stylesheet.greenColor;
  } else {
    saveItemColor = stylesheet.lightGrayIconColor;
  }
  [self.saveItem setTitleTextAttributes:@{ NSForegroundColorAttributeName: saveItemColor } forState:UIControlStateNormal];
}

- (void)updateSubviewMasks
{
  CAGradientLayer *maskLayer = nil;
  maskLayer = (CAGradientLayer *)self.descriptionContainerView.layer.mask;
  CGFloat heightRatio = 20.0f / self.descriptionContainerView.frame.size.height;
  maskLayer.locations = @[ @0.0f, @(heightRatio), @(1.0f - heightRatio), @1.0f ];
  maskLayer.frame = self.descriptionContainerView.bounds;
}

- (void)updateOnKeyboardAppearanceWithNotification:(NSNotification *)notification
{
  CGFloat constant = 0.0f;
  if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
    CGRect frame = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    constant = frame.size.height > frame.size.width ? frame.size.width : frame.size.height;
  }
  self.toolbarBottomEdgeConstraint.constant = constant;
  // TODO: Flawless animation sync.
  [self updateLayoutWithDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue]
                         options:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]
                      completion:nil];
}

- (void)updateLayoutWithDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options completion:(void (^)(BOOL finished))completion
{
  [self.view setNeedsUpdateConstraints];
  [UIView animateWithDuration:duration delay:0.0f options:options
                   animations:^{ [self.view layoutIfNeeded]; }
                   completion:completion];
}

- (void)toggleDatePickerDrawerAppearance:(BOOL)visible
{
  self.datePickerDrawerHeightConstraint.constant = visible ? self.datePicker.frame.size.height : 1.0f;
  self.dayLabel.hidden = visible; // TODO: Update layout.
  [self updateLayoutWithDuration:0.3f options:UIViewAnimationOptionCurveEaseInOut completion:^(BOOL finished) {
    self.isDatePickerVisible = visible;
  }];
  if (visible) self.currentInputView = self.datePicker;
  else if (self.currentInputView == self.datePicker) self.currentInputView = nil;
}

- (void)toggleDescriptionTopMask:(BOOL)visible
{
  CAGradientLayer *maskLayer = (CAGradientLayer *)self.descriptionContainerView.layer.mask;
  UIColor *topColor = !visible ? [UIColor whiteColor] : [UIColor clearColor];
  if ([(id)topColor.CGColor isEqual:maskLayer.colors.firstObject]) return;
  NSMutableArray *colors = @[ (id)topColor.CGColor,
                              (id)[UIColor whiteColor].CGColor,
                              (id)[UIColor whiteColor].CGColor,
                              (id)[UIColor clearColor].CGColor ].mutableCopy;
  maskLayer.colors = colors;
}

- (void)tearDown
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.titleView removeObserver:self forKeyPath:NSStringFromSelector(@selector(visibleItem)) context:ETContext];
  [self.laterItem removeTarget:self action:@selector(laterItemAction:) forControlEvents:UIControlEventTouchUpInside];
  for (NSString *keyPath in self.eventKeyPathsToObserve) {
    [self.event removeObserver:self forKeyPath:keyPath context:ETContext];
  }
}

- (void)saveData
{
  // TODO: Save.
  [self.navigationController popViewControllerAnimated:YES];
}

- (void)validateData
{
  self.isDataValid = !!self.descriptionView.text.length;
}

- (void)updateDayIdentifierToItem:(UIView *)item
{
  if ([item isKindOfClass:[UIButton class]]) {
    self.dayIdentifier = [(UIButton *)item titleForState:UIControlStateNormal];
  } else {
    self.dayIdentifier = ((UILabel *)item).text;
  }
  NSDate *dayDate = [self dateFromDayIdentifier:self.dayIdentifier];
  if (dayDate) {
    self.event.startDate = dayDate;
  }
}

- (NSDate *)dateFromDayIdentifier:(NSString *)identifier
{
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *dayComponents = [calendar components:(NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit|
                                                          NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit)
                                                fromDate:[NSDate date]];
  dayComponents.hour = dayComponents.minute = dayComponents.second = 0;
  if ([identifier isEqualToString:self.tomorrowIdentifier]) {
    dayComponents.day += 1;
  } else if ([identifier isEqualToString:self.laterIdentifier]) {
    if (self.datePicker.minimumDate) return self.datePicker.minimumDate;
    dayComponents.day += 2;
  }
  NSDate *date = [calendar dateFromComponents:dayComponents];
  return date;
}

@end
