//
//  DataPoint.h
//  SuperOMNI
//
//  Created by Eric Tan on 7/23/15.
//  Copyright (c) 2015 Harman International. All rights reserved.
//

#ifndef SuperOMNI_DataPoint_h
#define SuperOMNI_DataPoint_h

@interface DataPoint : NSObject

@property float distValue;
@property float rssiValue;


+ (DataPoint *) initWithValues: (float) dist
                          rssi: (float) rssiVal;

- (NSComparisonResult) compare: (DataPoint *) otherPt;

- (float) getrssi;
- (float) getdist; 

@end


#endif
