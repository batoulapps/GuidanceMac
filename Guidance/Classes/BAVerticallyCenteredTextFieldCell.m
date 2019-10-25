//
//  BAVerticallyCenteredTextFieldCell.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 7/5/14.
//  Copyright (c) 2014 Batoul Apps. All rights reserved.
//

#import "BAVerticallyCenteredTextFieldCell.h"

@implementation BAVerticallyCenteredTextFieldCell

- (NSRect)drawingRectForBounds:(NSRect)rect
{
    NSRect newRect = [super drawingRectForBounds:rect];
    
    // Get our ideal size for current text
    NSSize textSize = [self cellSizeForBounds:rect];
    
    NSFont *font = [self.attributedStringValue attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];
    if (!font) {
        return newRect;
    }
    
    CGFloat adjustedHeight = textSize.height + (font.ascender - font.capHeight) - self.fontOffset;
    
    // Center that in the proposed rect
    float heightDelta = newRect.size.height - adjustedHeight;
    if (heightDelta > 0)
    {
        newRect.origin.y += (heightDelta / 2);
    }
    
    return newRect;
}

@end
