//
//  RWTItem.h
//  ForgetMeNot
//
//  Created by Chris Wagner on 1/29/14.
//  Copyright (c) 2014 Ray Wenderlich Tutorial Team. All rights reserved.
//

#import <Foundation/Foundation.h>

@import CoreLocation;

static NSString * const HarmanUUID = @"5D3758EC-4C01-4C38-A1BF-69A1536E3513";

@interface RWTItem : NSObject <NSCoding>

@property (strong, nonatomic, readonly) NSString *name;
@property (strong, nonatomic, readonly) NSUUID *uuid;
@property (assign, nonatomic, readonly) CLBeaconMajorValue majorValue;
@property (assign, nonatomic, readonly) CLBeaconMinorValue minorValue;
@property (strong, nonatomic) CLBeacon *lastSeenBeacon;


- (instancetype)initWithName:(NSString *)name
                        uuid:(NSUUID *)uuid
                       major:(CLBeaconMajorValue)major
                       minor:(CLBeaconMinorValue)minor;

/* Compares a CLBeacon instance with an RWTItem instance to see if they are equal. (If all identifiers match) */
- (BOOL)isEqualToCLBeacon:(CLBeacon *)beacon;

- (BOOL)isEqualToSpecific:(NSString *) uuid
                    majorVal:(NSString *) majorVal
                    minorVal:(NSString *) minorVal;


@end
