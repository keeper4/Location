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
@property (weak, nonatomic) IBOutlet UILabel *betaLable;
@end

@implementation ACSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.betaLable.text = @"Beta version";
    
    ACMainColor *color = [[ACMainColor alloc] init];
    
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.navigationBar.backgroundColor = [color mainColor];
    self.navigationController.navigationBar.tintColor       = [color buttonColor];
    
    [self createButtonApplyWithColorType:color];
    
    self.typeTransportSegmentControl.tintColor       = [color buttonColor];
    self.typeTransportSegmentControl.backgroundColor = [color segmentControlColor];
    
    self.view.backgroundColor = [color viewBackColor];
    
    [LocationManager sharedInstance];
    [[LocationManager sharedInstance] stopUpdatingLocation];
}

#pragma mark - Private method

- (void) createButtonApplyWithColorType:(ACMainColor *)color{
    
    UIButton *applyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [applyButton addTarget:self
                    action:@selector(showMapController)
          forControlEvents:UIControlEventTouchUpInside];
    [applyButton setTitle:@"Apply" forState:UIControlStateNormal];
    
    applyButton.titleLabel.font = [UIFont systemFontOfSize:13];
    
    CGFloat height = 90.0f;
    CGFloat widht  = 29.0f;
    CGFloat y      = (CGRectGetMidY(self.view.frame) - CGRectGetMaxY(self.typeTransportSegmentControl.frame))/2 + CGRectGetMaxY(self.typeTransportSegmentControl.frame) - widht/2;
    
    applyButton.frame = CGRectMake(CGRectGetMidX(self.view.frame) - height/2, y, height, widht);
    
    applyButton.opaque        = NO;
    applyButton.clipsToBounds = YES;
    applyButton.layer.cornerRadius = 10;
    applyButton.layer.borderWidth  = 1.0f;
    applyButton.layer.borderColor  = [color buttonColor].CGColor;
    [applyButton setTitleColor:[color buttonColor] forState:UIControlStateNormal];
    applyButton.backgroundColor = [color segmentControlColor];
    
    [self.view addSubview:applyButton];
}

#pragma mark - Action

- (IBAction)transportSettingControl:(UISegmentedControl *)sender {
    
    switch (sender.selectedSegmentIndex) {
            
        case TransportTypeCityBus: self.segmentIndex = 0; break;
        case TransportTypeTrain:   self.segmentIndex = 1; break;
            
        default: break;
    }
}

- (void)showMapController {
    
    [self performSegueWithIdentifier:@"ACMapControllerSegue" sender:nil];
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    
    ACMapController *vc = segue.destinationViewController;
    
    vc.segmentIndex = self.segmentIndex;
}



@end
