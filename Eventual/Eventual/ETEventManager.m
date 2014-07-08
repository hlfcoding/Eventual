//
//  ETEventManager.m
//  Eventual
//
//  Created by Peng Wang <peng@pengxwang.com> on 11/7/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import "ETEventManager.h"

#import <EventKit/EventKit.h>

#import "ETAppDelegate.h"

NSString *const ETEntityAccessRequestNotification = @"ETEntityAccess";

NSString *const ETEntityAccessRequestNotificationDenied = @"ETEntityAccessDenied";
NSString *const ETEntityAccessRequestNotificationError = @"ETEntityAccessError";
NSString *const ETEntityAccessRequestNotificationGranted = @"ETEntityAccessGranted";

NSString *const ETEntityAccessRequestNotificationErrorKey = @"ETEntityAccessErrorKey";
NSString *const ETEntityAccessRequestNotificationResultKey = @"ETEntityAccessResultKey";
NSString *const ETEntityAccessRequestNotificationTypeKey = @"ETEntityAccessTypeKey";

NSString *const ETEntitySaveOperationNotification = @"ETEntitySaveOperation";
NSString *const ETEntityOperationNotificationTypeKey = @"ETEntityOperationTypeKey";
NSString *const ETEntityOperationNotificationDataKey = @"ETEntityOperationDataKey";

NSString *const ETEntityCollectionDatesKey = @"dates";
NSString *const ETEntityCollectionDaysKey = @"days";
NSString *const ETEntityCollectionEventsKey = @"events";

@interface ETEventManager ()

@property (nonatomic, strong, readwrite, setter = setMutableEvents:) NSMutableArray *mutableEvents;
@property (nonatomic, strong, readwrite) NSDictionary *eventsByMonthsAndDays;

@property (nonatomic, strong, readwrite) EKEventStore *store;

@property (nonatomic, strong) NSArray *calendars;
@property (nonatomic, strong) EKCalendar *calendar;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

- (void)setUp;

- (BOOL)invalidateEvents;
- (BOOL)addEvent:(EKEvent *)event;

@end

@implementation ETEventManager

- (id)init
{
  self = [super init];
  if (self) [self setUp];
  return self;
}

#pragma mark - Public

- (NSArray *)events
{
  return self.mutableEvents;
}

- (NSDictionary *)eventsByMonthsAndDays
{
  if (!self.events) {
    NSLog(@"WARNING: Trying to access events before fetching.");
    return nil;
  }
  if (!_eventsByMonthsAndDays) {
    NSMutableDictionary *months = [NSMutableDictionary dictionary];
    NSMutableArray *monthsDates = [NSMutableArray array];
    NSMutableArray *monthsDays = [NSMutableArray array];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    for (EKEvent *event in self.events) {
      NSDateComponents *monthComponents = [calendar components:NSMonthCalendarUnit|NSYearCalendarUnit fromDate:event.startDate];
      NSDateComponents *dayComponents = [calendar components:NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit fromDate:event.startDate];
      NSDate *monthDate = [calendar dateFromComponents:monthComponents];
      NSDate *dayDate = [calendar dateFromComponents:dayComponents];
      NSMutableDictionary *days;
      NSMutableArray *daysDates;
      NSMutableArray *daysEvents;
      NSMutableArray *events;
      NSUInteger monthIndex = [monthsDates indexOfObject:monthDate];
      if (monthIndex == NSNotFound) {
        [monthsDates addObject:monthDate];
        days = [NSMutableDictionary dictionary];
        daysDates = [NSMutableArray array];
        daysEvents = [NSMutableArray array];
        days[ETEntityCollectionDatesKey] = daysDates;
        days[ETEntityCollectionEventsKey] = daysEvents;
        [monthsDays addObject:days];
      } else {
        days = monthsDays[monthIndex];
        daysDates = days[ETEntityCollectionDatesKey];
        daysEvents = days[ETEntityCollectionEventsKey];
      }
      NSUInteger dayIndex = [daysDates indexOfObject:dayDate];
      if (dayIndex == NSNotFound) {
        [daysDates addObject:dayDate];
        events = [NSMutableArray array];
        [daysEvents addObject:events];
      } else {
        events = daysEvents[dayIndex];
      }
      [events addObject:event];
    }
    months[ETEntityCollectionDatesKey] = monthsDates;
    months[ETEntityCollectionDaysKey] = monthsDays;
    self.eventsByMonthsAndDays = months;
  }
  return _eventsByMonthsAndDays;
}

- (void)completeSetup
{
  [self.store requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *accessError) {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[ETEntityAccessRequestNotificationTypeKey] = @( EKEntityTypeEvent );
    if (granted) {
      userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationGranted;
      self.calendars = [self.store calendarsForEntityType:EKEntityTypeEvent];
      self.calendar = self.store.defaultCalendarForNewEvents;
    } else if (!granted) {
      userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationDenied;
    } else if (accessError) {
      userInfo[ETEntityAccessRequestNotificationResultKey] = ETEntityAccessRequestNotificationError;
      userInfo[ETEntityAccessRequestNotificationErrorKey] = accessError;
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ETEntityAccessRequestNotification object:self
                                                      userInfo:userInfo];
  }];
}

- (NSOperation *)fetchEventsFromDate:(NSDate *)startDate untilDate:(NSDate *)endDate completion:(ETFetchEventsCompletionHandler)completion
{
  if (!startDate) {
    startDate = [NSDate date];
  }
  NSAssert(endDate, @"`endDate` is required.");
  NSAssert(completion, @"`completion` is required.");
  NSPredicate *predicate = [self.store predicateForEventsWithStartDate:startDate endDate:endDate calendars:self.calendars];
  NSOperation *fetchOperation = [NSBlockOperation blockOperationWithBlock:^{
    NSArray *events = [self.store eventsMatchingPredicate:predicate];
    self.mutableEvents = events.mutableCopy;
  }];
  [fetchOperation setQueuePriority:NSOperationQueuePriorityVeryHigh];
  NSOperation *completionOperation = [NSBlockOperation blockOperationWithBlock:completion];
  [completionOperation addDependency:fetchOperation];
  [self.operationQueue addOperation:fetchOperation];
  [[NSOperationQueue mainQueue] addOperation:completionOperation];
  return fetchOperation;
}

- (BOOL)saveEvent:(EKEvent *)event error:(NSError *__autoreleasing *)error
{
  if (![self validateEvent:event error:error]) return NO;
  BOOL didSave = [self.store saveEvent:event span:EKSpanThisEvent commit:YES error:error];
  if (didSave) {
    [self addEvent:event];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    userInfo[ETEntityOperationNotificationTypeKey] = @( EKEntityTypeEvent );
    userInfo[ETEntityOperationNotificationDataKey] = event;
    [[NSNotificationCenter defaultCenter] postNotificationName:ETEntitySaveOperationNotification object:self
                                                      userInfo:userInfo];
  }
  return didSave;
}

- (BOOL)validateEvent:(EKEvent *)event error:(NSError *__autoreleasing *)error
{
  static NSString *failureReasonNone = @"";
  NSMutableDictionary *userInfo = @{ NSLocalizedDescriptionKey: NSLocalizedString(@"Event is invalid. ", nil),
                                     NSLocalizedFailureReasonErrorKey: failureReasonNone,
                                     NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Please make sure event is filled in. ", nil) }.mutableCopy;
  if (!event.calendar) {
    event.calendar = self.store.defaultCalendarForNewEvents;
  }
  if (!event.endDate ||
      [event.endDate compare:event.startDate] != NSOrderedDescending // Isn't later.
      ) {
    event.endDate = [self dateFromAddingDays:1 toDate:event.startDate];
  }
  if (!event.title.length) {
    userInfo[NSLocalizedFailureReasonErrorKey] = [(NSString *)userInfo[NSLocalizedFailureReasonErrorKey]
                                                  stringByAppendingString:NSLocalizedString(@"Event title is required. ", nil)];
  }
  if (!event.startDate) {
    userInfo[NSLocalizedFailureReasonErrorKey] = [(NSString *)userInfo[NSLocalizedFailureReasonErrorKey]
                                                  stringByAppendingString:NSLocalizedString(@"Event start date is required. ", nil)];
  }
  if (!event.endDate) {
    userInfo[NSLocalizedFailureReasonErrorKey] = [(NSString *)userInfo[NSLocalizedFailureReasonErrorKey]
                                                  stringByAppendingString:NSLocalizedString(@"Event end date is required. ", nil)];
  }
  BOOL isValid = userInfo[NSLocalizedFailureReasonErrorKey] == failureReasonNone;
  if (!isValid) {
    *error = [NSError errorWithDomain:ETErrorDomain
                                 code:ETErrorCodeInvalidObject
                             userInfo:userInfo];
  }
  return isValid;
}

#pragma mark Helpers

- (NSDate *)dateFromAddingDays:(NSInteger)numberOfDays toDate:(NSDate *)date
{
  if (!date) return date;
  NSCalendar *calendar = [NSCalendar currentCalendar];
  NSDateComponents *dayComponents = [calendar components:(NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit|
                                                          NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit)
                                                fromDate:date];
  dayComponents.hour = dayComponents.minute = dayComponents.second = 0;
  dayComponents.day += numberOfDays;
  NSDate *newDate = [calendar dateFromComponents:dayComponents];
  return newDate;
}

+ (ETEventManager *)defaultManager
{
  return ((ETAppDelegate *)[UIApplication sharedApplication].delegate).eventManager;
}

#pragma mark - Private

#pragma mark Accessors

- (void)setMutableEvents:(NSMutableArray *)mutableEvents
{
  if (mutableEvents && mutableEvents == self.mutableEvents) return;
  _mutableEvents = mutableEvents ? mutableEvents : [NSMutableArray array];
  [self invalidateEvents];
}

#pragma mark Setup

- (void)setUp
{
  self.store = [[EKEventStore alloc] init];
  self.operationQueue = [[NSOperationQueue alloc] init];
}

#pragma mark Update

- (BOOL)invalidateEvents
{
  BOOL didInvalidate = NO;
  if (self.eventsByMonthsAndDays) {
    self.eventsByMonthsAndDays = nil;
    didInvalidate = YES;
  }
  return didInvalidate;
}

- (BOOL)addEvent:(EKEvent *)event
{
  BOOL didAdd = NO;
  if (![self.mutableEvents containsObject:event]) { // TODO: Naive.
    [self.mutableEvents addObject:event];
    [self.mutableEvents sortUsingSelector:@selector(compareStartDateWithEvent:)];
    [self invalidateEvents];
    didAdd = YES;
  }
  return didAdd;
}

@end
