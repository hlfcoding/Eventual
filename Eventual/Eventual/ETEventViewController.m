//
//  ETEventViewController.m
//  Eventual
//
//  Created by Nest Master on 11/21/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETEventViewController.h"

#import <EventKit/EKEvent.h>

#import "ETAppearanceManager.h"
#import "ETEventManager.h"
#import "ETNavigationTitleScrollView.h"

// TODO: Date picker, lazy-loaded.

NSTimeInterval const DatePickerAppearanceTransitionDuration = 0.3f;

static NSTimeInterval InputViewTransitionDuration;

@interface ETEventViewController ()

<UITextViewDelegate, UIAlertViewDelegate>

#pragma mark - Subviews

@property (nonatomic, weak) IBOutlet UIDatePicker *datePicker;
@property (nonatomic, weak) IBOutlet UILabel *dayLabel;
@property (nonatomic, weak) IBOutlet UITextView *descriptionView;
@property (nonatomic, weak) IBOutlet UIView *descriptionContainerView;
@property (nonatomic, weak) IBOutlet UIToolbar *editToolbar;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *timeItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *locationItem;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *saveItem;
@property (nonatomic, weak) IBOutlet ETNavigationTitleScrollView *dayMenuView;

#pragma mark - Constraints

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *datePickerDrawerHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *toolbarBottomEdgeConstraint;
@property (nonatomic) CGFloat initialToolbarBottomEdgeConstant;

#pragma mark - Day Menu

@property (nonatomic, strong, setter = setDayIdentifier:) NSString *dayIdentifier;
@property (nonatomic, strong) NSDateFormatter *dayFormatter;
@property (nonatomic, strong) UIButton *laterItem;

@property (nonatomic, strong) NSString *todayIdentifier;
@property (nonatomic, strong) NSString *tomorrowIdentifier;
@property (nonatomic, strong) NSString *laterIdentifier;

#pragma mark - State

@property (nonatomic, strong, setter = setCurrentInputView:) UIView *currentInputView;
@property (nonatomic, strong) UIView *previousInputView;
@property (nonatomic, strong) NSString *waitingSegueIdentifier;
@property (nonatomic) BOOL shouldLockInputViewBuffer;
@property (nonatomic) BOOL isDatePickerVisible;
@property (nonatomic) BOOL isAttemptingDismissal;

#pragma mark - KVO

@property (nonatomic, strong) NSArray *eventKeyPathsToObserve;

#pragma mark - Data

@property (nonatomic, strong) UIAlertView *errorMessageView;
@property (nonatomic, strong, setter = setSaveError:) NSError *saveError;
@property (nonatomic) NSInteger acknowledgeErrorButtonIndex;
@property (nonatomic, setter = setIsDataValid:) BOOL isDataValid;

@property (nonatomic, strong) NSDictionary *baseEditToolbarIconTitleAttributes;

@property (nonatomic, weak) ETEventManager *eventManager;

#pragma mark - Methods

- (IBAction)completeEditing:(id)sender;
- (IBAction)updateDatePicking:(id)sender;
- (IBAction)completeDatePicking:(id)sender;
- (IBAction)toggleDatePicking:(id)sender;

- (void)setUp;
- (void)setUpEvent;
- (void)setUpNewEvent;
- (void)setUpDayMenu;
- (void)setUpDescriptionView;
- (void)setUpEditToolbar;
- (void)resetSubviews;

- (void)updateSaveBarButtonItem;
- (void)updateSubviewMasks;
- (void)updateOnKeyboardAppearanceWithNotification:(NSNotification *)notification;
- (void)updateLayoutForView:(UIView *)view
               withDuration:(NSTimeInterval)duration
                    options:(UIViewAnimationOptions)options
                 completion:(void (^)(BOOL finished))completion;
- (void)toggleDatePickerDrawerAppearance:(BOOL)visible;
- (void)toggleDescriptionTopMask:(BOOL)visible;
- (void)toggleErrorMessage:(BOOL)visible;

- (void)performWaitingSegue;

- (void)tearDown;

- (void)saveData;
- (void)validateData;
- (void)updateDayIdentifierToItem:(UIView *)item;

- (NSDate *)dateFromDayIdentifier:(NSString *)identifier;

@end

#pragma mark -

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
  [self setUpDayMenu];
  [self setUpDescriptionView];
  [self setUpEditToolbar];
  self.dayLabel.textColor = [ETAppearanceManager defaultManager].lightGrayTextColor;
  self.dayMenuView.textColor = [ETAppearanceManager defaultManager].darkGrayTextColor;
  [self updateDayIdentifierToItem:self.dayMenuView.visibleItem];
  [self updateSubviewMasks];
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  self.dayMenuView.alpha = 0.0f;
}

- (void)viewDidAppear:(BOOL)animated
{
  [super viewDidAppear:animated];
  [UIView animateWithDuration:0.3f animations:^{
    self.dayMenuView.alpha = 1.0f;
  }];
}

- (void)viewDidLayoutSubviews
{
  [super viewDidLayoutSubviews];
  [self updateSubviewMasks];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if (context != &ETContext) {
    return [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
  id previousValue = change[NSKeyValueChangeOldKey];
  id value = change[NSKeyValueChangeNewKey];

  if (object == self.dayMenuView && value != previousValue &&
      [keyPath isEqualToString:NSStringFromSelector(@selector(visibleItem))]
      ) {

    [self updateDayIdentifierToItem:value];

  } else if (object == self.event && value != previousValue) {

    [self validateData];
    
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(startDate))] && value) {
      
      NSString *dayText = [self.dayFormatter stringFromDate:value];
      if (dayText) self.dayLabel.text = dayText.uppercaseString;
      
    }

  }
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
  BOOL should = !self.currentInputView;
  self.isAttemptingDismissal = [identifier isEqualToString:ETSegueDismissToMonths];
  if (!should) {
    self.waitingSegueIdentifier = identifier;
    self.previousInputView = nil;
    self.currentInputView = nil;
  }
  return should;
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
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
  NSString *text = textView.text;
  NSError *error;
  if ([self.event validateValue:&text forKey:NSStringFromSelector(@selector(title)) error:&error]) {
    self.event.title = text;
  }
  textView.text = text;
  if (self.currentInputView == textView) self.currentInputView = nil;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if (scrollView != self.descriptionView ||
      scrollView.contentOffset.y > 44.0f) {
    return;
  }
  BOOL shouldHideTopMask = (!self.descriptionView.text.length ||
                            scrollView.contentOffset.y <= fabsf(scrollView.scrollIndicatorInsets.top));
  [self toggleDescriptionTopMask:!shouldHideTopMask];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if (alertView == self.errorMessageView && buttonIndex == self.acknowledgeErrorButtonIndex) {
    [self toggleErrorMessage:NO];
  }
}

#pragma mark - Actions

- (IBAction)completeEditing:(id)sender
{
  if ([self.descriptionView isFirstResponder]) {
    [self.descriptionView resignFirstResponder];
    if (self.currentInputView == self.descriptionView) self.currentInputView = nil;
  }
  [self saveData];
}

- (IBAction)updateDatePicking:(id)sender
{
  NSDate *date = self.datePicker.date;
  NSError *error;
  if ([self.event validateValue:&date forKey:NSStringFromSelector(@selector(startDate)) error:&error]) {
    self.event.startDate = date;
  }
  self.datePicker.date = date;
}

- (IBAction)completeDatePicking:(id)sender
{
  if (self.currentInputView == self.datePicker) self.currentInputView = nil;
}

- (IBAction)toggleDatePicking:(id)sender
{
  BOOL didPickDate = self.isDatePickerVisible;
  if (didPickDate) {
    [self updateDatePicking:sender];
    [self completeDatePicking:sender];
  } else {
    [self toggleDatePickerDrawerAppearance:YES];
  }
}

#pragma mark - Public

#pragma mark - Private

#pragma mark Accessors

- (void)setDayIdentifier:(NSString *)dayIdentifier
{
  if (dayIdentifier == _dayIdentifier) return;
  _dayIdentifier = dayIdentifier;
  [self toggleDatePickerDrawerAppearance:(self.dayIdentifier == self.laterIdentifier)];
}

- (void)setCurrentInputView:(UIView *)currentInputView
{
  // Guard.
  if (self.shouldLockInputViewBuffer || currentInputView == self.currentInputView) return;
  // Re-focus previously focused input.
  self.shouldLockInputViewBuffer = YES;
  if (!currentInputView && self.previousInputView && !self.isAttemptingDismissal) {
    if (self.previousInputView == self.descriptionView) {
      [self.descriptionView becomeFirstResponder];
    } else if (self.previousInputView == self.datePicker) {
      [self toggleDatePickerDrawerAppearance:YES];
    }
    // Update.
    _currentInputView = self.previousInputView;
  } else {
    BOOL shouldPerformWaitingSegue = !currentInputView;
    // Blur currently focused input.
    if (self.currentInputView == self.descriptionView) {
      [self.descriptionView resignFirstResponder];
    } else if (self.currentInputView == self.datePicker) {
      BOOL previousValue = self.shouldLockInputViewBuffer;
      self.shouldLockInputViewBuffer = YES;
      [self toggleDatePickerDrawerAppearance:NO];
      self.shouldLockInputViewBuffer = previousValue;
      shouldPerformWaitingSegue = NO;
    }
    // Update.
    self.previousInputView = self.currentInputView;
    _currentInputView = currentInputView;
    // Retry any waiting actions.
    if (shouldPerformWaitingSegue) {
      [self performWaitingSegue];
    }
  }
  self.shouldLockInputViewBuffer = NO;
}

- (void)setSaveError:(NSError *)saveError
{
  if (saveError == _saveError) return;
  _saveError = saveError;
  if (!self.errorMessageView) {
    self.errorMessageView = [[UIAlertView alloc] init];
    self.errorMessageView.delegate = self;
    self.acknowledgeErrorButtonIndex = [self.errorMessageView addButtonWithTitle:NSLocalizedString(@"OK", nil)];
  }
  self.errorMessageView.title = [[(NSString *)saveError.userInfo[NSLocalizedDescriptionKey] capitalizedString]
                                 stringByReplacingOccurrencesOfString:@". " withString:@""];
  self.errorMessageView.message = [(NSString *)saveError.userInfo[NSLocalizedFailureReasonErrorKey]
                                   stringByAppendingString:saveError.userInfo[NSLocalizedRecoverySuggestionErrorKey]];
}

- (void)setIsDataValid:(BOOL)isDataValid
{
  _isDataValid = isDataValid;
  [self updateSaveBarButtonItem];
}

#pragma mark Setup

- (void)setUp
{
  // Note: This happens on init.
  self.eventKeyPathsToObserve = @[ NSStringFromSelector(@selector(title)), NSStringFromSelector(@selector(startDate)) ];
  self.dayFormatter = [[NSDateFormatter alloc] init];
  self.dayFormatter.dateFormat = @"MMMM d, y · EEEE";
  self.eventManager = [ETEventManager defaultManager];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnKeyboardAppearanceWithNotification:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateOnKeyboardAppearanceWithNotification:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)setUpEvent
{
  if (!self.event) return;
  for (NSString *keyPath in self.eventKeyPathsToObserve) {
    [self.event addObserver:self forKeyPath:keyPath
                    options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&ETContext];
  }
}

- (void)setUpNewEvent
{
  if (self.event) return;
  self.event = [EKEvent eventWithEventStore:self.eventManager.store];
  [self setUpEvent];
}

- (void)setUpDayMenu
{
  // Define.
  self.todayIdentifier = NSLocalizedString(@"Today", nil);
  self.tomorrowIdentifier = NSLocalizedString(@"Tomorrow", nil);
  self.laterIdentifier = NSLocalizedString(@"Later", nil);
  self.dayMenuView.accessibilityLabel = NSLocalizedString(ETLabelEventScreenTitle, nil);
  // Add.
  UIView *item = [self.dayMenuView addItemOfType:ETNavigationItemTypeLabel withText:self.todayIdentifier];
  item.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(ETLabelFormatDayOption, nil), self.todayIdentifier];
  item = [self.dayMenuView addItemOfType:ETNavigationItemTypeLabel withText:self.tomorrowIdentifier];
  item.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(ETLabelFormatDayOption, nil), self.tomorrowIdentifier];
  item = [self.dayMenuView addItemOfType:ETNavigationItemTypeButton withText:self.laterIdentifier];
  item.accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(ETLabelFormatDayOption, nil), self.laterIdentifier];
  // Bind and observe.
  self.laterItem = (UIButton *)item;
  [self.laterItem addTarget:self action:@selector(toggleDatePicking:) forControlEvents:UIControlEventTouchUpInside];
  self.datePicker.minimumDate = [self dateFromDayIdentifier:self.laterIdentifier];
  [self.dayMenuView addObserver:self forKeyPath:NSStringFromSelector(@selector(visibleItem))
                      options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:&ETContext];
  // Commit.
  [self.dayMenuView processItems];
}

- (void)setUpDescriptionView
{
  CAGradientLayer *maskLayer = [CAGradientLayer layer];
  self.descriptionContainerView.layer.mask = maskLayer;
  [self toggleDescriptionTopMask:NO];
  self.descriptionView.contentInset = UIEdgeInsetsMake(-10.0f, 0.0f, 0.0f, 0.0f);
  self.descriptionView.scrollIndicatorInsets = UIEdgeInsetsMake(10.0f, 0.0f, 10.0f, 0.0f);
}

- (void)setUpEditToolbar
{
  // Save initial state.
  self.initialToolbarBottomEdgeConstant = self.toolbarBottomEdgeConstraint.constant;
  // Style toolbar itself.
  self.editToolbar.clipsToBounds = YES;
  // Set base attributes.
  CGFloat iconFontSize = [ETAppearanceManager defaultManager].iconBarButtonItemFontSize;
  UIFont *iconFont = [UIFont fontWithName:@"eventual" size:iconFontSize];
  self.baseEditToolbarIconTitleAttributes = @{ NSFontAttributeName: iconFont };
  // Set icons.
  self.timeItem.title = ETIconClock;
  self.locationItem.title = ETIconMapPin;
  self.saveItem.title = ETIconCheckCircle;
  // Set initial attributes.
  NSMutableDictionary *attributes = self.baseEditToolbarIconTitleAttributes.mutableCopy;
  attributes[NSForegroundColorAttributeName] = [ETAppearanceManager defaultManager].lightGrayIconColor;
  // For all actual buttons.
  for (UIBarButtonItem *item in self.editToolbar.items) {
    if (item.width == 0.0f) {
      // Apply initial attributes.
      [item setTitleTextAttributes:attributes forState:UIControlStateNormal];
      // Adjust icon layout.
      [item setWidth:roundf(iconFont.pointSize * 1.15f)];
    }
  }
}

- (void)resetSubviews
{
  self.dayLabel.text = nil;
  self.descriptionView.text = nil;
}

#pragma mark Update

- (void)updateSaveBarButtonItem
{
  UIColor *saveItemColor;
  if (self.isDataValid) {
    saveItemColor = [ETAppearanceManager defaultManager].greenColor;
  } else {
    saveItemColor = [ETAppearanceManager defaultManager].lightGrayIconColor;
  }
  NSMutableDictionary *attributes = self.baseEditToolbarIconTitleAttributes.mutableCopy;
  attributes[NSForegroundColorAttributeName] = saveItemColor;
  [self.saveItem setTitleTextAttributes:attributes forState:UIControlStateNormal];
}

- (void)updateSubviewMasks
{
  CAGradientLayer *maskLayer = (CAGradientLayer *)self.descriptionContainerView.layer.mask;
  CGFloat heightRatio = 20.0f / self.descriptionContainerView.frame.size.height;
  maskLayer.locations = @[ @0.0f, @(heightRatio), @(1.0f - heightRatio), @1.0f ];
  maskLayer.frame = self.descriptionContainerView.bounds;
}

- (void)updateOnKeyboardAppearanceWithNotification:(NSNotification *)notification
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    InputViewTransitionDuration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
  });
  CGFloat constant = 0.0f;
  if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
    CGRect frame = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    constant = frame.size.height > frame.size.width ? frame.size.width : frame.size.height;
  }
  self.toolbarBottomEdgeConstraint.constant = constant + self.initialToolbarBottomEdgeConstant;
  // TODO: Flawless animation sync.
  [self.editToolbar setNeedsUpdateConstraints];
  [self updateLayoutForView:self.editToolbar
               withDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue]
                    options:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue]
                 completion:nil];
}

- (void)updateLayoutForView:(UIView *)view withDuration:(NSTimeInterval)duration options:(UIViewAnimationOptions)options completion:(void (^)(BOOL))completion
{
  [view setNeedsUpdateConstraints];
  [UIView
   animateWithDuration:duration delay:0.0f
   usingSpringWithDamping:0.7f initialSpringVelocity:0.0f
   options:options|UIViewAnimationOptionBeginFromCurrentState
   animations:^{
     [view layoutIfNeeded];
   } completion:^(BOOL finished) {
     if (completion) {
       completion(finished);
     }
   }];
}

- (void)toggleDatePickerDrawerAppearance:(BOOL)visible
{
  if (self.isDatePickerVisible == visible) return;
  self.datePickerDrawerHeightConstraint.constant = visible ? self.datePicker.frame.size.height : 1.0f;
  self.dayLabel.hidden = visible; // TODO: Update layout.
  void (^completion)(BOOL) = ^(BOOL finished) {
    self.isDatePickerVisible = visible;
    if (visible) {
      self.currentInputView = self.datePicker;
    } else {
      if (self.currentInputView == self.datePicker) {
        self.currentInputView = nil;
      }
      [self performWaitingSegue];
    }
  };
  [self updateLayoutForView:self.view withDuration:DatePickerAppearanceTransitionDuration
                    options:UIViewAnimationOptionCurveEaseInOut completion:completion];
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

- (void)toggleErrorMessage:(BOOL)visible
{
  if (visible) {
    [self.errorMessageView show];
  } else {
    [self.errorMessageView dismissWithClickedButtonIndex:self.acknowledgeErrorButtonIndex animated:YES];
  }
}

#pragma mark Perform

- (void)performWaitingSegue
{
  if (self.waitingSegueIdentifier) {
    self.isAttemptingDismissal = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
      [self performSegueWithIdentifier:self.waitingSegueIdentifier sender:self];
      self.waitingSegueIdentifier = nil;
    });
  }
}

#pragma mark Teardown

- (void)tearDown
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.dayMenuView removeObserver:self forKeyPath:NSStringFromSelector(@selector(visibleItem)) context:&ETContext];
  [self.laterItem removeTarget:self action:@selector(toggleDatePicking:) forControlEvents:UIControlEventTouchUpInside];
  for (NSString *keyPath in self.eventKeyPathsToObserve) {
    [self.event removeObserver:self forKeyPath:keyPath context:&ETContext];
  }
}

#pragma mark Data

- (void)saveData
{
  NSError *error;
  BOOL didSave = [self.eventManager saveEvent:self.event error:&error];
  if (error) {
    self.saveError = error;
  }
  if (!didSave) {
    [self toggleErrorMessage:YES];
  } else {
    if ([self shouldPerformSegueWithIdentifier:ETSegueDismissToMonths sender:self]) {
      [self performSegueWithIdentifier:ETSegueDismissToMonths sender:self];
    }
  }
}

- (void)validateData
{
  NSError *error;
  self.isDataValid = [self.eventManager validateEvent:self.event error:&error];
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
  NSDate *date = [NSDate date];
  if ([identifier isEqualToString:self.tomorrowIdentifier]) {
    date = [self.eventManager dateFromAddingDays:1 toDate:date];
  } else if ([identifier isEqualToString:self.laterIdentifier]) {
    if (self.datePicker.minimumDate) return self.datePicker.minimumDate;
    date = [self.eventManager dateFromAddingDays:2 toDate:date];
  }
  return date;
}

@end
