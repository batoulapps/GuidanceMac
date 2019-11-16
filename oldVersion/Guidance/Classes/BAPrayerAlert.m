//
//  BAPrayerAlert.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 6/29/14.
//  Copyright (c) 2014 Batoul Apps. All rights reserved.
//

#import "BAPrayerAlert.h"

@implementation BAPrayerAlert

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@: %@ - %@\n%@", self.title, self.message, [self.time description], self.audioFile.absoluteString];
}

@end
