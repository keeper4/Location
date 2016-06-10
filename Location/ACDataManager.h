//
//  ACDataManager.h
//  Location
//
//  Created by Oleksandr Chyzh on 10/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <GoogleMaps/GMSMarker.h>

@interface ACDataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (strong, nonatomic) NSArray *allCourses;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;
- (void)addMarker:(GMSMarker *)marker namePointTextField:(NSString *)namePoint;

+ (ACDataManager*)sharedManager;
@end
