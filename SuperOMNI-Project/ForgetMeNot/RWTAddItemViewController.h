//
//  RWTAddItemViewController.h
//  ForgetMeNot
//
//  Created by Chris Wagner on 1/29/14.
//  Copyright (c) 2014 Ray Wenderlich Tutorial Team. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RWTItem;

typedef void(^RWTItemAddedCompletion)(RWTItem *newItem);
typedef void(^CheckReverseBtn) (bool flag);

@interface RWTAddItemViewController : UITableViewController

@property (nonatomic, copy) RWTItemAddedCompletion itemAddedCompletion;
@property (nonatomic, copy) CheckReverseBtn checkReverseButton;

@end

