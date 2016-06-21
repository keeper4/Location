//
//  ACInfoViewController.m
//  Location
//
//  Created by Oleksandr Chyzh on 20/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACInfoViewController.h"
#import "ACMainColor.h"

@interface ACInfoViewController ()

@property (weak, nonatomic) IBOutlet UILabel *infoLable;
@end

@implementation ACInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ACMainColor *color = [[ACMainColor alloc] init];
    
    self.infoLable.backgroundColor = [color mainColor];
    self.infoLable.clipsToBounds = YES;
    self.infoLable.numberOfLines = 7;
    self.infoLable.layer.cornerRadius = 10;
    [self.infoLable setFont:[UIFont fontWithName:@"Helvetica" size:13.0f]];
    
    
    self.infoLable.text = [NSString stringWithFormat:@"Radius around Pin = %lu\n\nDistance to the point that runs\nthe exact location = %lu\n\nInterval including the exact\nlocations = %lu sec", (unsigned long)self.radius, (unsigned long)self.metersToEnableTranspotr, (unsigned long)self.bgUpdatesLocationInterval];
}

@end
