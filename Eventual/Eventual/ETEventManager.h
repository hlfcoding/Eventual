//
//  ETEventManager.h
//  Eventual
//
//  Created by Nest Master on 11/7/13.
//  Copyright (c) 2013 Hashtag Studio. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const ETEntityAccessRequestNotification;

extern NSString *const ETEntityAccessRequestNotificationDenied;
extern NSString *const ETEntityAccessRequestNotificationError;
extern NSString *const ETEntityAccessRequestNotificationGranted;

extern NSString *const ETEntityAccessRequestNotificationErrorKey;
extern NSString *const ETEntityAccessRequestNotificationResultKey;
extern NSString *const ETEntityAccessRequestNotificationTypeKey;

typedef void(^ETFetchEventsCompletionHandler)();

@class EKEvent;
@class EKEventStore;

@interface ETEventManager : NSObject

@property (nonatomic, strong, readonly) NSArray *events;
@property (nonatomic, strong, readonly, getter = eventsByMonthsAndDays) NSDictionary *eventsByMonthsAndDays;

@property (nonatomic, strong, readonly) EKEventStore *store;

- (void)completeSetup;

- (NSOperation *)fetchEventsFromDate:(NSDate *)startDate
                           untilDate:(NSDate *)endDate
                          completion:(ETFetchEventsCompletionHandler)completion;

- (BOOL)saveEvent:(EKEvent *)event error:(NSError **)error;

- (BOOL)validateEvent:(EKEvent *)event error:(NSError **)error;

///--------------
/// @name Helpers
///--------------

- (NSDate *)dateFromAddingDays:(NSInteger)numberOfDays toDate:(NSDate *)date;

+ (ETEventManager *)defaultManager;

@end
