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

@interface ACMapController () <CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) CLCircularRegion *region;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender;

@end

@implementation ACMapController

static CLLocationDistance radius = 400;
//static NSUInteger filterMetrs = 50;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    self.mapView.delegate = self;
    
    self.locationManager = [[CLLocationManager alloc] init];
    
    self.locationManager.delegate = self;
    self.locationManager.distanceFilter  = kCLHeadingFilterNone;
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
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                       action:@selector(handleLongPress:)];
    lpgr.delegate = self;
    
    [self.mapView addGestureRecognizer:lpgr];
}

#pragma mark - private Methods

- (void)DidEnterBackground {
    
    [self.locationManager stopUpdatingLocation];
    
    [self.locationManager startMonitoringSignificantLocationChanges];
}

- (void)WillEnterForeground {
    
    [self.locationManager stopMonitoringSignificantLocationChanges];
    
    [self.locationManager startUpdatingLocation];
}

- (void)drawCircularOverlayCuestaCoordinate:(CLLocationCoordinate2D)cuestaCoordinate {
    
    [self.mapView removeOverlays: [self.mapView overlays]];
    
    MKCircle *outerCircle = [MKCircle circleWithCenterCoordinate:cuestaCoordinate radius:radius];
    
    [self.mapView addOverlay: outerCircle];
}

- (double)distanceToPoint:(MKPointAnnotation *)finishPoint pointNow:(CLLocation *)pointNow{
    
    CLLocation *endPoint = [[CLLocation alloc] initWithLatitude:finishPoint.coordinate.latitude longitude:finishPoint.coordinate.longitude];
    
    CLLocationDistance meters = [endPoint distanceFromLocation:pointNow];
    
    return meters;
}

- (MKPointAnnotation *)getAnnotationFromMapView:(MKMapView *)mapView {
    
    MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
    
    for (id annotat in mapView.annotations) {
        
        if ([annotat isKindOfClass:[MKPointAnnotation class]]) {
            
            annotation = annotat;
        }
    }
    return annotation;
}

#pragma mark - MKMapViewDelegate

- (MKOverlayRenderer*)mapView:(MKMapView*)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    
    MKCircleRenderer *circleRenderer = [[MKCircleRenderer alloc]initWithCircle:overlay];
    circleRenderer.fillColor = [[UIColor greenColor] colorWithAlphaComponent:0.2];
    circleRenderer.strokeColor = [[UIColor blackColor] colorWithAlphaComponent:0.4];
    circleRenderer.lineWidth = 3;
    
    return circleRenderer;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray<MKAnnotationView *> *)views {
    
    if (mapView.overlays.count != 0) {
        
        MKPointAnnotation *annotation = [self getAnnotationFromMapView:mapView];
        
        CLLocationCoordinate2D location2D =
        CLLocationCoordinate2DMake(annotation.coordinate.latitude, annotation.coordinate.longitude);
        
        self.region = [[CLCircularRegion alloc] initWithCenter:location2D
                                                        radius:radius
                                                    identifier:@"theRegion"];
      
        [self.locationManager startMonitoringForRegion:self.region];
    }
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    
    [self.locationManager stopMonitoringForRegion:self.region];
    
    MKPointAnnotation *annotation = [self getAnnotationFromMapView:self.mapView];
    
    CLLocationDistance meters = [self distanceToPoint: annotation pointNow:manager.location];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.fireDate = [NSDate date];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertAction = @"Let's do this";
    notification.alertBody = [NSString stringWithFormat:@"Meters to Final Point %.0f", meters];
    
    [[UIApplication sharedApplication]scheduleLocalNotification:notification];
}

#pragma mark - UIGestureRecognizerDelegate

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        
        [self.locationManager stopMonitoringForRegion:self.region];
        
        for (id annotat in self.mapView.annotations) {
            
            if ([annotat isKindOfClass:[MKPointAnnotation class]]) {
                
                [self.mapView removeAnnotation:annotat];
            }
        }
        
        CGPoint point = [gestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D locCoord = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
        
        MKPointAnnotation *dropPin = [[MKPointAnnotation alloc] init];
        
        dropPin.coordinate = locCoord;
        
        [self.mapView addAnnotation:dropPin];
        
        [self drawCircularOverlayCuestaCoordinate:locCoord];
    }
}

#pragma mark - Action

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender {
    
    [self.locationManager stopUpdatingLocation];
    [self.locationManager stopMonitoringForRegion:self.region];
    [self.locationManager stopMonitoringSignificantLocationChanges];
    
    exit(0);
}





@end
