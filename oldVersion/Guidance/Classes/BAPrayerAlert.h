//
//  BAPrayerAlert.h
//  Guidance
//
//  Created by Ameir Al-Zoubi on 6/29/14.
//  Copyright (c) 2014 Batoul Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Adhan-Swift.h"

@interface BAPrayerAlert : NSObject

@property (strong, nonatomic) NSDate *time;
@property (copy, nonatomic) NSString *title;
@property (copy, nonatomic) NSString *message;
@property (assign, nonatomic) BOOL playAudio;
@property (strong, nonatomic) NSURL *audioFile;
@property (assign, nonatomic) BAPrayer prayerType;

@end
