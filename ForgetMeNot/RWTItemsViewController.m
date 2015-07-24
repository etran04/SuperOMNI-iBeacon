//
//  RWTItemsViewController.m
//  SuperOMNI
//
//  Created by Eric Tran on 7/2/15.
//  Copyright (c) 2015 Harman International. All rights reserved.
//

#import "RWTItemsViewController.h"
#import "RWTAddItemViewController.h"
#import "RWTItem.h"
#import "ItemCell.h"
#import "HKWControlHandler.h"
#import "HKWPlayerEventHandlerSingleton.h"
#import "HKWDeviceEventHandlerSingleton.h"
#import "DataItem.h"
#import "LinearRegression.h"
#import "RegressionResult.h"

@import CoreLocation;
@import Foundation;

NSString * const kRWTStoredItemsKey = @"storedItems";
int const kSecondsToPollFor = 5;

@interface RWTItemsViewController () <UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *itemsTableView;
@property (strong, nonatomic) NSMutableArray *items;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSArray *music;
@property int superOmniNdx;
@property int smartThingsNdx;
@property (strong, nonatomic) NSMutableArray *smartThingsDataPoints;
@property (strong, nonatomic) NSArray *ratios;
@property (strong, nonatomic) LinearRegression * linearFit;

@end

@implementation RWTItemsViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    // Set up location manager
    self.locationManager = [[CLLocationManager alloc] init];
    if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        [self.locationManager requestAlwaysAuthorization];
    self.locationManager.delegate = self;

    self.superOmniNdx = self.smartThingsNdx = -1;
    [self searchBeacons];
    [[HKWControlHandler sharedInstance] setVolumeAll: 0];
    
    [self loadItems];
    
    // init array for smartThingsRanges
    self.smartThingsDataPoints = [[NSMutableArray alloc] initWithCapacity:kSecondsToPollFor];
    self.linearFit = [LinearRegression sharedInstance];
     
}

/* Goes through list of speakers and assigns index number to the superOmni and the smartThings speaker
 * If current speaker is neither, removes that speaker from playback session.
 * Currently hardcoded to look for speakers named "SuperOmni" and "SmartThings"
 */
- (void) searchBeacons {
    for (int i = 0; i < [[HKWControlHandler sharedInstance] getDeviceCount]; i++) {
        DeviceInfo * dInfo = [[HKWControlHandler sharedInstance] getDeviceInfoByIndex:i];
        if ([dInfo.deviceName isEqual: @"SuperOmni"])
            self.superOmniNdx = i;
        else if ([dInfo.deviceName isEqual: @"SmartThings"])
            self.smartThingsNdx = i;
        else
            [[HKWControlHandler sharedInstance] removeDeviceFromSession: dInfo.deviceId];
    }
}

/* Handles the transition from current view controller to the addItemViewController */
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

/* Helper method for allocating a beaconRegion through our custom beacon 'RWTItem' */
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

/* Called for when a iBeacon comes within range, move out of range, or when the range of an iBeacon changes (called at a frequency of 1Hz) */
- (void)locationManager:(CLLocationManager *)manager
        didRangeBeacons:(NSArray *)beacons
               inRegion:(CLBeaconRegion *)region {
    
    // If either ndx hasn't been assign, check to see if they're available. 
    if (self.superOmniNdx == -1 || self.smartThingsNdx == -1)
        [self searchBeacons];
    
    for (CLBeacon *beacon in beacons) {
        for (RWTItem *item in self.items) {
            if ([item isEqualToCLBeacon:beacon]) {
                item.lastSeenBeacon = beacon;
                
                // Check if beacon is an SuperOmni
                if ([beacon.major intValue] == 1010 && self.superOmniNdx != -1)
                    [self calcAvgAndStream: beacon speakerNdx:self.superOmniNdx];
                
                // Check if beacon is an SmartThings
                if ([beacon.major intValue] == 1100 && self.smartThingsNdx != -1) {
                    [self calcAvgAndStream: beacon speakerNdx:self.smartThingsNdx];
                }
                
            }
        }
    }
}

/* Create a new data point with the beacon rssi and accuracy value
 * Stores into an array
 * If full, calculates the linear regression and uses that in order to compute the best fit rssi value to base the volume off of. */
- (void) calcAvgAndStream: (CLBeacon *) beacon
               speakerNdx: (int) speakerNdx {
    
    if (self.smartThingsDataPoints.count == kSecondsToPollFor) {
        
        RegressionResult *answer = [self.linearFit calculate];
        // Linear fit of the set of  data points...
        // Using this linear fit, we can plug in the current dist to figure out the rssi and play accordingly.
        float calcRSSI = (answer.slope * beacon.accuracy) + answer.intercept;
        
        // clear data to go again
        [self.smartThingsDataPoints removeObjectAtIndex:0];
        [self.linearFit removeFirst];
        
        [self checkBeacon:beacon speakerNdx:speakerNdx avgRSSI:calcRSSI];
    } else {
        // add a new data point with rssi value and dist
        NSLog(@"Added new dataPoint with rssi: %ld accuracy: %f", (long)beacon.rssi, beacon.accuracy);
        DataItem * temp = [DataItem new];
        temp.xValue = beacon.accuracy;
        temp.yValue = beacon.rssi;
        [self.smartThingsDataPoints addObject: temp];
        [self.linearFit addDataObject:temp];
    }

    
}

/* Helper method for determining which speaker - beacon is interacting and acts accordingly */
- (void) checkBeacon: (CLBeacon *)beacon
          speakerNdx: (int)index
             avgRSSI: (float)rssi {
    
    HKWControlHandler *temp = [HKWControlHandler sharedInstance];
    
    // If the beacon is 'Near' or 'Immediate'(ly) close, play music on that speaker and adjust the volume if we move around.
    if (beacon.proximity == CLProximityNear || beacon.proximity == CLProximityImmediate) {
        int volumeLvl = [self changeVolumeBasedOnRSSI:rssi];
        
        // If beacon correlates to superomni (omni10), add volume to make it louder
        if ([beacon.major intValue] == 1010)
            volumeLvl += 5;
        else if ([beacon.major intValue] == 1100) // Beacon is smartThings (Omni20), play more quiter
            volumeLvl -= 6;
        
        [temp setVolumeDevice:[temp getDeviceInfoByIndex:index].deviceId volume:volumeLvl];
        
        // If song isn't playing start playing it
        if (![temp isPlaying])
            [self playStreaming];
    }
    // If beacon is 'Far' or 'Unknown' (out of reach), turn down the volume of that speaker to 0
    else
        [temp setVolumeDevice:[temp getDeviceInfoByIndex:index].deviceId volume:0];
    
}

/* Notify when user enters a monitored region through local notifcations */
- (void)locationManager:(CLLocationManager *)manager
         didEnterRegion:(CLRegion *)region {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Just entered a beacon region";
    notification.soundName = @"Default";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
}


/* Notify when user leaves a monitored region through local notifcations */
- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    UILocalNotification *notification = [[UILocalNotification alloc] init];
    notification.alertBody = @"Just left a beacon region";
    notification.soundName = @"Default";
    [[UIApplication sharedApplication] presentLocalNotificationNow:notification];
    [[HKWControlHandler sharedInstance] stop];
}

/* Starts the playing of the first mp3 file */
- (void) playStreaming {
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
 * iBeacons should be used to sense just sense proximity as of right now.
 * UPDATE 2: After talking with Seonman and Kevin, doing linear interpolation and averaging out a set might be what we want. */
- (int) changeVolumeBasedOnRSSI: (float) rssi { //(CLBeacon *) beacon {
    
    // Realistically, can't go father than -88 approx.
    if (rssi < -80)
        return 40;
    else if (rssi < -70)
        return 35;
    else if (rssi < -60)
        return 30;
    else if (rssi < -45)
        return 25;
    else if (rssi < -25)
        return 20;
    
    return 0; // Unknown rssi
}


/* Linear interpolation helper method between two points, returns the estimated dist value at newDist
- (float) lerpForNewDistance: (float) targetRssi
                      pointA: (DataPoint *) pointA
                      pointB: (DataPoint *) pointB {
    
    float slope = (pointB.distValue - pointA.distValue) / (pointB.rssiValue - pointA.rssiValue) ;
    
    return -(pointA.distValue + (targetRssi - pointA.rssiValue) * slope);
}*/


#pragma mark - UITableViewDataSource 

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Item" forIndexPath:indexPath];
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
@end
