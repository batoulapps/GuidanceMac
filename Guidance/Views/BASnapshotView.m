//
//  BASnapshotView.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 5/3/14.
//  Copyright (c) 2014 Batoul Apps. All rights reserved.
//

#import "BASnapshotView.h"

#import <QuartzCore/QuartzCore.h>
#import <Accelerate/Accelerate.h>
#import <float.h>

static CGFloat const kBAPanelTopLineOpacity = 0.05;
static CGFloat const kBAPanelTopAltColor = 0.94;

@implementation BASnapshotView

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithDeviceWhite:kBAPanelTopAltColor alpha:1.0] setFill];
    [NSBezierPath fillRect:dirtyRect];

    NSRect line = NSMakeRect(0, 0.0, CGRectGetWidth(dirtyRect), 1.0);
    [[NSColor colorWithDeviceWhite:0.0 alpha:kBAPanelTopLineOpacity] setFill];
    [NSBezierPath fillRect:line];
    
    [self.day drawInRect:[self dayRect]];
    [self.month drawInRect:[self monthRect]];
    [self.year drawInRect:[self yearRect]];
}

- (NSRect)dayRect
{
    if (self.arabicMode) {
        return NSMakeRect(145.0, 17.0, 85.0, 66.0);
    }
    
    return NSMakeRect(2.0, 9.0, 70.0, 66.0);
}

- (NSRect)monthRect
{
    if (self.arabicMode) {
        return NSMakeRect(1.0, 30.0, 136.0, 40.0);
    }
    
    return NSMakeRect(90.0, 33.0, 135.0, 33.0);
}

- (NSRect)yearRect
{
    if (self.arabicMode) {
        return NSMakeRect(1.0, 5.0, 136.0, 36.0);
    }
    
    return NSMakeRect(90.0, 5.0, 140.0, 36.0);
}



@end
