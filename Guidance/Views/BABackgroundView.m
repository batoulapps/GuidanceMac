//
//  BABackgroundView.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 7/3/13.
//  Copyright (c) 2013 Batoul Apps. All rights reserved.
//

#import "BABackgroundView.h"
#import "BAConstants.h"

@implementation BABackgroundView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect contentRect = [self bounds];

    NSBezierPath *path = [NSBezierPath bezierPath];
    
    NSPoint bottomRightCorner = NSMakePoint(NSMaxX(contentRect), NSMinY(contentRect));
    
    [path moveToPoint:NSMakePoint(0.0, kBAPanelHeight)];
    [path lineToPoint:NSMakePoint(NSMaxX(contentRect), kBAPanelHeight)];
    [path lineToPoint:NSMakePoint(NSMaxX(contentRect), NSMinY(contentRect) + kBAPanelCornerRadius)];
    [path curveToPoint:NSMakePoint(NSMaxX(contentRect) - kBAPanelCornerRadius, NSMinY(contentRect))
         controlPoint1:bottomRightCorner controlPoint2:bottomRightCorner];
    
    [path lineToPoint:NSMakePoint(NSMinX(contentRect) + kBAPanelCornerRadius, NSMinY(contentRect))];
    
    [path curveToPoint:NSMakePoint(NSMinX(contentRect), NSMinY(contentRect) + kBAPanelCornerRadius)
         controlPoint1:contentRect.origin controlPoint2:contentRect.origin];
    
    [path lineToPoint:NSMakePoint(NSMinX(contentRect), NSMaxY(contentRect))];
    
    [path closePath];
    
    [[NSColor whiteColor] setFill];
    [path fill];
    
    NSRect line = NSMakeRect(13.0, 56.0, 206.0, 1.0);
    [[NSColor colorWithDeviceWhite:191.0/255.0 alpha:1.0] setFill];
    [NSBezierPath fillRect:line];
}


@end
