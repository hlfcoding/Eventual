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

@interface ETEventManager : NSObject

@property (strong, nonatomic, readonly) NSArray *events;

- (void)completeSetup;
- (NSOperation *)fetchEventsFromDate:(NSDate *)startDate
                           untilDate:(NSDate *)endDate
                          completion:(ETFetchEventsCompletionHandler)completion;

@end
