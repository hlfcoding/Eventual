//
//  EVTAppDelegate.h
//  Eventual
//
//  Created by Peng Wang on 10/20/13.
//  Copyright (c) 2013 Jussttin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EVTAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
