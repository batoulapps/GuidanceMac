//
//  NSSound+Guidance.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 6/29/14.
//  Copyright (c) 2014 Batoul Apps. All rights reserved.
//

#import "NSSound+Guidance.h"

#import <objc/runtime.h>

NSString * const kBAPrayerAlertInfoKeyPrayer = @"kBAPrayerAlertInfoKeyPrayer";
NSString * const kBAPrayerAlertInfoKeyAdhan = @"kBAPrayerAlertInfoKeyAdhan";

@implementation NSSound (Guidance)

- (NSDictionary *)prayerAlertInfo
{
    return objc_getAssociatedObject(self, @selector(prayerAlertInfo));
}

- (void)setPrayerAlertInfo:(NSDictionary *)prayerAlertInfo
{
    objc_setAssociatedObject(self, @selector(prayerAlertInfo), prayerAlertInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
