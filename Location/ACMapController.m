//
//  ACMapController.m
//  Location
//
//  Created by Oleksandr Chyzh on 1/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACMapController.h"
#import "LocationManager.h"

@import GoogleMaps;

typedef enum {
    TransportTypeWalk,
    TransportTypeCar,
    TransportTypeCityBus,
    TransportTypeSpeedTrain
} TransportType;

@interface ACMapController () <CLLocationManagerDelegate, GMSMapViewDelegate>

@property (strong, nonatomic) CLCircularRegion *region;
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;
@property (assign, nonatomic) BOOL flagEnter;
@property (assign, nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (assign, nonatomic) UIApplication *app;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSMarker *marker;

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
    
    [[LocationManager sharedInstance] startUpdatingLocation];
    
    GMSCameraPosition *camera =
    [GMSCameraPosition cameraWithLatitude:[LocationManager sharedInstance].locationManager.location.coordinate.latitude
                                longitude:[LocationManager sharedInstance].locationManager.location.coordinate.longitude
                                     zoom:15];
    
    self.mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
    self.mapView.myLocationEnabled = YES;
    self.view = self.mapView;
    self.mapView.delegate = self;

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
    
    radius = [self getRadius];
    
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

- (NSUInteger)getRadius {
    
    switch (self.segmentIndex) {
        case 0:  return radiusForWalk;
        case 1:  return radiusForCar;
        case 2:  return radiusForCityBus;
        case 3:  return radiusForSpeedTrain;
            
        default: break;
    }
    return 500;
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
    
    [mapView clear];
    
    if (self.region) {
        [[LocationManager sharedInstance] stopMonitoringForRegion:self.region];
    }
    
    self.marker = [[GMSMarker alloc] init];
    self.marker.position = coordinate;
    self.marker.title = @"Current Location";
    self.marker.icon = [GMSMarker markerImageWithColor:[UIColor blackColor]];
    self.marker.map = mapView;
    
    GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
    geoFenceCircle.radius = radius;
    geoFenceCircle.position = coordinate;
    geoFenceCircle.fillColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.4];
    geoFenceCircle.strokeWidth = 2;
    geoFenceCircle.strokeColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    geoFenceCircle.map = mapView;
    
    self.region = [[CLCircularRegion alloc] initWithCenter:geoFenceCircle.position
                                                    radius:radius
                                                identifier:@"theRegion"];
    
    [[LocationManager sharedInstance] startMonitoringForRegion:self.region];
}

- (void)youInRegionNotification {
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.fireDate = [NSDate date];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    
    notification.soundName = UILocalNotificationDefaultSoundName;
    notification.alertAction = @"Let's do this";
    
    CLLocationDistance meters = [self distanceToPoint: self.marker];
    
    notification.alertBody = [NSString stringWithFormat:@"didEnterRegion:distans to Pin %.0f", meters];
    
    [[UIApplication sharedApplication]scheduleLocalNotification:notification];
}

- (double)distanceToPoint:(GMSMarker *)finishPoint {
    
    CLLocation *endPoint = [[CLLocation alloc] initWithLatitude:finishPoint.position.latitude longitude:finishPoint.position.longitude];
    
    CLLocationDistance meters = [endPoint distanceFromLocation:[LocationManager sharedInstance].locationManager.location];
    
    return meters;
}

- (void)locationChanges {
    
    CLLocationDistance meters = [self distanceToPoint: self.marker];
    
    NSLog(@"%f", meters);
    
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

#pragma mark - Action

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender {
    
    [[LocationManager sharedInstance] stopUpdatingLocation];
    [[LocationManager sharedInstance] stopMonitoringForRegion:self.region];
    [[LocationManager sharedInstance] stopMonitoringSignificantLocationChanges];
    
    exit(1);
}

//#pragma mark - Segue
//
//- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
//
//    [self dismissViewControllerAnimated:YES completion:nil];
//}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
