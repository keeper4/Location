//
//  ACMapController.m
//  Location
//
//  Created by Oleksandr Chyzh on 1/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACMapController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

@interface ACMapController () <CLLocationManagerDelegate, MKMapViewDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) MKPointAnnotation *annotation;
@property (strong, nonatomic) CLCircularRegion *region;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)addButton:(UIBarButtonItem *)sender;
- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender;
@end

@implementation ACMapController

static CLLocationDistance radius = 400;
static NSUInteger filterMetrs = 50;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    self.mapView.delegate = self;
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter  = filterMetrs;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    self.locationManager.allowsBackgroundLocationUpdates = true;
    
    
    
    [self.locationManager requestAlwaysAuthorization];
    
    [self.locationManager startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(DidEnterBackground)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(WillEnterForeground)
                                                name:UIApplicationWillEnterForegroundNotification
                                              object:nil];
    
}

- (void)DidEnterBackground {
    
    
    [self.locationManager stopUpdatingLocation];
   

    self.locationManager.distanceFilter  = kCLDistanceFilterNone;
    
    [self.locationManager startMonitoringSignificantLocationChanges];
    
     // NSLog(@"DidEnterBackground -%@, man -%f", self.region, self.locationManager.location.coordinate.longitude);
}

- (void)WillEnterForeground {
    
    [self.locationManager stopMonitoringSignificantLocationChanges];
    
    self.locationManager.distanceFilter  = filterMetrs;
    
    [self.locationManager startUpdatingLocation];
    
    //  NSLog(@"DidBecomeActive -%@, man -%f", self.region, self.locationManager.location.coordinate.longitude);
}
#pragma mark - MKMapViewDelegate

- (MKOverlayRenderer*)mapView:(MKMapView*)mapView rendererForOverlay:(id <MKOverlay>)overlay
{
    
    MKCircleRenderer * circleRenderer = [[MKCircleRenderer alloc]initWithCircle:overlay];
    circleRenderer.fillColor = [[UIColor greenColor] colorWithAlphaComponent:0.2];
    circleRenderer.strokeColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    circleRenderer.lineWidth = 3;
    
    return circleRenderer;
}

#pragma mark - private Methods

- (void) drawCircularOverlayCuestaCoordinate:(CLLocationCoordinate2D)cuestaCoordinate {

    [self.mapView removeOverlays: [self.mapView overlays]];

    MKCircle* outerCircle = [MKCircle circleWithCenterCoordinate: cuestaCoordinate radius: radius];
    
    [self.mapView addOverlay: outerCircle];
    
    CLLocationCoordinate2D location2D =
    CLLocationCoordinate2DMake(self.annotation.coordinate.latitude, self.annotation.coordinate.longitude);
    
    self.region = [[CLCircularRegion alloc] initWithCenter:location2D
                                                    radius:radius
                                                identifier:@"theRegion"];
    
    [self.locationManager startMonitoringForRegion:self.region];

}

#pragma mark - Action

- (IBAction)addButton:(UIBarButtonItem *)sender {
    
    if (self.annotation) {
        
        [self.locationManager stopMonitoringForRegion:self.region];
        
        for (MKPointAnnotation *anno in self.mapView.annotations) {
            
            [self.mapView removeAnnotation:anno];
        }
    }
    
    self.annotation = [[MKPointAnnotation alloc] init];
    
    self.annotation.coordinate = self.mapView.region.center;
    
    [self.mapView addAnnotation:self.annotation];
    
    
    [self drawCircularOverlayCuestaCoordinate:self.annotation.coordinate];
    

}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    [self.locationManager stopMonitoringForRegion:self.region];
    [self.locationManager stopUpdatingLocation];
    
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.fireDate = [NSDate date];
    NSTimeZone* timezone = [NSTimeZone defaultTimeZone];
    notification.timeZone = timezone;
    notification.alertBody = @"didEnterRegion!!!";
    notification.alertAction = @"Show";
    notification.soundName = UILocalNotificationDefaultSoundName;
    [[UIApplication sharedApplication] scheduleLocalNotification:notification];

}



- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender {
    
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringForRegion:self.region];
    [self.locationManager stopUpdatingLocation];
    
    exit(0);
    
}
@end
