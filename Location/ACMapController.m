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
#import "ACMainColor.h"
#import "MDDirectionService.h"

@import GoogleMaps;

typedef enum {
    TransportTypeCityBus,
    TransportTypeTrain
} TransportType;

@interface ACMapController () <GMSMapViewDelegate, UIApplicationDelegate>

@property (strong, nonatomic) CLCircularRegion *region;
@property (assign, nonatomic) BOOL flagEnterBgTask;
@property (assign, nonatomic) UIBackgroundTaskIdentifier bgTask;
@property (assign, nonatomic) UIApplication *app;
@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) GMSMapView *mapView;
@property (strong, nonatomic) GMSMarker *marker;

@property (strong, nonatomic) NSString *typeTransportTitle;
@property (weak, nonatomic) IBOutlet UILabel *durationAndDistanceLabel;

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender;

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
    
    [self setupDurationDistanceLabel];
    
    radius = [self getRadius];
    
    [[LocationManager sharedInstance] startUpdatingLocation];
    
    GMSCameraPosition *camera =
    [GMSCameraPosition cameraWithLatitude:[LocationManager sharedInstance].locationManager.location.coordinate.latitude
                                longitude:[LocationManager sharedInstance].locationManager.location.coordinate.longitude
                                     zoom:cameraZoom];
    
    self.mapView = [GMSMapView mapWithFrame:self.view.frame camera:camera];
    self.mapView.myLocationEnabled = YES;
    self.mapView.settings.myLocationButton = YES;
    self.mapView.trafficEnabled = YES;
    self.mapView.buildingsEnabled = YES;
    self.mapView.settings.compassButton = YES;
    
    [self.view addSubview:self.mapView];
    [self.view bringSubviewToFront:self.durationAndDistanceLabel];
    
    self.mapView.delegate = self;
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter addObserver:self
                           selector:@selector(didEnterBackground)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(willEnterForeground)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(youInRegionNotification)
                               name:invokeLocalNotification
                             object:nil];
    
    [notificationCenter addObserver:self
                           selector:@selector(locationChanges)
                               name:locationChangesNotification
                             object:nil];
    
    self.flagEnterBgTask = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.marker != nil && self.marker.snippet != nil) {
        
        [self drawMarkerWithCoordinate:self.marker.position];
        
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
        exit(2);
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
        case 1: self.typeTransportTitle = @"Train";    self.navigationItem.title = self.typeTransportTitle; return radiusForTrain;
        default: break;
    }
    return 1000;
}

- (void)drawMarkerWithCoordinate:(CLLocationCoordinate2D)coordinate {
    
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
        self.marker.map  = self.mapView;
    }];
    
    GMSCircle *geoFenceCircle = [[GMSCircle alloc] init];
    geoFenceCircle.radius   = radius;
    geoFenceCircle.position = coordinate;
    geoFenceCircle.fillColor   = [UIColor colorWithRed:0.55 green:0.76 blue:0.29 alpha:0.5];
    geoFenceCircle.strokeWidth = 2;
    geoFenceCircle.strokeColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:0.65];
    geoFenceCircle.map = self.mapView;
    
    self.region = [[CLCircularRegion alloc] initWithCenter:geoFenceCircle.position
                                                    radius:radius
                                                identifier:@"theRegion"];
    
    [[LocationManager sharedInstance] startMonitoringForRegion:self.region];
}


- (void)getRouteFromCurrentLocationOnMapView:(GMSMapView *)mapView toCoordinate:(CLLocationCoordinate2D)coordinate {
    
    CLLocationCoordinate2D currentPosition = mapView.myLocation.coordinate;
    
    GMSMarker *marker = [GMSMarker markerWithPosition:coordinate];
    marker.map = mapView;
    
    GMSMarker *markerMyLocation = [GMSMarker markerWithPosition:currentPosition];
    
    NSArray *waypoints = [NSArray arrayWithObjects:markerMyLocation, marker, nil];
    
    NSString *positionString = [NSString stringWithFormat:@"%f,%f", coordinate.latitude, coordinate.longitude];
    
    NSString *myPositionString = [NSString stringWithFormat:@"%f,%f", currentPosition.latitude, currentPosition.longitude];
    
    NSArray *waypointStrings = [NSArray arrayWithObjects:myPositionString, positionString, nil];
    
    if ([waypoints count] > 1 ) {
        
        NSString *sensor = @"false";
        NSArray *parameters = [NSArray arrayWithObjects:sensor, waypointStrings, nil];
        
        NSArray *keys = [NSArray arrayWithObjects:@"sensor", @"waypoints", nil];
        NSDictionary *query = [NSDictionary dictionaryWithObjects:parameters
                                                          forKeys:keys];
        
        MDDirectionService *mds = [[MDDirectionService alloc] init];
        
        SEL selector = @selector(addDirections:);
        
        [mds setDirectionsQuery:query
                   withSelector:selector
                   withDelegate:self];
    }
}

- (void)updateCameraPosition {
    
    if (self.region) {
        
        double delta = 70;
        
        CLLocationCoordinate2D marketLocation = self.marker.position;
        CLLocationCoordinate2D currentLocation = [LocationManager sharedInstance].locationManager.location.coordinate;
        
        GMSCoordinateBounds *bounds = [[GMSCoordinateBounds alloc] initWithCoordinate:marketLocation coordinate:currentLocation];
        
        UIEdgeInsets insert = UIEdgeInsetsMake(150, 30, delta, delta);
        
        GMSCameraPosition *camera = [self.mapView cameraForBounds:bounds insets:insert];
        self.mapView.camera = camera;
        
    } else {
        
        CLLocationCoordinate2D coordinates = [LocationManager sharedInstance].locationManager.location.coordinate;
        
        GMSCameraUpdate *updatedCamera = [GMSCameraUpdate setTarget:coordinates zoom:cameraZoom];
        
        [self.mapView animateWithCameraUpdate:updatedCamera];
    }
}

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

- (void)disableLocation {
    
    [[LocationManager sharedInstance] stopMonitoringSignificantLocationChanges];
    [[LocationManager sharedInstance] stopUpdatingLocation];
    [[LocationManager sharedInstance] stopMonitoringForRegion:self.region];
    self.region = nil;
}

//- (void)getTravelDuration {
//
//    NSString *requestString = @"https://maps.googleapis.com/maps/api/directions/json?origin=sydney,au&destination=perth,au&waypoints=via:-37.81223%2C144.96254%7Cvia:-34.92788%2C138.60008&key=YOUR_API_KEY";
//}

- (double)distanceToPoint:(GMSMarker *)finishPoint {
    
    CLLocation *endPoint = [[CLLocation alloc] initWithLatitude:finishPoint.position.latitude
                                                      longitude:finishPoint.position.longitude];
    
    CLLocationDistance meters = [endPoint distanceFromLocation:[LocationManager sharedInstance].locationManager.location];
    
    return meters;
}

- (void)addDirections:(NSDictionary *)json {
    
    NSDictionary *routes = [[json objectForKey:@"routes"] firstObject];
    
    NSDictionary *legs = [[routes objectForKey:@"legs"] firstObject];
    
    if (legs) {
        
        NSDictionary *distance = [legs objectForKey:@"distance"];
        NSString *distanceText = [distance objectForKey:@"text"];
        
        NSDictionary *duration = [legs objectForKey:@"duration"];
        NSString *durationText = [duration objectForKey:@"text"];
        
        [self formateDurationDistanceLabelWithDuration:distanceText distance:durationText];
    }
    
    NSDictionary *route = [routes objectForKey:@"overview_polyline"];
    NSString *overview_route = [route objectForKey:@"points"];
    
    GMSPath *path = [GMSPath pathFromEncodedPath:overview_route];
    
    GMSPolyline *polyline = [GMSPolyline polylineWithPath:path];
    polyline.map = self.mapView;
}

- (void)formateDurationDistanceLabelWithDuration:(NSString *)duration distance:(NSString *)distance {
    
    self.durationAndDistanceLabel.text = [NSString stringWithFormat:@"%@, %@", duration, distance];
    
    if (self.durationAndDistanceLabel.text.length > 3) {
        
        [self showDurationAndDistanceLabelAnimated:YES];
        
    } else {
        
        self.durationAndDistanceLabel.alpha = 0.0f;
    }
    
}

- (void)showDurationAndDistanceLabelAnimated:(BOOL)isShowing {
    
    [UIView animateWithDuration:0.5
                          delay:0
                        options:UIViewAnimationOptionCurveLinear
                     animations:^{
                         
                         if (isShowing == YES) {
                             
                             self.durationAndDistanceLabel.alpha = 1.0f;
                             
                         } else {
                             
                             self.durationAndDistanceLabel.alpha = 0.0f;
                         }
                         
                     } completion:nil];
}

- (void)setupDurationDistanceLabel {
    
    self.durationAndDistanceLabel.alpha = 0.0f;
    
    self.durationAndDistanceLabel.layer.cornerRadius = 10;
    self.durationAndDistanceLabel.layer.borderWidth  = 1.0f;
    self.durationAndDistanceLabel.layer.borderColor  = [ACMainColor buttonColor].CGColor;
    self.durationAndDistanceLabel.textColor = [ACMainColor buttonColor];
    self.durationAndDistanceLabel.backgroundColor = [ACMainColor segmentControlColor];
    
}

#pragma mark - GMSMapViewDelegate

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate {
    
    [self drawMarkerWithCoordinate:coordinate];
    
    [self getRouteFromCurrentLocationOnMapView:mapView toCoordinate:coordinate];
}

#pragma mark - invokeLocalNotification

- (void)youInRegionNotification {
    
    [LocationManager sharedInstance].startMonSignifOn = NO;
    
    [self.timer invalidate];
    [self.app endBackgroundTask:self.bgTask];
    self.bgTask = UIBackgroundTaskInvalid;
    
    NSLog(@"Remove Timer and BgTask");
    
    NSLog(@"!!!!!!!!youInRegion!!!!!!!");
    
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    
    notification.fireDate    = [NSDate date];
    notification.timeZone    = [NSTimeZone defaultTimeZone];
    notification.soundName   = @"alarm.caf";
    notification.alertAction = @"Let's do this";
    notification.applicationIconBadgeNumber = 1;
    
    CLLocationDistance meters = [self distanceToPoint: self.marker];
    
    notification.alertBody = [NSString stringWithFormat:@"didEnterRegion:distans to Pin %.0f", meters];
    
    [[UIApplication sharedApplication]scheduleLocalNotification:notification];
    
    [self disableLocation];
}

#pragma mark - locationChangesNotification

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

#pragma mark - Action methods

- (IBAction)actionExitBarButton:(UIBarButtonItem *)sender {
    
    [self.mapView clear];
    
    [self disableLocation];
    
    [self showDurationAndDistanceLabelAnimated:NO];
}

- (void)showCurrentLocation {
    
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
    }
}

#pragma mark - Deallocation

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
