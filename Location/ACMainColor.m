//
//  ACMainColor.m
//  Location
//
//  Created by Oleksandr Chyzh on 21/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACMainColor.h"

@implementation ACMainColor

- (UIColor *)mainColor {
    
    UIColor *color = [UIColor colorWithRed:0.55 green:0.76 blue:0.29 alpha:1.0];
    //[UIColor colorWithRed:0.63 green:0.85 blue:0.63 alpha:1.0];
    
    return color;
}

- (UIColor *)buttonColor {
    
    UIColor *color = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0];
    
    return color;
}

- (UIColor *)segmentControlColor {
    
    UIColor *color = [UIColor colorWithRed:0.45 green:0.45 blue:0.45 alpha:1.0];
    
    return color;
}

- (UIColor *)viewBackColor {
    
    UIColor *color = [UIColor colorWithRed:0.71 green:0.71 blue:0.71 alpha:1.0];
    
    return color;
}

@end
