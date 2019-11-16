//
//  BASnapshotView.h
//  Guidance
//
//  Created by Ameir Al-Zoubi on 5/3/14.
//  Copyright (c) 2014 Batoul Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BASnapshotView : NSView

@property (strong, nonatomic) NSImage *snapshot;
@property (strong, nonatomic) NSAttributedString *day;
@property (strong, nonatomic) NSAttributedString *month;
@property (strong, nonatomic) NSAttributedString *year;
@property (assign, nonatomic) BOOL arabicMode;

- (NSRect)dayRect;
- (NSRect)monthRect;
- (NSRect)yearRect;

@end
