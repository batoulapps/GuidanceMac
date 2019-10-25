//
//  NSSound+Guidance.h
//  Guidance
//
//  Created by Ameir Al-Zoubi on 6/29/14.
//  Copyright (c) 2014 Batoul Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString * const kBAPrayerAlertInfoKeyPrayer;
extern NSString * const kBAPrayerAlertInfoKeyAdhan;

@interface NSSound (Guidance)

@property (nonatomic, strong) NSDictionary *prayerAlertInfo;

@end
