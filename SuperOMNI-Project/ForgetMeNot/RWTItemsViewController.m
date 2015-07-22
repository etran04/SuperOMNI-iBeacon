//
//  RWTItemsViewController.m
//  ForgetMeNot
//
//  Created by Chris Wagner on 1/28/14.
//  Edited by Eric Tran on 7/2/15.
//  Copyright (c) 2014 Ray Wenderlich Tutorial Team. All rights reserved.
//

#import "RWTItemsViewController.h"
#import "RWTAddItemViewController.h"
#import "RWTItem.h"
#import "RWTItemCell.h"
#import "SpeakersViewController.h"
#import "HKWControlHandler.h"
#import "HKWPlayerEventHandlerSingleton.h"
#import "HKWDeviceEventHandlerSingleton.h"
#import "math.h"

@import CoreLocation;
@import Foundation;

NSString * const kRWTStoredItemsKey = @"storedItems";

@interface RWTItemsViewController () <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *itemsTableView;
@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSArray *music;
@property int superOmniNdx;
@property int smartThingsNdx;

@end

@implementation RWTItemsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up location manager
    self.locationManager = [[CLLocationManager alloc] init];
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
        [self.locationManager requestAlwaysAuthorization];
    }
    self.locationManager.delegate = self;

    self.superOmniNdx = self.smartThingsNdx = -1;
    
    // Goes through list of internal speakers and assigns index number
    for (int i = 0; i < [[HKWControlHandler sharedInstance] getDeviceCount]; i++) {
        DeviceInfo * dInfo = [[HKWControlHandler sharedInstance] getDeviceInfoByIndex:i];
        NSLog(@"Device name is @%@", dInfo.deviceName);
        if ([dInfo.deviceName isEqual: @"SuperOmni"]) {
            NSLog(@"Assigned %d to superOmniNdx", i);
            self.superOmniNdx = i;
        }
        if ([dInfo.deviceName isEqual: @"SmartThings"]) {
            NSLog(@"Assigned %d to smartThingsNdx", i);
            self.smartThingsNdx = i;
        }
    }
    [[HKWControlHandler sharedInstance] setVolumeAll: 0];
    [self loadItems];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UINavigationController *navController = segue.destinationViewController;
    if ([segue.identifier isEqualToString:@"Add"]) {
        RWTAddItemViewController *addItemViewController = (RWTAddItemViewController *)navController.topViewController;
        // Callback function for when you add a new item to the list
        [addItemViewController setItemAddedCompletion:^(RWTItem *newItem) {
            [self.items addObject:newItem];
            [self.itemsTableView beginUpdates];
            NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:self.items.count-1 inSection:0];
            [self.itemsTableView insertRowsAtIndexPaths:@[newIndexPath]
                                       withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.itemsTableView endUpdates];
            [self startMonitoringItem:newItem]; // Added this line in order to start monitoring when an item is added to the list
            [self persistItems];
        }];
    }
    if ([segue.identifier isEqualToString:@"NowPlaying"]) {
        printf("Got into segue NowPlaying\n");
        // Callback function for checking to see reverseBtn is pressed
    }
}

/* Loads the information stored from the list */
- (void)loadItems {
    NSArray *storedItems = [[NSUserDefaults standardUserDefaults] arrayForKey:kRWTStoredItemsKey];
    self.items = [NSMutableArray array];
    
    if (storedItems) {
        for (NSData *itemData in storedItems) {
            RWTItem *item = [NSKeyedUnarchiver unarchiveObjectWithData:itemData];
            [self.items addObject:item];
            [self startMonitoringItem:item];
        }
    }
}

/* Persist takes all known items and persists them to NSUserDefaults so that user wont have to re-enter items each time app is launch (Stores the information) */
- (void)persistItems {
    NSMutableArray *itemsDataArray = [NSMutableArray array];
    for (RWTItem *item in self.items) {
        NSData *itemData = [NSKeyedArchiver archivedDataWithRootObject:item];
        [itemsDataArray addObject:itemData];
    }
    [[NSUserDefaults standardUserDefaults] setObject:itemsDataArray forKey:kRWTStoredItemsKey];
}

- (CLBeaconRegion *)beaconRegionWithItem:(RWTItem *)item {
    CLBeaconRegion *beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:item.uuid
                                                                           major:item.majorValue
                                                                           minor:item.minorValue
                                                                      identifier:item.name];
    return beaconRegion;
}

/* Starts ranging for iBeacons in that region for that list item. */
- (void)startMonitoringItem:(RWTItem *)item {
    CLBeaconRegion *beaconRegion = [self beaconRegionWithItem:item];
    [self.locationManager startMonitoringForRegion:beaconRegion];
    [self.locationManager startRangingBeaconsInRegion:beaconRegion];
}

/* Turns off the ranging for an item in the list. */
- (void)stopMonitoringItem:(RWTItem *)item {
    CLBeaconRegion *beaconRegion = [self beaconRegionWithItem:item];
    [self.locationManager stopMonitoringForRegion:beaconRegion];
    [self.locationManager stopRangingBeaconsInRegion:beaconRegion];
}

#pragma mark - UITableViewDataSource 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RWTItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Item" forIndexPath:indexPath];
    RWTItem *item = self.items[indexPath.row];
    cell.item = item;
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Stops the monitoring of an item after removal,
        RWTItem *itemToRemove = [self.items objectAtIndex:indexPath.row];
        [self stopMonitoringItem:itemToRemove];

        [tableView beginUpdates];
        [self.items removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [tableView endUpdates];
        [self persistItems];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    RWTItem *item = [self.items objectAtIndex:indexPath.row];
    NSString *detailMessage = [NSString stringWithFormat:@"UUID: %@\nMajor: %d\nMinor: %d", item.uuid.UUIDString, item.majorValue, item.minorValue];
    UIAlertView *detailAlert = [[UIAlertView alloc] initWithTitle:@"Details" message:detailMessage delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
    [detailAlert show];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Failed monitoring region: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Location manager failed: %@", error);
}

/* Called for when a iBeacon comes within range, move out of range, or when the range of an iBeacon changes */
- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    for (CLBeacon *beacon in beacons) {
        for (RWTItem *item in self.items) {
            if ([item isEqualToCLBeacon:beacon]) {
                item.lastSeenBeacon = beacon;
                
                // Check if beacon is an SuperOmni
                if ([beacon.major intValue] == 1010)
                    [self checkBeacon:beacon speakerNdx:self.superOmniNdx];
                
                // Check if beacon is an SmartThings
                if ([beacon.major intValue] == 1001)
                    [self checkBeacon:beacon speakerNdx:self.smartThingsNdx];
                
            }
        }
    }
}

/* Helper method for determining which speaker - beacon is interacting and acts accordingly */
- (void) checkBeacon: (CLBeacon *)beacon
          speakerNdx: (int)index {
    
    HKWControlHandler *temp = [HKWControlHandler sharedInstance];
    
    // If the beacon is 'Near' or 'Immediate'(ly) close, play music on that speaker and adjust the volume if we move around.
    if (beacon.proximity == CLProximityNear || beacon.proximity == CLProximityImmediate) {
        int volumeLvl = [self changeVolumeBasedOnProximity:beacon];
        
        // If beacon correlates to superomni (omni10) add 7 volume to make it louder
        if ([beacon.major intValue] == 1010)
            volumeLvl += 3;
        
        [temp setVolumeDevice:[temp getDeviceInfoByIndex:index].deviceId volume:volumeLvl];

        // If song isn't playing start playing it
        if (![temp isPlaying])
            [self playStreaming];
    }
    // If beacon is 'Far' or 'Unknown' (out of reach), turn down the volume of that speaker to 0
    else
        [temp setVolumeDevice:[temp getDeviceInfoByIndex:index].deviceId volume:0];

}

/* Called when user enters a monitored region */
- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Just entered a beacon region";
    notification.soundName = @"Default";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}


/* Called when user leaves a monitored region */
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Just left a beacon region";
    notification.soundName = @"Default";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [[HKWControlHandler sharedInstance] stop];
}

/* Starts the playing of the first mp3 file */
- (void) playStreaming {
    
    /* Removes the other speaker from the session
    DeviceInfo *temp = [[HKWControlHandler sharedInstance] getDeviceInfoByIndex: (int)index];
    if ([temp.deviceName isEqual: deviceName]) {
        [[HKWControlHandler sharedInstance] removeDeviceFromSession: temp.deviceId];
    }*/
    
    // Plays the first song that we have access too. (I'm blue.mp3)
    NSString *bundleRoot = [[NSBundle mainBundle] bundlePath];
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:bundleRoot error:nil];
    NSPredicate *filter = [NSPredicate predicateWithFormat: @"self ENDSWITH '.mp3'"];
    _music = [dirContents filteredArrayUsingPredicate:filter];
    
    NSURL *assetURL = [NSURL fileURLWithPath: [bundleRoot stringByAppendingPathComponent: _music[0]]];
    NSLog(@"NSURL: %@", assetURL);
    
    [[HKWControlHandler sharedInstance] playCAF:assetURL songName:_music[0] resumeFlag:true];
}

/* Changes volume of superomni, based on beacon's rssi value.
 * Currently using hard coded values, could change once an algorithm is figured out...
 * UPDATE: This is actually pretty unreliable. RSSI fluctuates very heavily and can be interfered with by very common things.
 * iBeacons should be used to sense just sense proximity as of right now. */
- (int) changeVolumeBasedOnRSSI: (CLBeacon *) beacon {
    
    // As RSSI goes down, volume needs to go up
    // As RSSI goes up, volume needs to go down (inverse relationship)
    NSLog(@"In changeVolumeBasedOnRSSI.\nRSSI: %zd\nCurrent accuracy: %f meters", beacon.rssi, beacon.accuracy);
    
    if (beacon.rssi < -80)
        return 40;
    else if (beacon.rssi < -60)
        return 30;
    else if (beacon.rssi < -40)
        return 20;
    else if (beacon.rssi < -25)
        return 15;
    
    return 0;
}

/* Changes volume of superomni based on beacon's accuracy value */
- (void) changeVolumeBasedOnAccuracy: (CLBeacon *) beacon {
    NSLog(@"In changeVolumeBasedOnAcc.\nRSSI: %zd\nCurrent accuracy: %f meters\nVolume: %d", beacon.rssi, beacon.accuracy, (int)(15 * beacon.accuracy));
    [[HKWControlHandler sharedInstance] setVolumeAll: (int)(15 * beacon.accuracy)];
}

/* Method used to change volume of a connected speaker based on beacon proximity value */
- (int) changeVolumeBasedOnProximity: (CLBeacon *)beacon {
    switch (beacon.proximity) {
        case CLProximityImmediate:
            return 20;
            break;
        case CLProximityNear:
            return 10;
            break;
        case CLProximityFar:
            return 0;
            break;
        case CLProximityUnknown:
            return 0;
            break;
    }
}

@end
