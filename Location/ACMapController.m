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
#import "ACInfoViewController.h"
#import "ACMainColor.h"

@import GoogleMaps;

typedef enum {
    TransportTypeCityBus,
    TransportTypeTrain
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
- (IBAction)actionShowCurrentLocation:(UIBarButtonItem *)sender;
@end

@implementation ACMapController

static CGFloat cameraZoom = 14;

static CLLocationDistance radius;

static CLLocationDistance radiusForCityBus            = 700;
static NSUInteger metersToEnableForCityBus            = 7000;
static NSUInteger bgUpdatesLocationIntervalForCityBus = 30;

static CLLocationDistance radiusForTrain              = 1000;
static NSUInteger metersToEnableForTrain              = 15000;
static NSUInteger bgUpdatesLocationIntervalForTrain   = 20;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = NO;
    
    radius = [self getRadius];
    
    [[LocationManager sharedInstance] startUpdatingLocation];
    
    GMSCameraPosition *camera =
    [GMSCameraPosition cameraWithLatitude:[LocationManager sharedInstance].locationManager.location.coordinate.latitude
                                longitude:[LocationManager sharedInstance].locationManager.location.coordinate.longitude
                                     zoom:cameraZoom];
    
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
    
    if (self.region) {
        
        [LocationManager sharedInstance].inBackground = YES;
        [LocationManager sharedInstance].startMonSignifOn = YES;
        [[LocationManager sharedInstance] startMonitoringSignificantLocationChanges];
        
    } else {
        
        [self disableLocation];
    }
}

- (void)willEnterForeground {
    
    [self checkNotification];
    
    [LocationManager sharedInstance].inBackground = NO;
    
    [[LocationManager sharedInstance] stopMonitoringSignificantLocationChanges];
    
    [[LocationManager sharedInstance] startUpdatingLocation];
    
    [self updateCameraPosition];
}

- (NSUInteger)getRadius {
    
    switch (self.segmentIndex) {
        case 0: self.typeTransportTitle = @"City Bus"; self.navigationItem.title = self.typeTransportTitle; return radiusForCityBus;
        case 1: self.typeTransportTitle = @"Train";    self.navigationItem.title = self.typeTransportTitle;  return radiusForTrain;
        default: break;
    }
    return 1000;
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
        self.marker.icon = [GMSMarker markerImageWithColor:[UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0]];
        self.marker.map = self.mapView;
    }];
    
    GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
    geoFenceCircle.radius = radius;
    geoFenceCircle.position = coordinate;
    geoFenceCircle.fillColor = [UIColor colorWithRed:0.55 green:0.76 blue:0.29 alpha:0.5];
    geoFenceCircle.strokeWidth = 2;
    geoFenceCircle.strokeColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:0.65];
    geoFenceCircle.map = self.mapView;
    
    self.region = [[CLCircularRegion alloc] initWithCenter:geoFenceCircle.position
                                                    radius:radius
                                                identifier:@"theRegion"];
    
    [[LocationManager sharedInstance] startMonitoringForRegion:self.region];
}

- (void)updateCameraPosition {
    
    CLLocationCoordinate2D coordinates = [LocationManager sharedInstance].locationManager.location.coordinate;
    
    GMSCameraUpdate *updatedCamera = [GMSCameraUpdate setTarget:coordinates zoom:cameraZoom];
    
    [self.mapView animateWithCameraUpdate:updatedCamera];
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
    
    [self drowMarkerWithCoordinate:coordinate];
}

- (void)youInRegionNotification {
    
    [self.timer invalidate];
    [self.app endBackgroundTask:self.bgTask];
    self.bgTask = UIBackgroundTaskInvalid;
    
    [LocationManager sharedInstance].startMonSignifOn = NO;
    
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
    
    [self disableLocation];
}

- (double)distanceToPoint:(GMSMarker *)finishPoint {
    
    CLLocation *endPoint = [[CLLocation alloc] initWithLatitude:finishPoint.position.latitude
                                                      longitude:finishPoint.position.longitude];
    
    CLLocationDistance meters = [endPoint distanceFromLocation:[LocationManager sharedInstance].locationManager.location];
    
    return meters;
}

- (void)locationChanges {
    
    if (self.flagEnterBgTask && ![self.region containsCoordinate:[LocationManager sharedInstance].locationManager.location.coordinate]) {
        
        CLLocationDistance meters = [self distanceToPoint: self.marker];
        
        NSLog(@"meters: %f", meters);
        
        if (meters < metersToEnableForCityBus && meters > 0 && self.segmentIndex == TransportTypeCityBus) {
            
            [self createBgTaskWithTimerSecond:bgUpdatesLocationIntervalForCityBus];
        }
        if (meters < metersToEnableForTrain && meters > 0 && self.segmentIndex == TransportTypeTrain) {
            
            [self createBgTaskWithTimerSecond:bgUpdatesLocationIntervalForTrain];
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
    self.region = nil;
}

#pragma mark - Action methods

- (void)updateCurrentLocation {
    
    if (self.region) {
        [[LocationManager sharedInstance] startUpdatingLocation];
        NSLog(@"Timer selector FIRE NOW");
    } else {
        [self.timer invalidate];
        [self.app endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
        NSLog(@"Timer selector Remove task");
    }
}

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender {
    
    [self.mapView clear];
    
    [self disableLocation];
}

- (IBAction)actionShowCurrentLocation:(UIBarButtonItem *)sender {
    
    [self updateCameraPosition];
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
    
    if ([segue.identifier isEqualToString:@"favoriteSegue"]) {
        
        ACFavoriteViewController *favoriteVc = segue.destinationViewController;
        favoriteVc.marker = self.marker;
        
    } else if ([segue.identifier isEqualToString:@"infoSegue"]) {
        
        ACInfoViewController *infoVc = segue.destinationViewController;
        infoVc.radius = radius;
        infoVc.metersToEnableTranspotr = metersToEnableForCityBus;
        infoVc.bgUpdatesLocationInterval = bgUpdatesLocationIntervalForCityBus;
    }
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
