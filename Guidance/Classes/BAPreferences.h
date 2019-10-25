//
//  BAPreferences.h
//  Guidance
//
//  Created by Ameir Al-Zoubi on 5/5/14.
//  Copyright (c) 2014 Batoul Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Adhan-Swift.h"

@class CLPlacemark;

typedef enum : NSInteger {
    BANextPrayerDisplayTypeTimeUntilNextPrayer,
    BANextPrayerDisplayTypeTimeOfNextPrayer,
    BANextPrayerDisplayTypeNone
} BANextPrayerDisplayType;

typedef enum : NSInteger {
    BANextPrayerDisplayNameFull,
    BANextPrayerDisplayNameAbbreviation,
    BANextPrayerDisplayNameNone
} BANextPrayerDisplayName;

typedef enum : NSInteger {
    BAMadhabPreferenceShafi,
    BAMadhabPreferenceHanafi
} BAMadhabPreference;

typedef enum : NSInteger {
    BAMethodPreferenceEgyptian,
    BAMethodPreferenceKarachi,
    BAMethodPreferenceNorthAmerica,
    BAMethodPreferenceMuslimWorldLeague,
	BAMethodPreferenceUmmAlQura,
	BAMethodPreferenceGulf,
    BAMethodPreferenceMoonsightingCommittee,
	BAMethodPreferenceCustom,
    BAMethodPreferenceKuwait,
    BAMethodPreferenceQatar,
    BAMethodPreferenceSingapore,
    BAMethodPreferenceTehran
} BAMethodPreference;

extern NSString * const kBAUserDefaultsDidChangeNotification;
extern NSString * const kBAAlertsDidChangeNotification;
extern NSInteger const kBAAdhanOptionCustom;

@interface BAPreferences : NSObject

@property (strong, nonatomic) NSString *version;

@property (assign, nonatomic) BOOL forceArabic;

@property (assign, nonatomic) BOOL displayNextPrayer;
@property (assign, nonatomic) BANextPrayerDisplayType nextPrayerDisplayType;
@property (assign, nonatomic) BANextPrayerDisplayName nextPrayerDisplayName;
@property (assign, nonatomic) BOOL displayIcon;

@property (assign, nonatomic) BOOL useCurrentLocation;
@property (strong, nonatomic) NSString *city;
@property (strong, nonatomic) NSString *state;
@property (strong, nonatomic) NSString *country;
@property (strong, nonatomic) NSString *countryName;
@property (strong, nonatomic) NSString *timeZone;

@property (assign, nonatomic) double latitude;
@property (assign, nonatomic) double longitude;

@property (assign, nonatomic) BOOL autoDetectMethod;
@property (assign, nonatomic) BOOL autoDetectHighLatitudeRule;

@property (assign, nonatomic) double customFajrAngle;
@property (assign, nonatomic) double customIshaAngle;
@property (assign, nonatomic) BAMadhabPreference madhab;
@property (assign, nonatomic) BAMethodPreference method;
@property (assign, nonatomic) BAHighLatitudeRule highLatitudeRule;

@property (assign, nonatomic) NSInteger fajrAdjustment;
@property (assign, nonatomic) NSInteger shuruqAdjustment;
@property (assign, nonatomic) NSInteger dhuhrAdjustment;
@property (assign, nonatomic) NSInteger asrAdjustment;
@property (assign, nonatomic) NSInteger maghribAdjustment;
@property (assign, nonatomic) NSInteger ishaAdjustment;

@property (assign, nonatomic) BOOL fajrReminderAlertEnabled;
@property (assign, nonatomic) BOOL fajrAlertEnabled;
@property (assign, nonatomic) BOOL shuruqReminderAlertEnabled;
@property (assign, nonatomic) BOOL dhuhrAlertEnabled;
@property (assign, nonatomic) BOOL asrAlertEnabled;
@property (assign, nonatomic) BOOL maghribAlertEnabled;
@property (assign, nonatomic) BOOL ishaAlertEnabled;

@property (assign, nonatomic) NSInteger fajrAdhan;
@property (assign, nonatomic) NSInteger dhuhrAdhan;
@property (assign, nonatomic) NSInteger asrAdhan;
@property (assign, nonatomic) NSInteger maghribAdhan;
@property (assign, nonatomic) NSInteger ishaAdhan;

@property (strong, nonatomic) NSData *fajrCustomAdhan;
@property (strong, nonatomic) NSData *dhuhrCustomAdhan;
@property (strong, nonatomic) NSData *asrCustomAdhan;
@property (strong, nonatomic) NSData *maghribCustomAdhan;
@property (strong, nonatomic) NSData *ishaCustomAdhan;

@property (assign, nonatomic) NSInteger alertVolume;

@property (assign, nonatomic) BOOL duaEnabled;

@property (assign, nonatomic) BOOL silentMode;

@property (assign, nonatomic) NSInteger fajrReminderOffset;
@property (assign, nonatomic) NSInteger shuruqReminderOffset;

@property (assign, nonatomic) NSInteger hijriOffset;

@property (assign, nonatomic) BOOL delayedIshaInRamadan;

+ (BAPreferences *)sharedPreferences;
- (void)registerDefaults;
- (void)synchronize;
- (void)updateLocationWithPlacemark:(CLPlacemark *)placemark;
- (void)updatePreferences;

+ (NSURL *)fileForAdhan:(NSInteger)adhan customAdhan:(NSData *)customAdhan;

+ (BACalculationMethod)calculationMethodForPreference:(BAMethodPreference)methodPref;
+ (BAMadhab)madhabForPreference:(BAMadhabPreference)madhabPref;

@end
