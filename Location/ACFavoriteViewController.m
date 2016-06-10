//
//  ACFavoriteViewController.m
//  Location
//
//  Created by Oleksandr Chyzh on 9/6/16.
//  Copyright © 2016 Oleksandr Chyzh. All rights reserved.
//

#import "ACFavoriteViewController.h"
#import "ACDataManager.h"
#import "ACMarker.h"

@interface ACFavoriteViewController () <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *namePointTextField;
@property (strong, nonatomic) NSMutableArray *favoriteMarkersArray;
@end

@implementation ACFavoriteViewController

@synthesize fetchedResultsController = _fetchedResultsController;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                target:self
                                                                                action:@selector(saveMarker)];
    
    self.navigationItem.rightBarButtonItem = saveButton;
    
   //  [NSFetchedResultsController deleteCacheWithName:nil];
    
}

#pragma mark - Action

- (void)saveMarker {
    
    if (self.marker != nil) {
        
        [[ACDataManager sharedManager] addMarker:self.marker namePointTextField:self.namePointTextField.text];
    }
    
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.fetchedResultsController.fetchedObjects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1
                                      reuseIdentifier:CellIdentifier];
    }
    
    ACMarker *marker = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = marker.name;
    cell.detailTextLabel.text = marker.title;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        [[[ACDataManager sharedManager] managedObjectContext]
         deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        [[ACDataManager sharedManager] saveContext];
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(nullable NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(nullable NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        default:
            break;
    }
}

#pragma mark - Table view data source

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription* description =
    [NSEntityDescription entityForName:@"ACMarker"
                inManagedObjectContext:[ACDataManager sharedManager].managedObjectContext];
    
    [fetchRequest setEntity:description];
    
    NSSortDescriptor* nameDescription =
    [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES];
    
    [fetchRequest setSortDescriptors:@[nameDescription]];
    
    NSFetchedResultsController *aFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:[ACDataManager sharedManager].managedObjectContext
                                          sectionNameKeyPath:nil
                                                   cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
    NSError *error = nil;
    if (![self.fetchedResultsController performFetch:&error]) {
        
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _fetchedResultsController;
}




@end