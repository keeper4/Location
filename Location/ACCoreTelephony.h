//
//  ACCoreTelephony.h
//  Location
//
//  Created by Oleksandr Chyzh on 27/5/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ACCoreTelephony : NSObject

- (void) startMonitoring;
- (void) stopMonitoring;
- (instancetype) init_true;

+ (instancetype) sharedInstance;

@end
