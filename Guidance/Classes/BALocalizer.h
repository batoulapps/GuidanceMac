//
//  BALocalizer.h
//  Guidance
//
//  Created by Ameir Al-Zoubi on 7/31/10.
//  Copyright 2010 Batoul Apps. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BALocalizer : NSObject

+ (NSString *)localizedDhuhr;
+ (NSString *)localizedDhuhrAbbreviation;

+ (NSDate *)adjustedHijriDateForDate:(NSDate *)date;
+ (NSInteger)hijriMonthForDate:(NSDate *)date;

@end


