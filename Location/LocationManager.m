//
//  LocationManager.m
//  Location
//
//  Created by Oleksandr Chyzh on 3/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "LocationManager.h"
#import "AppDelegate.h"

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
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        self.locationManager.distanceFilter  = kCLDistanceFilterNone;
        self.locationManager.delegate = self;
        self.locationManager.allowsBackgroundLocationUpdates = true;
        
        [self.locationManager requestAlwaysAuthorization];
        
        self.startMonSignifOn = NO;
    }
    return self;
}

#pragma mark - PrivateMethods





#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
   // NSLog(@"didUpdateToLocation == %@",newLocation);
    
    if (self.inBackground) {
        [self.locationManager stopUpdatingLocation];
    }
    
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

- (void)stopMonitoringForRegion:(CLCircularRegion *)region {
    
    [self.locationManager stopMonitoringForRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location service failed with error %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    
    if (status == kCLAuthorizationStatusDenied) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Location Services Disabled!"
                                                                       message:@"Please enable Location. Settings > LocationmyLocation > Always"
                                                                preferredStyle:(UIAlertControllerStyleAlert)];
        
        
        UIAlertAction* noButton = [UIAlertAction
                                   actionWithTitle:@"Exit"
                                   style:UIAlertActionStyleDefault
                                   handler:^(UIAlertAction * action)
                                   {
                                       exit(2);
                                   }];
        
        [alert addAction:noButton];
        
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        window.rootViewController = [[UIViewController alloc] init];
        window.windowLevel = UIWindowLevelAlert + 1;
        [window makeKeyAndVisible];
        
        [window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}


@end
