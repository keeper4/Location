//
//  ACSettingsViewController.m
//  Location
//
//  Created by Oleksandr Chyzh on 4/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACMapController.h"
#import "ACSettingsViewController.h"

@interface ACSettingsViewController ()

@property (assign, nonatomic) NSUInteger segmentIndex;
@end

@implementation ACSettingsViewController

- (IBAction)transportSettingControl:(UISegmentedControl *)sender {
    
    switch (sender.selectedSegmentIndex) {
        case TransportTypeWalk:       self.segmentIndex = 0; break;
        case TransportTypeCar:        self.segmentIndex = 1; break;
        case TransportTypeCityBus:    self.segmentIndex = 2; break;
        case TransportTypeSpeedTrain: self.segmentIndex = 3; break;

        default: break;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {

    ACMapController *vc = segue.destinationViewController;
    
    vc.segmentIndex = self.segmentIndex;
}

@end
