//
//  ACMarker+CoreDataProperties.h
//  Location
//
//  Created by Oleksandr Chyzh on 10/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "ACMarker.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACMarker (CoreDataProperties)
@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSString *snippet;
@property (nullable, nonatomic, retain) NSNumber *longitude;
@property (nullable, nonatomic, retain) NSNumber *latitude;

@end

NS_ASSUME_NONNULL_END
