//
//  ACFavoriteViewController.h
//  Location
//
//  Created by Oleksandr Chyzh on 9/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import <UIKit/UIKit.h>
@class GMSMarker;

@interface ACFavoriteViewController : UIViewController

@property (strong, nonatomic) GMSMarker *marker;

@end
