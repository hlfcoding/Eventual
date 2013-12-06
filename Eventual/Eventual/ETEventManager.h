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

@class EKEventStore;

@interface ETEventManager : NSObject

@property (strong, nonatomic, readonly) NSArray *events;
@property (strong, nonatomic, readonly, getter = eventsByMonthsAndDays) NSDictionary *eventsByMonthsAndDays;

@property (strong, nonatomic, readonly) EKEventStore *store;

- (void)completeSetup;
- (NSOperation *)fetchEventsFromDate:(NSDate *)startDate
                           untilDate:(NSDate *)endDate
                          completion:(ETFetchEventsCompletionHandler)completion;

@end