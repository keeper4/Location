//
//  LocationManager.m
//  Location
//
//  Created by Oleksandr Chyzh on 3/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "LocationManager.h"

@interface LocationManager ()
@end

@implementation LocationManager

+ (LocationManager *) sharedInstance {
    static LocationManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc]init];
    });
    return instance;
}

- (id)init {
    self = [super init];
    if(self != nil) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = kCLDistanceFilterNone; // meters
        self.locationManager.delegate = self;
    }
    return self;
}

- (void)startUpdatingLocation {
    
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location service failed with error %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray*)locations {
    CLLocation *location = [locations lastObject];

    self.currentLocation = location;
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
//    [self.locationManager stopMonitoringForRegion:region];
//    
//    MKPointAnnotation *annotation = [self getAnnotationFromMapView:self.mapView];
//    
//    CLLocationDistance meters = [self distanceToPoint: annotation pointNow:manager.location];
//    
//    [[UIApplication sharedApplication] cancelAllLocalNotifications];
//    
//    UILocalNotification *notification = [[UILocalNotification alloc] init];
//    
//    notification.fireDate = [NSDate date];
//    notification.timeZone = [NSTimeZone defaultTimeZone];
//    
//    notification.soundName = UILocalNotificationDefaultSoundName;
//    notification.alertAction = @"Let's do this";
//    notification.alertBody = [NSString stringWithFormat:@"Meters to Final Point %.0f", meters];
//    
//    [[UIApplication sharedApplication]scheduleLocalNotification:notification];
}

@end
