//
//  ETMonthsViewController.m
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/5/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETMonthsViewController.h"

#import <EventKit/EKEvent.h>

#import "ETAppDelegate.h"
#import "ETDayViewCell.h"
#import "ETDayViewController.h"
#import "ETEventManager.h"
#import "ETEventViewController.h"
#import "ETMonthHeaderView.h"
#import "ETNavigationController.h"
#import "ETNavigationTitleView.h"
#import "ETZoomTransitionCoordinator.h"

// TODO: Custom layout.
// TODO: User refreshing.
// TODO: Navigation.
// TODO: Add day.
// TODO: Drag and drop. Delete tile.

CGFloat const DayGutter = 0.0f;
CGFloat const MonthGutter = 50.0f;

@interface ETMonthsViewController ()

<UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSDate *currentDate;
@property (nonatomic, strong) NSDate *currentDayDate;
@property (nonatomic, strong) NSDateFormatter *dayFormatter;
@property (nonatomic, strong) NSDateFormatter *monthFormatter;

@property (nonatomic, strong, readonly, getter = dataSource) NSDictionary *dataSource;
@property (nonatomic, strong, readonly, getter = allMonthDates) NSArray *allMonthDates;
@property (nonatomic, strong) NSIndexPath *currentIndexPath;

@property (nonatomic) NSUInteger numberOfColumns;
@property (nonatomic) CGSize cellSize;
@property (nonatomic, setter = setCurrentSectionIndex:) NSUInteger currentSectionIndex;
@property (nonatomic) CGPoint previousContentOffset;
@property (nonatomic) CGFloat viewportYOffset;
@property (nonatomic, weak) IBOutlet ETNavigationTitleView *titleView;

@property (nonatomic, strong) ETZoomTransitionCoordinator *transitionCoordinator;

@property (nonatomic, weak) IBOutlet UITapGestureRecognizer *backgroundTapRecognizer; // Aspect(s): Add-Event.

@property (nonatomic, weak) ETEventManager *eventManager;

- (NSArray *)allDayDatesForMonthAtIndex:(NSUInteger)index;
- (NSDate *)dayDateAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)dayEventsAtIndexPath:(NSIndexPath *)indexPath;

- (UIEdgeInsets)borderInsetsForCell:(ETDayViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

- (void)eventAccessRequestDidComplete:(NSNotification *)notification;

- (void)setUp;
- (void)setUpTransitionForCellAtIndexPath:(NSIndexPath *)indexPath;
- (void)setAccessibilityLabels;
- (void)setUpBackgroundView; // Aspect(s): Add-Event.

- (void)updateMeasures;
- (void)updateTitleView;

- (void)tearDown;

- (void)toggleBackgroundViewHighlighted:(BOOL)highlighted; // Aspect(s): Add-Event.

@end

@implementation ETMonthsViewController

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
  self.eventManager = [ETEventManager defaultManager];
  [self setAccessibilityLabels];
  [self setUpBackgroundView];
  [self updateMeasures];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self updateMeasures];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  ETNavigationController *navigationController;
  if ([segue.destinationViewController isKindOfClass:[ETNavigationController class]]) {
    navigationController = (ETNavigationController *)segue.destinationViewController;
    // Setup transition.
    [self setUpTransitionForCellAtIndexPath:self.currentIndexPath];
    navigationController.transitioningDelegate = self.transitionCoordinator;
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
  }
  if ([segue.identifier isEqualToString:ETSegueShowDay]) {
    
    ETDayViewController *viewController = navigationController.viewControllers.firstObject;
    // Setup data.
    NSArray *indexPaths = self.collectionView.indexPathsForSelectedItems;
    if (!indexPaths.count) return;
    NSIndexPath *indexPath = indexPaths.firstObject;
    viewController.dayDate = [self dayDateAtIndexPath:indexPath];
    viewController.dayEvents = [self dayEventsAtIndexPath:indexPath];
    
  } else if ([segue.identifier isEqualToString:ETSegueAddDay]) {
    
    ETEventViewController *viewController = (ETEventViewController *)segue.destinationViewController;
    
  }
  [super prepareForSegue:segue sender:sender];
}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
  return YES;
}

#pragma mark - Actions

- (IBAction)dismissToMonths:(UIStoryboardSegue *)sender
{
  // TODO: Auto-unwinding currently not supported in tandem with iOS7 Transition API.
  [self setUpTransitionForCellAtIndexPath:self.currentIndexPath];
  self.transitionCoordinator.zoomReversed = YES;
  [self dismissViewControllerAnimated:YES completion:nil];
}

// Aspect(s): Add-Event.
- (IBAction)requestAddingEvent:(id)sender
{
  if (sender == self.backgroundTapRecognizer) {
    //NSLog(@"Background tap.");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [self toggleBackgroundViewHighlighted:NO];
      [self performSegueWithIdentifier:ETSegueAddDay sender:sender];
    });
  }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  NSInteger number = 0;
  if (self.dataSource) {
    NSArray *monthDates = self.allMonthDates;
    if (monthDates) {
      number = monthDates.count;
    }
  }
  return number;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  NSInteger number = 0;
  if (self.dataSource) {
    NSArray *dayDates = [self allDayDatesForMonthAtIndex:section];
    if (dayDates) {
      number = dayDates.count;
    }
  }
  return number;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ETDayViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Day" forIndexPath:indexPath];
  if (self.dataSource) {
    NSDate *dayDate = [self dayDateAtIndexPath:indexPath];
    [cell setAccessibilityLabelsWithIndexPath:indexPath];
    for (UIView *subview in cell.subviews) {
      subview.hidden = NO;
    }
    NSArray *dayEvents = [self dayEventsAtIndexPath:indexPath];
    cell.isToday = [dayDate isEqualToDate:self.currentDayDate];
    cell.dayText = [self.dayFormatter stringFromDate:dayDate];
    cell.numberOfEvents = dayEvents.count;
    cell.borderInsets = [self borderInsetsForCell:cell atIndexPath:indexPath];
  }
  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  if (kind == UICollectionElementKindSectionHeader) {
    if (!self.dataSource) return nil;
    NSUInteger index = indexPath.section;
    ETMonthHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Month" forIndexPath:indexPath];
    NSDate *monthDate = self.allMonthDates[index];
    headerView.monthName = [self.monthFormatter stringFromDate:monthDate];
    return headerView;
  }
  return nil;
}

#pragma mark - UICollectionViewDelegate

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
  self.currentIndexPath = indexPath;
  ETDayViewCell *cell = (id)[self.collectionView cellForItemAtIndexPath:indexPath];
  [cell performPopAnimationWithCompletion:nil];
  return YES;
}

#pragma mark - UICollectionViewFlowLayout

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return DayGutter;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return DayGutter;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return self.cellSize;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
  return UIEdgeInsetsMake(0.0f, 0.0f, MonthGutter, 0.0f);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section
{
  UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;
  return (section == 0) ? CGSizeZero : layout.headerReferenceSize;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
  // Aspect(s): Add-Event.
  [self toggleBackgroundViewHighlighted:NO];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  if (self.dataSource) {
    //NSLog(@"Offset: %@", NSStringFromCGPoint(scrollView.contentOffset));
    NSInteger direction = (scrollView.contentOffset.y < self.previousContentOffset.y) ? -1 : 1;
    self.previousContentOffset = scrollView.contentOffset;
    CGFloat offset = scrollView.contentOffset.y;
    if (self.navigationController.navigationBar.isTranslucent) {
      offset += self.viewportYOffset;
    }
    NSUInteger previousIndex = (direction == -1 && self.currentSectionIndex > 0) ? self.currentSectionIndex - 1 : NSNotFound;
    NSUInteger nextIndex = (direction == 1 && self.currentSectionIndex + 1 < self.allMonthDates.count) ? self.currentSectionIndex + 1 : NSNotFound;
    UICollectionViewLayout *layout = self.collectionViewLayout;
    if (previousIndex != NSNotFound) {
      CGRect prevFrame = [layout layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                atIndexPath:[NSIndexPath indexPathForItem:0 inSection:self.currentSectionIndex]].frame;
      CGFloat top = prevFrame.origin.y;
      offset -= prevFrame.size.height / 2.0f;
      if (offset < top) {
        self.currentSectionIndex = previousIndex;
      }
    }
    if (nextIndex != NSNotFound) {
      CGRect nextFrame = [layout layoutAttributesForSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                atIndexPath:[NSIndexPath indexPathForItem:0 inSection:nextIndex]].frame;
      CGFloat bottom = nextFrame.origin.y + nextFrame.size.height;
      offset += nextFrame.size.height / 2.0f;
      if (offset > bottom) {
        self.currentSectionIndex = nextIndex;
      }
    }
  }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
  if (gestureRecognizer == self.backgroundTapRecognizer) {
    // Aspect(s): Add-Event.
    [self toggleBackgroundViewHighlighted:YES];
    //NSLog(@"Begin possible background tap.");
  }
  return YES;
}

#pragma mark - Private

#pragma mark Accessors

- (NSDictionary *)dataSource
{
  return self.eventManager.events ? self.eventManager.eventsByMonthsAndDays : nil;
}

- (NSArray *)allMonthDates
{
  return self.dataSource[ETEntityCollectionDatesKey];
}

- (NSArray *)allDayDatesForMonthAtIndex:(NSUInteger)index
{
  NSArray *days = self.dataSource[ETEntityCollectionDaysKey];
  if (days.count <= index) return nil;
  return days[index][ETEntityCollectionDatesKey];
}

- (NSDate *)dayDateAtIndexPath:(NSIndexPath *)indexPath
{
  return self.dataSource
  [ETEntityCollectionDaysKey][indexPath.section]
  [ETEntityCollectionDatesKey][indexPath.item];
}

- (NSArray *)dayEventsAtIndexPath:(NSIndexPath *)indexPath
{
  return self.dataSource
  [ETEntityCollectionDaysKey][indexPath.section]
  [ETEntityCollectionEventsKey][indexPath.item];
}

- (UIEdgeInsets)borderInsetsForCell:(ETDayViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
  UIEdgeInsets borderInsets = cell.defaultBorderInsets;

  // First, create measures to decide if the right border, drawn by default,
  // needs to be drawn.

  NSUInteger itemIndex = indexPath.item;
  NSUInteger lastRowItemIndex = self.numberOfColumns - 1;
  NSUInteger rowItemIndex = itemIndex % self.numberOfColumns;

  if (rowItemIndex == lastRowItemIndex) {
    borderInsets.right = 0.0f;
  }

  // Next, create measures to decide if the bottom border, not drawn by default,
  // needs to be drawn.

  NSUInteger itemCount = [self collectionView:self.collectionView numberOfItemsInSection:indexPath.section];
  NSUInteger lastItemIndex = itemCount - 1;
  NSUInteger bottomEdgeStartIndex = lastItemIndex - self.numberOfColumns;
  NSUInteger remainingRowItemCount = lastRowItemIndex - rowItemIndex;

  BOOL isBottomEdgeCell = itemIndex > bottomEdgeStartIndex;
  BOOL isOnRowWithBottomEdgeCell = !isBottomEdgeCell && (itemIndex + remainingRowItemCount > bottomEdgeStartIndex);
  BOOL isSingleRowCell = itemCount <= self.numberOfColumns;
  BOOL isTopEdgeCell = itemIndex < self.numberOfColumns;

  if (isBottomEdgeCell || isOnRowWithBottomEdgeCell || (isTopEdgeCell && isSingleRowCell)) {
    borderInsets.bottom = 1.0f;
  }

  // Finally, decide when the top border, drawn by default, needs to be drawn.

  BOOL hasPartialLastRow = itemCount % self.numberOfColumns > 0;
  BOOL isOnPartialLastRow = hasPartialLastRow && (itemIndex + remainingRowItemCount >= lastItemIndex);

  if (isOnPartialLastRow && !isOnRowWithBottomEdgeCell && !isSingleRowCell) {
    borderInsets.top = 0.0f;
  }

  return borderInsets;
}

- (void)setCurrentSectionIndex:(NSUInteger)currentSectionIndex
{
  if (currentSectionIndex == _currentSectionIndex) return;
  _currentSectionIndex = currentSectionIndex;
  [self updateTitleView];
}

#pragma mark Setup

- (void)setUp
{
  self.currentDate = [NSDate date];
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *dayComponents = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:self.currentDate];
  self.currentDayDate = [calendar dateFromComponents:dayComponents];
  self.dayFormatter = [[NSDateFormatter alloc] init];
  self.dayFormatter.dateFormat = @"d";
  self.monthFormatter = [[NSDateFormatter alloc] init];
  self.monthFormatter.dateFormat = @"MMMM";
  self.transitionCoordinator = [[ETZoomTransitionCoordinator alloc] init];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventAccessRequestDidComplete:)
                                               name:ETEntityAccessRequestNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventSaveOperationDidComplete:)
                                               name:ETEntitySaveOperationNotification object:nil];
}

- (void)setUpTransitionForCellAtIndexPath:(NSIndexPath *)indexPath
{
  self.transitionCoordinator.zoomContainerView = self.navigationController.view;
  self.transitionCoordinator.zoomedOutView = [self.collectionView cellForItemAtIndexPath:indexPath];
  self.transitionCoordinator.zoomedOutFrame = CGRectOffset(self.transitionCoordinator.zoomedOutView.frame,
                                                           -self.collectionView.contentOffset.x,
                                                           -self.collectionView.contentOffset.y);
}

- (void)setAccessibilityLabels
{
  self.collectionView.isAccessibilityElement = YES;
  self.collectionView.accessibilityLabel = NSLocalizedString(ETLabelMonthDays, nil);
}

- (void)setUpBackgroundView
{
  self.collectionView.backgroundView = [[UIView alloc] init];
  self.collectionView.backgroundView.backgroundColor = [UIColor clearColor];
  self.collectionView.backgroundView.userInteractionEnabled = YES;
  [self.collectionView.backgroundView addGestureRecognizer:self.backgroundTapRecognizer];
}

#pragma mark Update

- (void)updateMeasures
{
  // Cell size.
  self.numberOfColumns = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 2 : 3;
  NSUInteger numberOfGutters = self.numberOfColumns - 1;
  CGFloat dimension = (self.view.frame.size.width - numberOfGutters * DayGutter);
  dimension = floorf(dimension / self.numberOfColumns);
  self.cellSize = CGSizeMake(dimension, dimension);
  // Misc.
  self.viewportYOffset = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
}

- (void)updateTitleView
{
  NSString *titleText;
  BOOL initialized = ![self.titleView.text isEqualToString:@"Label"];
  if (!self.allMonthDates.count) {
    // Default to app title.
    titleText = [NSBundle mainBundle].infoDictionary[@"CFBundleDisplayName"];
    NSLog(@"%@", titleText);
  } else {
    // Show month name.
    NSDate *monthDate = self.allMonthDates[self.currentSectionIndex];
    titleText = [self.monthFormatter stringFromDate:monthDate];
  }
  [self.titleView setText:titleText.uppercaseString animated:initialized];
}

- (void)toggleBackgroundViewHighlighted:(BOOL)highlighted
{
  static UIColor *originalBackgroundColor;
  UIView *backgroundView = self.collectionView.backgroundView;
  if (highlighted) {
    if (!originalBackgroundColor) {
      originalBackgroundColor = backgroundView.backgroundColor;
    }
    backgroundView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.05f];
  } else if (originalBackgroundColor) {
    backgroundView.backgroundColor = originalBackgroundColor;
  }
}

#pragma mark Teardown

- (void)tearDown
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark Handlers

- (void)eventAccessRequestDidComplete:(NSNotification *)notification
{
  NSString *result = notification.userInfo[ETEntityAccessRequestNotificationResultKey];
  if (result == ETEntityAccessRequestNotificationGranted) {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.year = 1;
    NSDate *endDate = [[NSCalendar currentCalendar] dateByAddingComponents:components toDate:self.currentDate options:0];
    NSOperation *operation = [self.eventManager fetchEventsFromDate:nil untilDate:endDate completion:^{
      //NSLog(@"Events: %@", self.eventManager.eventsByMonthsAndDays);
      [self.collectionView reloadData];
      [self updateTitleView];
    }];
  }
}

- (void)eventSaveOperationDidComplete:(NSNotification *)notification
{
  EKEntityType type = [notification.userInfo[ETEntityOperationNotificationTypeKey] unsignedIntegerValue];
  if (type == EKEntityTypeEvent) {
    EKEvent *event = (EKEvent *)(notification.userInfo[ETEntityOperationNotificationDataKey]);
    //NSLog(@"Saved event: %@", event);
    [self.eventManager invalidateDerivedCollections];
    [self.collectionView reloadData];
  }
}

@end
