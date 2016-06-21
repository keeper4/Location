//
//  ACInfoViewController.m
//  Location
//
//  Created by Oleksandr Chyzh on 20/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACInfoViewController.h"

@interface ACInfoViewController ()

@property (weak, nonatomic) IBOutlet UILabel *infoLable;
@end

@implementation ACInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.infoLable.backgroundColor = [self buttonColor];
    self.infoLable.clipsToBounds = YES;
    self.infoLable.numberOfLines = 7;
    self.infoLable.layer.cornerRadius = 10;
    [self.infoLable setFont:[UIFont fontWithName:@"Helvetica" size:13.0f]];
    
    
    self.infoLable.text = [NSString stringWithFormat:@"Radius around Pin = %lu\n\nDistance to the point that runs\nthe exact location = %lu\n\nInterval including the exact\nlocations = %lu sec", (unsigned long)self.radius, (unsigned long)self.metersToEnableCar, (unsigned long)self.bgUpdatesLocationInterval];
    
}

- (UIColor *)buttonColor {
    
    UIColor *color = [UIColor colorWithRed:0.2 green:0.6 blue:0.2 alpha:0.8];
    
    return color;
}

@end
