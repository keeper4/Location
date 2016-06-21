//
//  ACSettingsViewController.m
//  Location
//
//  Created by Oleksandr Chyzh on 21/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACMapController.h"
#import "ACSettingsViewController.h"
#import "LocationManager.h"
#import "ACMainColor.h"

@interface ACSettingsViewController ()

@property (assign, nonatomic) NSUInteger segmentIndex;
@property (weak, nonatomic) IBOutlet UISegmentedControl *typeTransportSegmentControl;
@property (weak, nonatomic) IBOutlet UIButton *applyButton;
@end

@implementation ACSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ACMainColor *color = [[ACMainColor alloc] init];
    
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.backgroundColor = [color mainColor];
    self.navigationController.navigationBar.tintColor = [color buttonColor];
    self.applyButton.tintColor = [color buttonColor];
    self.typeTransportSegmentControl.tintColor = [color segmentControlColor];
    
    self.view.backgroundColor = [color viewBackColor];
    
    [LocationManager sharedInstance];
    [[LocationManager sharedInstance] stopUpdatingLocation];
}

- (IBAction)transportSettingControl:(UISegmentedControl *)sender {
    
    switch (sender.selectedSegmentIndex) {
            
        case TransportTypeCityBus: self.segmentIndex = 0; break;
        case TransportTypeTrain:   self.segmentIndex = 1; break;
            
        default: break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    
    ACMapController *vc = segue.destinationViewController;
    
    vc.segmentIndex = self.segmentIndex;
}

@end
