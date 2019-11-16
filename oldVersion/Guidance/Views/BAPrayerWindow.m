//
//  BAPrayerWindow.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 7/3/13.
//  Copyright (c) 2013 Batoul Apps. All rights reserved.
//

#import "BAPrayerWindow.h"

@implementation BAPrayerWindow

- (BOOL)canBecomeKeyWindow;
{
    return YES; // Allow panel to become first responder so we can detect the removal of focus
}

@end
