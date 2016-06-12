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
@property (strong, nonatomic) UILongPressGestureRecognizer *longPressGesture;
@property (assign, nonatomic) BOOL flagEnter;
@property (assign, nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (assign, nonatomic) UIApplication *app;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSMarker *marker;
@property (strong, nonatomic) NSString *typeTransportTitle;

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender;
@end

@implementation ACMapController

static CLLocationDistance radius;

static CLLocationDistance radiusForWalk = 250;
static CLLocationDistance radiusForCar  = 700;
static CLLocationDistance radiusForCityBus = 700;
static CLLocationDistance radiusForSpeedTrain = 700;

static NSUInteger metersToEnableWalr = 600;
static NSUInteger metersToEnableCar  = 3500;
static NSUInteger metersToEnableCityBus = 2500;
static NSUInteger metersToEnableSpeedTrain = 3500;



- (void)viewDidLoad {
    [super viewDidLoad];
    
    radius = [self getRadius];
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
    
    self.flagEnter = YES;
    self.app = [UIApplication sharedApplication];
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
    
    [[LocationManager sharedInstance] startMonitoringSignificantLocationChanges];
}

- (void)willEnterForeground {
    
    [self checkNotification];
    
    [[LocationManager sharedInstance] stopMonitoringSignificantLocationChanges];
    
    [[LocationManager sharedInstance] startUpdatingLocation];
}

- (NSUInteger)getRadius {
    
    switch (self.segmentIndex) {
        case 0: self.typeTransportTitle = @"Walk"; return radiusForWalk;
        case 1: self.typeTransportTitle = @"Car"; return radiusForCar;
        case 2: self.typeTransportTitle = @"City Bus"; return radiusForCityBus;
        case 3: self.typeTransportTitle = @"Speed Train"; return radiusForSpeedTrain;
            
        default: break;
    }
    return 500;
}

- (void)drowMarkerWithCoordinate:(CLLocationCoordinate2D)coordinate {
    
    [self.mapView clear];
    
    if (self.region) {
        [[LocationManager sharedInstance] stopMonitoringForRegion:self.region];
    }
    
    GMSGeocoder *geocoder = [[GMSGeocoder alloc] init];
    [geocoder reverseGeocodeCoordinate:coordinate completionHandler:^(GMSReverseGeocodeResponse *response, NSError *error) {
        
        GMSAddress *address = [response firstResult];
        
        // self.marker = [[GMSMarker alloc] init];
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
    
    self.bgTask = UIBackgroundTaskInvalid;
   
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
        
        if (meters < metersToEnableWalr && meters > 0 && self.segmentIndex == TransportTypeWalk) {
            
            [self createBgTaskWithTimerSecond:30];
        }
        
        if (meters < metersToEnableCar && meters > 0 && self.segmentIndex == TransportTypeCar) {
            
            [self createBgTaskWithTimerSecond:20];
        }
        
        if (meters < metersToEnableCityBus && meters > 0 && self.segmentIndex == TransportTypeCityBus) {

            [self createBgTaskWithTimerSecond:20];
        }
        
        if (meters < metersToEnableSpeedTrain && meters > 0 && self.segmentIndex == TransportTypeSpeedTrain) {
            
            [self createBgTaskWithTimerSecond:30];
        }
    }
}

- (void)createBgTaskWithTimerSecond:(NSUInteger)timer {
    
    self.flagEnter = NO;
    
    
    self.bgTask = [self.app beginBackgroundTaskWithExpirationHandler:^{
        NSLog(@"!!UIBackgroundTaskInvalid!!");
        self.bgTask = UIBackgroundTaskInvalid;
    }];
    
   // [self enableLocationWithTimerSecond:timer];
}

- (void)enableLocationWithTimerSecond:(NSUInteger)timer {
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void){
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timer * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [[LocationManager sharedInstance] startUpdatingLocation];
              NSLog(@"beginBG called1");
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [[LocationManager sharedInstance] stopUpdatingLocation];
               // [[LocationManager sharedInstance] startMonitoringSignificantLocationChanges];
                   NSLog(@"beginBG called2");
                
                if (self.bgTask != UIBackgroundTaskInvalid) {
                   // [self enableLocationWithTimerSecond:timer];
                } else {
                    [self.app endBackgroundTask:self.bgTask];
                }
            });
        });
    });
    
       NSLog(@"beginBG called3");
}

#pragma mark - Action

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender {
    
    [[LocationManager sharedInstance] stopUpdatingLocation];
    [[LocationManager sharedInstance] stopMonitoringForRegion:self.region];
    [[LocationManager sharedInstance] stopMonitoringSignificantLocationChanges];
    
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
                                           [[LocationManager sharedInstance] stopUpdatingLocation];
                                           [[LocationManager sharedInstance] stopMonitoringForRegion:self.region];
                                           [[LocationManager sharedInstance] stopMonitoringSignificantLocationChanges];
                                           
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
