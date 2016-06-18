//
//  ACMapController.m
//  Location
//
//  Created by Oleksandr Chyzh on 1/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACMapController.h"
#import "LocationManager.h"
#import "ACFavoriteViewController.h"

@import GoogleMaps;

typedef enum {
    TransportTypeWalk,
    TransportTypeCar,
    TransportTypeCityBus,
    TransportTypeSpeedTrain
} TransportType;

@interface ACMapController () <CLLocationManagerDelegate, GMSMapViewDelegate,UIApplicationDelegate>

@property (strong, nonatomic) CLCircularRegion *region;
@property (assign, nonatomic) BOOL flagEnterBgTask;
@property (assign, nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (assign, nonatomic) UIApplication *app;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSMarker *marker;
@property (strong, nonatomic) NSString *typeTransportTitle;

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender;
@end

@implementation ACMapController

static CLLocationDistance radius    = 700;
static NSUInteger metersToEnableCar = 3500;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = NO;
    self.navigationItem.title = self.typeTransportTitle;
    
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
    
    self.flagEnterBgTask = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.marker != nil && self.marker.snippet != nil) {
        
        [self drowMarkerWithCoordinate:self.marker.position];
    } else {
        
        self.marker = [[GMSMarker alloc] init];
    }
}

#pragma mark - private Methods

- (void)didEnterBackground {
    
    [[LocationManager sharedInstance] stopUpdatingLocation];
    
    [LocationManager sharedInstance].inBackground = YES;
    
    if (self.region) {
        [[LocationManager sharedInstance] startMonitoringSignificantLocationChanges];
    }
}

- (void)willEnterForeground {
    
    [self checkNotification];
    
    [LocationManager sharedInstance].inBackground = NO;
    
    [[LocationManager sharedInstance] stopMonitoringSignificantLocationChanges];
    
    [[LocationManager sharedInstance] startUpdatingLocation];
}

- (void)drowMarkerWithCoordinate:(CLLocationCoordinate2D)coordinate {
    
    [self.mapView clear];
    
    if (self.region) {
        [[LocationManager sharedInstance] stopMonitoringForRegion:self.region];
        self.flagEnterBgTask = YES;
        
        [self.app endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
        [self.timer invalidate];
    }
    
    GMSGeocoder *geocoder = [[GMSGeocoder alloc] init];
    [geocoder reverseGeocodeCoordinate:coordinate completionHandler:^(GMSReverseGeocodeResponse *response, NSError *error) {
        
        GMSAddress *address = [response firstResult];
        
        self.marker.position = coordinate;
        self.marker.title = [NSString stringWithFormat:@"%.f m.",[self distanceToPoint: self.marker]];
        self.marker.snippet = address.thoroughfare;
        self.marker.icon = [GMSMarker markerImageWithColor:[UIColor blackColor]];
        self.marker.map = self.mapView;
    }];
    
    GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
    geoFenceCircle.radius = radius;
    geoFenceCircle.position = coordinate;
    geoFenceCircle.fillColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.4];
    geoFenceCircle.strokeWidth = 2;
    geoFenceCircle.strokeColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.2];
    geoFenceCircle.map = self.mapView;
    
    self.region = [[CLCircularRegion alloc] initWithCenter:geoFenceCircle.position
                                                    radius:radius
                                                identifier:@"theRegion"];
    
    [[LocationManager sharedInstance] startMonitoringForRegion:self.region];
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
    
    [self drowMarkerWithCoordinate:coordinate];
}

- (void)youInRegionNotification {
    
    //[self disableLocation];
    
    [self.timer invalidate];
    [self.app endBackgroundTask:self.bgTask];
    self.bgTask = UIBackgroundTaskInvalid;
    
    NSLog(@"Remuve Timer and BgTask");
    
    NSLog(@"!!!!!!!!youInRegion!!!!!!!");
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.fireDate = [NSDate date];
    notification.timeZone = [NSTimeZone defaultTimeZone];
    notification.soundName = @"alarm.caf";
    notification.alertAction = @"Let's do this";
    
    CLLocationDistance meters = [self distanceToPoint: self.marker];
    
    notification.alertBody = [NSString stringWithFormat:@"didEnterRegion:distans to Pin %.0f", meters];
    
    [[UIApplication sharedApplication]scheduleLocalNotification:notification];
}

- (double)distanceToPoint:(GMSMarker *)finishPoint {
    
    CLLocation *endPoint = [[CLLocation alloc] initWithLatitude:finishPoint.position.latitude
                                                      longitude:finishPoint.position.longitude];
    
    CLLocationDistance meters = [endPoint distanceFromLocation:[LocationManager sharedInstance].locationManager.location];
    
    return meters;
}

- (void)locationChanges {
    
    if (self.flagEnterBgTask && ![self.region containsCoordinate:[LocationManager sharedInstance].curentLocation.coordinate]) {
        
        CLLocationDistance meters = [self distanceToPoint: self.marker];
        
        NSLog(@"meters: %f", meters);
        
        if (meters < metersToEnableCar && meters > 0) {
            
            [self createBgTaskWithTimerSecond:20];
        }
    }
}

- (void)createBgTaskWithTimerSecond:(NSUInteger)timerSeconds {
    
    NSLog(@"CREATE BGTASK!");
    
    self.app = [UIApplication sharedApplication];
    
    self.bgTask = [self.app beginBackgroundTaskWithName:@"MyTask" expirationHandler:^{
        
        NSLog(@"ending background task");
        [self.app endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];
    
    self.flagEnterBgTask = NO;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:timerSeconds
                                                  target:self
                                                selector:@selector(updateCurrentLocation)
                                                userInfo:nil
                                                 repeats:YES];
    
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}

- (void)disableLocation {
    
    [[LocationManager sharedInstance] stopMonitoringSignificantLocationChanges];
    [[LocationManager sharedInstance] stopUpdatingLocation];
    [[LocationManager sharedInstance] stopMonitoringForRegion:self.region];
}

#pragma mark - Action methods

- (void)updateCurrentLocation {
    
    [[LocationManager sharedInstance] startUpdatingLocation];
    
    NSLog(@"Timer selector FIRE NOW");
}

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender {
    
    [self disableLocation];
    
    exit(1);
}

#pragma mark - LocalNotification

- (void)checkNotification {
    
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(currentUserNotificationSettings)]) {
        
        UIUserNotificationSettings *grantedSettings = [[UIApplication sharedApplication] currentUserNotificationSettings];
        
        if (grantedSettings.types == UIUserNotificationTypeNone) {
            
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Notification Services Disable!"
                                                                           message:@"We can't send you alert, when you reach your destination. Please change your Notification settings. Settings > myLocation > Notification > Always"
                                                                    preferredStyle:(UIAlertControllerStyleAlert)];
            
            UIAlertAction* noButton = [UIAlertAction
                                       actionWithTitle:@"Exit"
                                       style:UIAlertActionStyleDefault
                                       handler:^(UIAlertAction * action)
                                       {
                                           [self disableLocation];
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
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    ACFavoriteViewController *vc = segue.destinationViewController;
    vc.marker = self.marker;
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
