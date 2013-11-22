//
//  ETMonthsViewController.m
//  Eventual
//
//  Created by Nest Master on 11/5/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETMonthsViewController.h"

#import <EventKit/EKEvent.h>

#import "ETDayViewCell.h"
#import "ETDayViewController.h"
#import "ETEventManager.h"
#import "ETEventViewController.h"
#import "ETMonthHeaderView.h"
#import "ETNavigationTitleView.h"

// TODO: User refreshing.
// TODO: Navigation.
// TODO: Add day.
// TODO: Drag and drop. Delete tile.

CGFloat const DayGutter = 2.0f;
CGFloat const MonthGutter = 50.0f;

@interface ETMonthsViewController ()

<UICollectionViewDelegateFlowLayout>

@property (strong, nonatomic) NSDate *currentDate;
@property (strong, nonatomic) NSDateFormatter *dayFormatter;
@property (strong, nonatomic) NSDateFormatter *monthFormatter;

@property (strong, nonatomic, readonly, getter = dataSource) NSDictionary *dataSource;
@property (strong, nonatomic) NSArray *allMonthDates;

@property (nonatomic) CGSize cellSize;
@property (nonatomic, setter = setCurrentSectionIndex:) NSUInteger currentSectionIndex;
@property (nonatomic) CGPoint previousContentOffset;
@property (nonatomic) CGFloat viewportYOffset;
@property (strong, nonatomic) IBOutlet ETNavigationTitleView *titleView;
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *backgroundTapGesture;

- (NSDate *)dayDateAtIndexPath:(NSIndexPath *)indexPath;
- (NSArray *)dayEventsAtIndexPath:(NSIndexPath *)indexPath;

- (void)eventAccessRequestDidComplete:(NSNotification *)notification;

- (IBAction)addDayAction:(id)sender;

- (void)setUp;
- (void)setAccessibilityLabels;
- (void)updateMeasures;
- (void)updateTitleView;

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

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self setAccessibilityLabels];
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
  if ([segue.destinationViewController isKindOfClass:[ETDayViewController class]]) {
    
    NSArray *indexPaths = self.collectionView.indexPathsForSelectedItems;
    if (!indexPaths.count) return;
    NSIndexPath *indexPath = indexPaths.firstObject;
    ETDayViewController *viewController = (ETDayViewController *)segue.destinationViewController;
    viewController.dayDate = [self dayDateAtIndexPath:indexPath];
    viewController.dayEvents = [self dayEventsAtIndexPath:indexPath];
    
  } else if ([segue.destinationViewController isKindOfClass:[ETEventViewController class]]) {
    
    ETEventViewController *viewController = (ETEventViewController *)segue.destinationViewController;
    
  }
}

#pragma mark - Actions

- (IBAction)addDayAction:(id)sender
{
  if (sender == self.backgroundTapGesture) {
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:[gestureRecognizer locationInView:self.collectionView]];
    if (indexPath) return;
    [self performSegueWithIdentifier:@"Add Day" sender:sender];
  }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  NSInteger number = 0;
  if (self.dataSource) {
    number = self.dataSource.count;
  }
  return number;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  NSInteger number = 0;
  if (self.dataSource) {
    NSDictionary *monthDays = self.dataSource[self.allMonthDates[section]];
    number = monthDays.count;
  }
  return number;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ETDayViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Day" forIndexPath:indexPath];
  [cell setAccessibilityLabelsWithIndexPath:indexPath];
  if (self.dataSource) {
    NSDate *dayDate = [self dayDateAtIndexPath:indexPath];
    NSArray *dayEvents = [self dayEventsAtIndexPath:indexPath];
    cell.dayText = [self.dayFormatter stringFromDate:dayDate];
    cell.numberOfEvents = dayEvents.count;
  }
  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  if (kind == UICollectionElementKindSectionHeader) {
    if (!self.dataSource) return nil;
    NSUInteger index = indexPath.section;
    ETMonthHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Month" forIndexPath:indexPath];
    NSDate *monthDate = self.dataSource.allKeys[index];
    headerView.monthName = [self.monthFormatter stringFromDate:monthDate];
    return headerView;
  }
  return nil;
}

#pragma mark - UICollectionViewDelegate

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
    NSUInteger nextIndex = (direction == 1 && self.currentSectionIndex < self.dataSource.count) ? self.currentSectionIndex + 1 : NSNotFound;
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

#pragma mark - Private

- (void)setUp
{
  self.currentDate = [NSDate date];
  self.dayFormatter = [[NSDateFormatter alloc] init];
  self.dayFormatter.dateFormat = @"d";
  self.monthFormatter = [[NSDateFormatter alloc] init];
  self.monthFormatter.dateFormat = @"MMMM";
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventAccessRequestDidComplete:)
                                               name:ETEntityAccessRequestNotification object:nil];
}

- (void)setAccessibilityLabels
{
  self.collectionView.isAccessibilityElement = YES;
  self.collectionView.accessibilityLabel = NSLocalizedString(ETMonthDaysLabel, nil);
}

# pragma mark Data

- (NSDictionary *)dataSource
{
  if (self.eventManager.events && !self.allMonthDates) {
    self.allMonthDates = self.eventManager.eventsByMonthsAndDays.allKeys;
  }
  return self.eventManager.events ? self.eventManager.eventsByMonthsAndDays : nil;
}

- (NSDate *)dayDateAtIndexPath:(NSIndexPath *)indexPath
{
  NSDictionary *monthDays = self.dataSource[self.allMonthDates[indexPath.section]];
  return monthDays.allKeys[indexPath.item];
}
- (NSArray *)dayEventsAtIndexPath:(NSIndexPath *)indexPath
{
  NSDictionary *monthDays = self.dataSource[self.allMonthDates[indexPath.section]];
  NSDate *dayDate = [self dayDateAtIndexPath:indexPath];
  return monthDays[dayDate];
}

# pragma mark UI

- (void)setCurrentSectionIndex:(NSUInteger)currentSectionIndex
{
  if (currentSectionIndex == _currentSectionIndex) return;
  _currentSectionIndex = currentSectionIndex;
  [self updateTitleView];
}

- (void)updateMeasures
{
  // Cell size.
  NSUInteger numberOfColumns = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 2 : 3;
  NSUInteger numberOfGutters = numberOfColumns - 1;
  CGFloat dimension = (self.view.frame.size.width - numberOfGutters * DayGutter);
  dimension = floorf(dimension / numberOfColumns);
  self.cellSize = CGSizeMake(dimension, dimension);
  // Misc.
  self.viewportYOffset = [UIApplication sharedApplication].statusBarFrame.size.height + self.navigationController.navigationBar.frame.size.height;
}

- (void)updateTitleView
{
  NSDate *monthDate = self.dataSource.allKeys[self.currentSectionIndex];
  [self.titleView setText:[self.monthFormatter stringFromDate:monthDate] animated:YES];
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

@end
