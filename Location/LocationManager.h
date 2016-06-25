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
extern NSString * const locationChangesNotification;

@interface LocationManager : NSObject <CLLocationManagerDelegate>

+ (LocationManager *)sharedInstance;

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (assign, nonatomic) BOOL inBackground;
@property (assign, nonatomic) BOOL startMonSignifOn;

- (void)startUpdatingLocation;
- (void)stopUpdatingLocation;
- (void)startMonitoringSignificantLocationChanges;
- (void)stopMonitoringSignificantLocationChanges;
- (void)startMonitoringForRegion:(CLCircularRegion *)regoin;
- (void)stopMonitoringForRegion:(CLCircularRegion *)regoin;
@end
