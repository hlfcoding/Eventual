//
//  ETDayViewController.m
//  Eventual
//
//  Created by Nest Master on 11/13/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETDayViewController.h"

#import <EventKit/EKEvent.h>

#import "ETEventManager.h"
#import "ETEventViewCell.h"

@interface ETDayViewController ()

@property (strong, nonatomic) NSDateFormatter *titleFormatter;

@property (strong, nonatomic, readonly, getter = dataSource) NSArray *dataSource;

- (void)setUp;

@end

@implementation ETDayViewController

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
  self.title = [self.titleFormatter stringFromDate:self.dayDate];
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
  return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
  NSInteger number = 0;
  if (self.dataSource) {
    number = self.dataSource.count;
  }
  return number;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  ETEventViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Event" forIndexPath:indexPath];
  if (self.dataSource) {
    EKEvent *event = self.dataSource[indexPath.item];
    cell.eventText = event.title;
  }
  return cell;
}

#pragma mark - UICollectionViewDelegate

#pragma mark - UICollectionViewFlowLayout

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
  return 1.0f;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
  return 1.0f;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
  return CGSizeMake(self.collectionView.frame.size.width, 75.0f);
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
  return UIEdgeInsetsZero;
}

#pragma mark - Private

- (void)setUp
{
  self.titleFormatter = [[NSDateFormatter alloc] init];
  self.titleFormatter.dateFormat = @"MMMM d";
}

#pragma mark Data

- (NSArray *)dataSource
{
  return self.dayEvents ? self.dayEvents : nil;
}

@end
