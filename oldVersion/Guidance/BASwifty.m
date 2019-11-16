//
//  BASwifty.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 10/30/16.
//  Copyright © 2016 Batoul Apps. All rights reserved.
//

#import "BASwifty.h"
#import "BAPreferences.h"

@implementation BASwifty

+ (NSString *)currentTimeZoneIdentifier
{
    return [[BAPreferences sharedPreferences] timeZone];
}

+ (BOOL)forceArabic
{
    return [[BAPreferences sharedPreferences] forceArabic];
}

@end
