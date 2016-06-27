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
@property (weak, nonatomic) IBOutlet UILabel *transportInfoLable;
@property (weak, nonatomic) IBOutlet UILabel *addMarkerInfoLable;
@property (weak, nonatomic) IBOutlet UILabel *cancelInfoLable;

- (IBAction)actionShowInfo:(UIButton *)sender;
@end

@implementation ACSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ACMainColor *color = [[ACMainColor alloc] init];
    
    [LocationManager sharedInstance];
    [[LocationManager sharedInstance] stopUpdatingLocation];
    
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.navigationBar.backgroundColor = [color mainColor];
    self.navigationController.navigationBar.tintColor       = [color buttonColor];
    
    [self createButtonApplyWithColorType:color];
    
    self.typeTransportSegmentControl.tintColor       = [color buttonColor];
    self.typeTransportSegmentControl.backgroundColor = [color segmentControlColor];
    
    self.view.backgroundColor = [color viewBackColor];
    
    self.betaLable.text = @"Beta version";
    
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

- (void)settingWithLable:(UILabel *)lable text:(NSString *)text numberLines:(NSUInteger)numberLines imageNamed:(NSString *)imageNamed {
    
    if (![imageNamed isEqualToString:@""]) {
        
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    
    attachment.image = [UIImage imageNamed:imageNamed];
    
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    NSMutableAttributedString *myString= [[NSMutableAttributedString alloc] initWithString:text];
    
    [myString insertAttributedString:attachmentString atIndex:0];
    
    lable.attributedText = myString;
    
    } else {
        lable.text = text;
    }

    lable.font = [UIFont fontWithName:@"Helvetica" size:13];
    lable.numberOfLines = numberLines;
    lable.alpha = 0;
    lable.textAlignment   = NSTextAlignmentLeft;
    
    [UIView animateWithDuration:2
                          delay:0
                        options:UIViewAnimationOptionCurveEaseIn
                     animations:^{
                         lable.alpha = 1;
                     }
                     completion:nil];
}

#pragma mark - Action

- (IBAction)transportSettingControl:(UISegmentedControl *)sender {
    
    switch (sender.selectedSegmentIndex) {
            
        case TransportTypeCityBus: self.segmentIndex = 0; break;
        case TransportTypeTrain:   self.segmentIndex = 1; break;
            
        default: break;
    }
}

- (IBAction)actionShowInfo:(UIButton *)sender {
    
    NSString *transportInfoText = @"Select ""Train"", If speed biggest than 70km/h";
    NSString *addMarkerInfoText = @" Select for add or load favorite Point";
    NSString *cancelInfoText    = @" Select for removing Map Point if you don't need anymore track region";
    
    [self settingWithLable:self.transportInfoLable text:transportInfoText numberLines:1 imageNamed:@""];
    [self settingWithLable:self.addMarkerInfoLable text:addMarkerInfoText numberLines:1 imageNamed:@"Add Property-50"];
    [self settingWithLable:self.cancelInfoLable    text:cancelInfoText    numberLines:2 imageNamed:@"Geocaching-50"];
}

#pragma mark - Segue

- (void)showMapController {
    
    [self performSegueWithIdentifier:@"ACMapControllerSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    
    ACMapController *vc = segue.destinationViewController;
    
    vc.segmentIndex = self.segmentIndex;
}




@end
