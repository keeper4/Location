//
//  LocationManager.m
//  Location
//
//  Created by Oleksandr Chyzh on 3/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "LocationManager.h"
#import <MapKit/MKPointAnnotation.h>

NSString * const invokeLocalNotification = @"invokeLocalNotification";
NSString * const locationChangesNotification = @"locationChangesNotification";

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
        self.locationManager.distanceFilter = kCLDistanceFilterNone;
        self.locationManager.delegate = self;
        self.locationManager.allowsBackgroundLocationUpdates = true;
        
        [self.locationManager requestAlwaysAuthorization];
    }
    return self;
}

#pragma mark - PrivateMethods





#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    
    self.currentLocation = newLocation;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:locationChangesNotification object:self];
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    [self.locationManager stopMonitoringForRegion:region];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:invokeLocalNotification object:self];
}

- (void)startUpdatingLocation {
    
    [self.locationManager startUpdatingLocation];
}

- (void)stopUpdatingLocation {
    
    [self.locationManager stopUpdatingLocation];
}

- (void)startMonitoringSignificantLocationChanges {
    
    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void)stopMonitoringSignificantLocationChanges {
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)startMonitoringForRegion:(CLCircularRegion *)regoin {
    
    [self.locationManager startMonitoringForRegion:regoin];
}

- (void)stopMonitoringForRegion:(CLCircularRegion *)regoin {
    
    [self.locationManager stopMonitoringForRegion:regoin];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location service failed with error %@", error);
}

@end
