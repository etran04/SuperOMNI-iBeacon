//
//  DataPoint.m
//  SuperOMNI
//
//  Created by Eric Tan on 7/23/15.
//  Copyright (c) 2015 Harman International. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataPoint.h"

@implementation DataPoint

+ (DataPoint *) initWithValues: (float) dist
                   rssi: (float) rssiVal {
    DataPoint * newPoint = [DataPoint new];
    newPoint.distValue = dist;
    newPoint.rssiValue = rssiVal;
    return newPoint;
}

/* Helper method for sorting array of datapoints by rssi values */
- (NSComparisonResult) compare: (DataPoint *) otherPt {
    if (self.rssiValue < otherPt.rssiValue)
        return NSOrderedAscending;
    else if (self.rssiValue > otherPt.rssiValue)
        return NSOrderedDescending;
    else
        return NSOrderedSame;
}

- (float) getrssi {
    return self.rssiValue;
}

- (float) getdist {
    return self.distValue; 
}

@end