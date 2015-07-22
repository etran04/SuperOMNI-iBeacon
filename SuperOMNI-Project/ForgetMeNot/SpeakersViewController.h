//
//  SpeakersViewController.h
//  ForgetMeNot
//
//  Created by Eric Tan on 7/1/15.
//  Copyright (c) 2015 Ray Wenderlich Tutorial Team. All rights reserved.
//

#ifndef ForgetMeNot_SpeakersViewController_h
#define ForgetMeNot_SpeakersViewController_h


#endif

extern NSString * const kListOfSpeakers;

typedef void(^updateButton)(bool flag);

@interface SpeakersViewController : UITableViewController

- (IBAction) playPressed:(id)sender;
- (IBAction) volumeDown:(id)sender;
- (IBAction) volumeUp:(id)sender;
- (IBAction) reverseDistance:(id)sender; 

@end