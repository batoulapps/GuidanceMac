//
//  BALocalizer.m
//  QamarDeen
//
//  Created by Ameir Al-Zoubi on 7/31/10.
//  Copyright 2010 Batoul Apps. All rights reserved.
//

#import "BALocalizer.h"
#import "BAPreferences.h"

@implementation BALocalizer

+ (NSString *)localizedDhuhr
{
	NSInteger weekday = [[[Formatter gregorianCalendar] components:NSCalendarUnitWeekday fromDate:[NSDate date]] weekday];
	if(weekday == 6) {
		return BALocalizedString(@"Jumuah");
	} else {
		return BALocalizedString(@"Dhuhr");
	}
}

+ (NSString *)localizedDhuhrAbbreviation
{
	NSInteger weekday = [[[Formatter gregorianCalendar] components:NSCalendarUnitWeekday fromDate:[NSDate date]] weekday];
	if(weekday == 6) {
		return BALocalizedString(@"J");
	} else {
		return BALocalizedString(@"D");
	}
}

+ (NSDate *)adjustedHijriDateForDate:(NSDate *)date
{
	NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
	dateComponents.day = [[BAPreferences sharedPreferences] hijriOffset];
	
	NSDate *adjustedDate = [[Formatter hijriCalendar] dateByAddingComponents:dateComponents toDate:date options:0];
    
    return adjustedDate;
}

+ (NSInteger)hijriMonthForDate:(NSDate *)date
{
    NSDate *hijriDate = [BALocalizer adjustedHijriDateForDate:date];
    NSDateComponents *components = [[Formatter hijriCalendar] components:NSCalendarUnitMonth fromDate:hijriDate];
    
    return components.month;
}

@end
