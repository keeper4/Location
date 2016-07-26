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

@interface ACSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (assign, nonatomic) NSUInteger segmentIndex;
@property (strong, nonatomic) NSArray *infoTextArray;
@property (strong, nonatomic) NSArray *infoImageArray;
@property (weak, nonatomic) IBOutlet UISegmentedControl *typeTransportSegmentControl;
@property (weak, nonatomic) IBOutlet UILabel *betaLable;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (IBAction)actionShowInfo:(UIButton *)sender;
@end

@implementation ACSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [LocationManager sharedInstance];
    [[LocationManager sharedInstance] stopUpdatingLocation];
    
//    ACMainColor *color = [[ACMainColor alloc] init];
    
    self.navigationController.navigationBar.hidden = YES;
    self.navigationController.navigationBar.backgroundColor = [ACMainColor mainColor];
    self.navigationController.navigationBar.tintColor       = [ACMainColor buttonColor];
    self.view.backgroundColor = [ACMainColor viewBackColor];
    
    [self createButtonApplyWithColorType];
    
    self.typeTransportSegmentControl.tintColor       = [ACMainColor buttonColor];
    self.typeTransportSegmentControl.backgroundColor = [ACMainColor segmentControlColor];
    
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    
    self.betaLable.text = [@"Beta version: " stringByAppendingString:version];
    
    [self tableViewSettings];
}

#pragma mark - Private method

- (void)createButtonApplyWithColorType {
    
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
    applyButton.layer.borderColor  = [ACMainColor buttonColor].CGColor;
    [applyButton setTitleColor:[ACMainColor buttonColor] forState:UIControlStateNormal];
    applyButton.backgroundColor = [ACMainColor segmentControlColor];
    
    [self.view addSubview:applyButton];
}

- (void)tableViewSettings {
    
    NSString *transportInfoText = @"Select ""Train"", If speed more than 70 km/h";
    NSString *addMarkerInfoText = @"Select for add or load favorite Point";
    NSString *cancelInfoText    = @"Select for removing Map Point if you don't need anymore track region";
    
    self.infoTextArray = @[transportInfoText, addMarkerInfoText, cancelInfoText];
    
    UIImage *transportInfoImage = [UIImage imageNamed:@"Switch On-48"];
    UIImage *addMarkerInfoImage = [UIImage imageNamed:@"Add List-50"];
    UIImage *cancelInfoImage    = [UIImage imageNamed:@"Geocaching-50"];
    
    self.infoImageArray = @[transportInfoImage, addMarkerInfoImage, cancelInfoImage];
    
    self.tableView.alpha = 0;
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.scrollEnabled = NO;
    self.tableView.allowsSelection = NO;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
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
    
    if (self.tableView.alpha == 0) {
        
        [UIView animateWithDuration:1.0f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.tableView.alpha = 1;
                         }
                         completion:nil];
    } else {
        
        [UIView animateWithDuration:1.0f
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
                             self.tableView.alpha = 0;
                         }
                         completion:nil];
    }
}

#pragma mark - Segue

- (void)showMapController {
    
    [self performSegueWithIdentifier:@"ACMapControllerSegue" sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(nullable id)sender {
    
    ACMapController *vc = segue.destinationViewController;
    
    vc.segmentIndex = self.segmentIndex;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return [self.infoTextArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    NSString *text = [self.infoTextArray objectAtIndex:indexPath.row];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = text;
    cell.textLabel.textAlignment = NSTextAlignmentLeft;
    cell.textLabel.numberOfLines = 0;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:13.0]];
    cell.backgroundColor = [UIColor clearColor];
    
    UIImage *image = [self.infoImageArray objectAtIndex:indexPath.row];
    
    cell.imageView.image = image;
    
    return cell;
}



@end
