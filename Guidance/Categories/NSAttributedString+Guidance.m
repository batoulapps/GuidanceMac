//
//  NSAttributedString+Guidance.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 3/28/15.
//  Copyright (c) 2015 Batoul Apps. All rights reserved.
//

#import "NSAttributedString+Guidance.h"

@implementation NSAttributedString (Guidance)

- (NSAttributedString *)ba_fittedAttributedStringToWidth:(CGFloat)width
{
    NSMutableAttributedString *mutable = [self mutableCopy];
    CGFloat stringWidth = NSWidth([mutable boundingRectWithSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX) options:0]);
    NSFont *font = [mutable attribute:NSFontAttributeName atIndex:0 effectiveRange:NULL];

    if (font) {
        CGFloat fontSize = [font pointSize];
        while (stringWidth > width && fontSize > 1) {
            fontSize = fontSize - 1;
            NSRange range = NSMakeRange(0, mutable.length);
            
            [mutable removeAttribute:NSFontAttributeName range:range];
            [mutable addAttribute:NSFontAttributeName value:[NSFont fontWithName:font.familyName size:fontSize] range:range];
            
            // re-measure string length
            stringWidth = NSWidth([mutable boundingRectWithSize:NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX) options:0]);
        }
    }
    
    return [mutable copy];
}

@end
