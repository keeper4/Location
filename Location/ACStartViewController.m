//
//  ACStartViewController.m
//  Location
//
//  Created by Oleksandr Chyzh on 27/5/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACStartViewController.h"
#import <CoreLocation/CoreLocation.h>

typedef void(^locationHandler)(CLLocation *location);

@interface ACStartViewController () <CLLocationManagerDelegate>


@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, copy) locationHandler locationUpdatedInForeground;
@property (nonatomic, copy) locationHandler locationUpdatedInBackground;

@property (strong, nonatomic) CLCircularRegion *region;
@end

@implementation ACStartViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.locationManager = [[CLLocationManager alloc] init];
//    self.locationManager.delegate = self;
//    self.locationManager.distanceFilter  = kCLDistanceFilterNone;
//    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//    self.locationManager.pausesLocationUpdatesAutomatically = false;
//    
//    CLLocationCoordinate2D coordinate;
//    
//    coordinate.latitude  = 50.444202;
//    coordinate.longitude = 30.443606;
//    
//    [self.locationManager requestAlwaysAuthorization];
//    
//    
//    CLLocationDistance radius = 100.00;
//    
//    CLLocationCoordinate2D location2D = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude);
//    
//    self.region = [[CLCircularRegion alloc] initWithCenter:location2D
//                                                    radius:radius
//                                                identifier:@"theRegion"];
//    self.region.notifyOnEntry = true;
//    
//   // [self.locationManager startMonitoringForRegion:self.region];
//    
//    [self.locationManager startMonitoringSignificantLocationChanges];
//    [self.locationManager startMonitoringForRegion:self.region];
// 
//    
}

- (void)startUpdatingLocation {
    
}

- (void)stopUpdatingLocation {
    
}

- (void)endBackgroundTask {
    
}












@end
