//
//  LocationManager.h
//  Location
//
//  Created by Oleksandr Chyzh on 3/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

extern NSString * const invokeLocalNotification;

@interface LocationManager : NSObject <CLLocationManagerDelegate>

+ (LocationManager *)sharedInstance;

@property (strong, nonatomic) CLLocationManager *locationManager;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (void)startMonitoringSignificantLocationChanges;
- (void)stopMonitoringSignificantLocationChanges;
- (void)startMonitoringForRegion:(CLCircularRegion *)regoin;
- (void)stopMonitoringForRegion:(CLCircularRegion *)regoin;

@end
