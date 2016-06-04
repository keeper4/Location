//
//  ACMapController.m
//  Location
//
//  Created by Oleksandr Chyzh on 1/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACMapController.h"
#import <MapKit/MapKit.h>
#import "LocationManager.h"

@interface ACMapController () <CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) CLCircularRegion *region;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender;

@end

@implementation ACMapController

static CLLocationDistance radius = 400;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MKUserTrackingModeFollow;
    self.mapView.delegate = self;
    
    [[LocationManager sharedInstance] startUpdatingLocation];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(didEnterBackground)
                                                name:UIApplicationDidEnterBackgroundNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(willEnterForeground)
                                                name:UIApplicationWillEnterForegroundNotification
                                              object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(youInRegionNotification)
                                                name:invokeLocalNotification
                                              object:nil];
    
    UILongPressGestureRecognizer *lpgr = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self
                                                  action:@selector(handleLongPress:)];
    lpgr.delegate = self;
    
    [self.mapView addGestureRecognizer:lpgr];
}

#pragma mark - private Methods

- (void)didEnterBackground {
    
    [[LocationManager sharedInstance] stopUpdatingLocation];
    
    [[LocationManager sharedInstance] startMonitoringSignificantLocationChanges];
}

- (void)willEnterForeground {
    
    [[LocationManager sharedInstance] stopMonitoringSignificantLocationChanges];
    
    [[LocationManager sharedInstance] startUpdatingLocation];
}

- (void)youInRegionNotification {
    
    MKPointAnnotation *annotation = [self getAnnotationFromMapView:self.mapView];
    
    CLLocationDistance meters = [self distanceToPoint: annotation];
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.fireDate = [NSDate date];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertAction = @"Let's do this";
    
    notification.alertBody = [NSString stringWithFormat:@"Meters to Final Point %.0f", meters];
    
    [[UIApplication sharedApplication]scheduleLocalNotification:notification];
}

- (double)distanceToPoint:(MKPointAnnotation *)finishPoint {
    
    CLLocation *endPoint = [[CLLocation alloc] initWithLatitude:finishPoint.coordinate.latitude longitude:finishPoint.coordinate.longitude];
    
    double lat = [LocationManager sharedInstance].locationManager.location.coordinate.latitude;
    double lon = [LocationManager sharedInstance].locationManager.location.coordinate.longitude;
    
    CLLocation *userLocation = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
    
    CLLocationDistance meters = [endPoint distanceFromLocation:userLocation];
    
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

- (void)drawCircularOverlayCuestaCoordinate:(CLLocationCoordinate2D)cuestaCoordinate {
    
    [self.mapView removeOverlays: [self.mapView overlays]];
    
    MKCircle *outerCircle = [MKCircle circleWithCenterCoordinate:cuestaCoordinate radius:radius];
    
    [self.mapView addOverlay: outerCircle];
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
        
        [[LocationManager sharedInstance] startMonitoringForRegion:self.region];
    }
}

#pragma mark - UIGestureRecognizerDelegate

-(void)handleLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        
        [[LocationManager sharedInstance] stopMonitoringForRegion:self.region];
        
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
    
    [[LocationManager sharedInstance] stopUpdatingLocation];
    [[LocationManager sharedInstance] stopMonitoringForRegion:self.region];
    [[LocationManager sharedInstance] stopMonitoringSignificantLocationChanges];
    
    exit(1);
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
