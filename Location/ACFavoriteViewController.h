//
//  ACFavoriteViewController.h
//  Location
//
//  Created by Oleksandr Chyzh on 9/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMaps/GMSMarker.h>
#import <CoreData/CoreData.h>

@interface ACFavoriteViewController : UIViewController <NSFetchedResultsControllerDelegate>
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) GMSMarker *marker;

@end
