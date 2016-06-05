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

typedef enum {
    TransportTypeWalk,
    TransportTypeCar,
    TransportTypeCityBus,
    TransportTypeSpeedTrain
} TransportType;

@interface ACMapController () <CLLocationManagerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate>

@property (strong, nonatomic) CLCircularRegion *region;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;
@property (assign, nonatomic) BOOL flagEnter;
@property (assign, nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (assign, nonatomic) UIApplication *app;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender;

@end

@implementation ACMapController

static CLLocationDistance radiusForWalk = 250;
static CLLocationDistance radiusForCar  = 600;
static CLLocationDistance radiusForCityBus = 600;
static CLLocationDistance radiusForSpeedTrain = 600;

static CLLocationDistance radius;

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
    
    [[NSNotificationCenter defaultCenter]addObserver:self
                                            selector:@selector(locationChanges)
                                                name:locationChangesNotification
                                              object:nil];
    
    self.flagEnter = YES;
    
    radius = [self gerRadius];
    
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

- (NSUInteger)gerRadius {
    
    switch (self.segmentIndex) {
        case 0:  return radiusForWalk;
        case 1:  return radiusForCar;
        case 2:  return radiusForCityBus;
        case 3:  return radiusForSpeedTrain;
            
        default: break;
    }
    return 500;
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
    
    notification.alertBody = [NSString stringWithFormat:@"didEnterRegion: distans to Pin %.0f", meters];
    
    [[UIApplication sharedApplication]scheduleLocalNotification:notification];
}

- (double)distanceToPoint:(MKPointAnnotation *)finishPoint {
    
    CLLocation *endPoint = [[CLLocation alloc] initWithLatitude:finishPoint.coordinate.latitude longitude:finishPoint.coordinate.longitude];
    
    CLLocationDistance meters = [endPoint distanceFromLocation:[LocationManager sharedInstance].currentLocation];
    
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

- (void)locationChanges {
    
    MKPointAnnotation *annotation = [self getAnnotationFromMapView:self.mapView];
    
    CLLocationDistance meters = [self distanceToPoint: annotation];
    
    if (self.flagEnter) {
        
        if (meters < 600 && self.segmentIndex == TransportTypeWalk) {

            [self createBgTaskWithTimerSecond:30];
        }
        
        if (meters < 3500 && self.segmentIndex == TransportTypeCar) {

            [self createBgTaskWithTimerSecond:20];
        }
        
        if (meters < 2500 && self.segmentIndex == TransportTypeCityBus) {

            [self createBgTaskWithTimerSecond:20];
        }
        
        if (meters < 3500 && self.segmentIndex == TransportTypeSpeedTrain) {
            
            [self createBgTaskWithTimerSecond:30];
            
        }
    }
}

- (void)createBgTaskWithTimerSecond:(NSUInteger)second {
    
    self.flagEnter = NO;
    
    self.app = [UIApplication sharedApplication];
    self.bgTask = [self.app beginBackgroundTaskWithExpirationHandler:^{
        
        self.bgTask = UIBackgroundTaskInvalid;
    }];
    
    [self enableLocationWithTimerSecond:second];
}

- (void)enableLocationWithTimerSecond:(NSUInteger)timer {
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(void){
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timer * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [[LocationManager sharedInstance] startUpdatingLocation];
            //  NSLog(@"beginBG called1");
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [[LocationManager sharedInstance] stopUpdatingLocation];
                [[LocationManager sharedInstance] startMonitoringSignificantLocationChanges];
                //   NSLog(@"beginBG called2");
                
                if (self.bgTask != UIBackgroundTaskInvalid) {
                    [self enableLocationWithTimerSecond:timer];
                } else {
                    [self.app endBackgroundTask:self.bgTask];
                }
            });
        });
    });
    
    //   NSLog(@"beginBG called3");
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
        
        self.bgTask = UIBackgroundTaskInvalid;
        
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
