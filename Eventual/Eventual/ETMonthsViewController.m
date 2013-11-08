//
//  ETMonthsViewController.m
//  Eventual
//
//  Created by Nest Master on 11/5/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETMonthsViewController.h"

#import "ETDayViewCell.h"
#import "ETEventManager.h"
#import "ETMonthHeaderView.h"

CGFloat const DayGutter = 2.0f;
CGFloat const MonthGutter = 50.0f;

@interface ETMonthsViewController ()

@property (strong, nonatomic) NSDate *currentDate;
@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSDateFormatter *formatter;
@property (nonatomic) NSUInteger numberOfMonths;
@property (nonatomic) CGSize cellSize;

- (void)eventAccessRequestDidComplete:(NSNotification *)notification;

- (void)setup;
- (void)updateCellSize;

@end

@implementation ETMonthsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) [self setup];
  return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
  self = [super initWithCoder:aDecoder];
  if (self) [self setup];
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  // Do any additional setup after loading the view.
  [self updateCellSize];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self updateCellSize];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return self.numberOfMonths;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  return 3; // TODO
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ETDayViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Day" forIndexPath:indexPath];
  cell.dayNumber = 1;
  cell.numberOfEvents = 1;
  return cell;
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
  if (kind == UICollectionElementKindSectionHeader) {
    ETMonthHeaderView *headerView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:@"Month" forIndexPath:indexPath];
    headerView.monthName = self.formatter.monthSymbols[indexPath.section];
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

#pragma mark - Private

- (void)setup
{
  self.currentDate = [NSDate date];
  self.calendar = [NSCalendar currentCalendar];
  self.formatter = [[NSDateFormatter alloc] init];
  self.numberOfMonths = self.formatter.monthSymbols.count;
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventAccessRequestDidComplete:)
                                               name:ETEntityAccessRequestNotification object:nil];

}

- (void)updateCellSize
{
  NSUInteger numberOfColumns = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 2 : 3;
  NSUInteger numberOfGutters = numberOfColumns - 1;
  CGFloat dimension = (self.view.frame.size.width - numberOfGutters * DayGutter);
  dimension = floorf(dimension / numberOfColumns);
  self.cellSize = CGSizeMake(dimension, dimension);
}

- (void)eventAccessRequestDidComplete:(NSNotification *)notification
{
  NSString *result = notification.userInfo[ETEntityAccessRequestNotificationResultKey];
  if (result == ETEntityAccessRequestNotificationGranted) {
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day = 1;
    NSDate *endDate = [self.calendar dateByAddingComponents:components toDate:self.currentDate options:0];
    NSOperation *operation = [self.eventManager fetchEventsFromDate:nil untilDate:endDate completion:^{
      NSLog(@"Events: %@", self.eventManager.events);
      [self.collectionView reloadData];
    }];
  }
}

@end
