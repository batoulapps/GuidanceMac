//
//  BAPreferences.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 5/5/14.
//  Copyright (c) 2014 Batoul Apps. All rights reserved.
//

#import "BAPreferences.h"
#import "Guidance-Swift.h"

#import <CoreLocation/CoreLocation.h>

NSString * const kBAUserDefaultsVersion = @"kBAUserDefaultsVersion";

NSString * const kBAUserDefaultsDidChangeNotification = @"kBAUserDefaultsDidChangeNotification";
NSString * const kBAAlertsDidChangeNotification = @"kBAAlertsDidChangeNotification";

NSString * const kBAUserDefaultsForceArabic = @"kBAUserDefaultsForceArabic";

NSString * const kBAUserDefaultsDisplayNextPrayer = @"kBAUserDefaultsDisplayNextPrayer";
NSString * const kBAUserDefaultsDisplayNextPrayerType = @"kBAUserDefaultsDisplayNextPrayerType";
NSString * const kBAUserDefaultsDisplayNextPrayerName = @"kBAUserDefaultsDisplayNextPrayerName";
NSString * const kBAUserDefaultsDisplayIcon = @"kBAUserDefaultsDisplayIcon";

NSString * const kBAUserDefaultsAutoLocation = @"kBAUserDefaultsAutoLocation";

NSString * const kBAUserDefaultsLocationCity = @"kBAUserDefaultsLocationCity";
NSString * const kBAUserDefaultsLocationState = @"kBAUserDefaultsLocationState";
NSString * const kBAUserDefaultsLocationCountry = @"kBAUserDefaultsLocationCountry";
NSString * const kBAUserDefaultsLocationCountryName = @"kBAUserDefaultsLocationCountryName";
NSString * const kBAUserDefaultsLatitude = @"kBAUserDefaultsLatitude";
NSString * const kBAUserDefaultsLongitude = @"kBAUserDefaultsLongitude";
NSString * const kBAUserDefaultsTimeZone = @"kBAUserDefaultsTimeZone";
NSString * const kBAUserDefaultsMadhab = @"kBAUserDefaultsMadhab";
NSString * const kBAUserDefaultsMethod = @"kBAUserDefaultsMethod";
NSString * const kBAUserDefaultsHighLatitudeRule = @"kBAUserDefaultsHighLatitudeRule";

NSString * const kBAUserDefaultsAutoDetectMethod = @"kBAUserDefaultsAutoDetectMethod";
NSString * const kBAUserDefaultsAutoDetectHighLatitudeRule = @"kBAUserDefaultsAutoDetectHighLatitudeRule";

NSString * const kBAUserDefaultsCustomFajrAngle = @"kBAUserDefaultsCustomFajrAngle";
NSString * const kBAUserDefaultsCustomIshaAngle = @"kBAUserDefaultsCustomIshaAngle";
NSString * const kBAUserDefaultsAdjustmentFajr = @"kBAUserDefaultsAdjustmentFajr";
NSString * const kBAUserDefaultsAdjustmentShuruq = @"kBAUserDefaultsAdjustmentShuruq";
NSString * const kBAUserDefaultsAdjustmentDhuhr = @"kBAUserDefaultsAdjustmentDhuhr";
NSString * const kBAUserDefaultsAdjustmentAsr = @"kBAUserDefaultsAdjustmentAsr";
NSString * const kBAUserDefaultsAdjustmentMaghrib = @"kBAUserDefaultsAdjustmentMaghrib";
NSString * const kBAUserDefaultsAdjustmentIsha = @"kBAUserDefaultsAdjustmentIsha";

NSString * const kBAUserDefaultsAlertFajrReminderEnabled = @"kBAUserDefaultsAlertFajrReminderEnabled";
NSString * const kBAUserDefaultsAlertFajrEnabled = @"kBAUserDefaultsAlertFajrEnabled";
NSString * const kBAUserDefaultsAlertShuruqReminderEnabled = @"kBAUserDefaultsAlertShuruqReminderEnabled";
NSString * const kBAUserDefaultsAlertDhuhrEnabled = @"kBAUserDefaultsAlertDhuhrEnabled";
NSString * const kBAUserDefaultsAlertAsrEnabled = @"kBAUserDefaultsAlertAsrEnabled";
NSString * const kBAUserDefaultsAlertMaghribEnabled = @"kBAUserDefaultsAlertMaghribEnabled";
NSString * const kBAUserDefaultsAlertIshaEnabled = @"kBAUserDefaultsAlertIshaEnabled";

NSString * const kBAUserDefaultsDua = @"kBAUserDefaultsDua";
NSString * const kBAUserDefaultsSilentMode = @"kBAUserDefaultsSilentMode";

NSString * const kBAUserDefaultsAlertFajrSound = @"kBAUserDefaultsAlertFajrSound";
NSString * const kBAUserDefaultsAlertDhuhrSound = @"kBAUserDefaultsAlertDhuhrSound";
NSString * const kBAUserDefaultsAlertAsrSound = @"kBAUserDefaultsAlertAsrSound";
NSString * const kBAUserDefaultsAlertMaghribSound = @"kBAUserDefaultsAlertMaghribSound";
NSString * const kBAUserDefaultsAlertIshaSound = @"kBAUserDefaultsAlertIshaSound";

NSString * const kBAUserDefaultsAlertFajrCustomSound = @"kBAUserDefaultsAlertFajrCustomSound";
NSString * const kBAUserDefaultsAlertDhuhrCustomSound = @"kBAUserDefaultsAlertDhuhrCustomSound";
NSString * const kBAUserDefaultsAlertAsrCustomSound = @"kBAUserDefaultsAlertAsrCustomSound";
NSString * const kBAUserDefaultsAlertMaghribCustomSound = @"kBAUserDefaultsAlertMaghribCustomSound";
NSString * const kBAUserDefaultsAlertIshaCustomSound = @"kBAUserDefaultsAlertIshaCustomSound";

NSString * const kBAUserDefaultsAlertVolume = @"kBAUserDefaultsAlertVolume";

NSString * const kBAUserDefaultsAlertFajrReminderOffset = @"kBAUserDefaultsAlertFajrReminderOffset";
NSString * const kBAUserDefaultsAlertShuruqReminderOffset = @"kBAUserDefaultsAlertShuruqReminderOffset";

NSString * const kBAUserDefaultsHijriOffset = @"kBAUserDefaultsHijriOffset";

NSString * const kBAUserDefaultsDelayedIshaInRamadan = @"kBAUserDefaultsDelayedIshaInRamadan";

NSInteger const kBAAdhanOptionCustom = 10;

@implementation BAPreferences

+ (BAPreferences *)sharedPreferences
{
	__strong static id sharedPreferences;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedPreferences = [[BAPreferences alloc] init];
	});
	
	return sharedPreferences;
}

- (instancetype)init
{
    self = [super init];
    return self;
}

- (void)updatePreferences
{
    if (self.autoDetectMethod) {
        if ([@[@"EG", @"SD", @"SS", @"LY", @"DZ", @"LB", @"SY", @"IL", @"MA", @"PS", @"IQ", @"TR", @"MY"] containsObject:self.country]) {
            self.method = BAMethodPreferenceEgyptian;
        } else if ([@[@"PK", @"IN", @"BD", @"AF", @"JO"] containsObject:self.country]) {
            self.method = BAMethodPreferenceKarachi;
        } else if ([@[@"SA"] containsObject:self.country]) {
            self.method = BAMethodPreferenceUmmAlQura;
        } else if ([@[@"AE"] containsObject:self.country]) {
            self.method = BAMethodPreferenceGulf;
        } else if ([@[@"US", @"CA", @"UK", @"GB"] containsObject:self.country]) {
            self.method = BAMethodPreferenceMoonsightingCommittee;
        } else if ([@[@"KW"] containsObject:self.country]) {
            self.method = BAMethodPreferenceKuwait;
        } else if ([@[@"BH", @"OM", @"YE", @"QA"] containsObject:self.country]) {
            self.method = BAMethodPreferenceQatar;
        } else if ([@[@"SG"] containsObject:self.country]) {
            self.method = BAMethodPreferenceSingapore;
        } else if ([@[@"IR"] containsObject:self.country]) {
            self.method = BAMethodPreferenceTehran;
        } else {
            self.method = BAMethodPreferenceMuslimWorldLeague;
        }
    }

    if (self.autoDetectHighLatitudeRule) {
        if (self.latitude > 48) {
            self.highLatitudeRule = BAHighLatitudeRuleSeventhOfTheNight;
        } else {
            self.highLatitudeRule = BAHighLatitudeRuleMiddleOfTheNight;
        }
    }
}

+ (BACalculationMethod)calculationMethodForPreference:(BAMethodPreference)methodPref
{
    switch (methodPref) {
        case BAMethodPreferenceMuslimWorldLeague:
            return BACalculationMethodMuslimWorldLeague;
        case BAMethodPreferenceEgyptian:
            return BACalculationMethodEgyptian;
        case BAMethodPreferenceKarachi:
            return BACalculationMethodKarachi;
        case BAMethodPreferenceUmmAlQura:
            return BACalculationMethodUmmAlQura;
        case BAMethodPreferenceMoonsightingCommittee:
            return BACalculationMethodMoonsightingCommittee;
        case BAMethodPreferenceNorthAmerica:
            return BACalculationMethodNorthAmerica;
        case BAMethodPreferenceGulf:
            return BACalculationMethodDubai;
        case BAMethodPreferenceQatar:
            return BACalculationMethodQatar;
        case BAMethodPreferenceKuwait:
            return BACalculationMethodKuwait;
        case BAMethodPreferenceCustom:
            return BACalculationMethodOther;
        case BAMethodPreferenceSingapore:
            return BACalculationMethodSingapore;
        case BAMethodPreferenceTehran:
            return BACalculationMethodTehran;
    }
  
    return BACalculationMethodOther;
}

+ (BAMadhab)madhabForPreference:(BAMadhabPreference)madhabPref
{
    if(madhabPref == BAMadhabPreferenceHanafi) {
        return BAMadhabHanafi;
    } else {
        return BAMadhabShafi;
    }
}

- (void)registerDefaults
{
    NSDictionary *appDefaults = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"plist"]];
	[[NSUserDefaults standardUserDefaults] registerDefaults:appDefaults];
}

- (void)synchronize
{
    [[NSUserDefaults standardUserDefaults] synchronize];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBAUserDefaultsDidChangeNotification object:nil];
}

- (void)updateLocationWithPlacemark:(CLPlacemark *)placemark
{
    NSDictionary *info = [BAPreferences infoFromPlacemark:placemark];
    self.latitude = [info[@"latitude"] doubleValue];
    self.longitude = [info[@"longitude"] doubleValue];
    self.country = info[@"country"];
    self.countryName = info[@"countryName"];
    self.state = info[@"state"];
    self.city = info[@"city"];
    self.timeZone = placemark.timeZone.name;
}

+ (NSDictionary *)infoFromPlacemark:(CLPlacemark *)placemark
{
    NSString *city = @"";
    NSString *state = @"";
    NSString *country = @"";
    NSString *countryName = @"";
    double latitude = 0;
    double longitude = 0;
    
    latitude = placemark.location.coordinate.latitude;
    longitude = placemark.location.coordinate.longitude;
    if (placemark.ISOcountryCode) {
        country = placemark.ISOcountryCode;
    }
    if (placemark.country) {
        countryName = placemark.country;
    }
    if (placemark.administrativeArea) {
        state = placemark.administrativeArea;
    }
    if (placemark.locality) {
        city = placemark.locality;
    } else if (placemark.subLocality) {
        city = placemark.subLocality;
    } else if (placemark.administrativeArea) {
        city = placemark.administrativeArea;
    } else if (placemark.country) {
        city = placemark.country;
    }
    
    return @{ @"city" : city,
              @"state" : state,
              @"country" : country,
              @"countryName" : countryName,
              @"latitude" : @(latitude),
              @"longitude" : @(longitude)
             };
}

+ (NSURL *)fileForAdhan:(NSInteger)adhan customAdhan:(NSData *)customAdhan
{
    if (adhan == kBAAdhanOptionCustom) {
        BOOL stale;
        return [NSURL URLByResolvingBookmarkData:customAdhan options:NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&stale error:nil];
    }
    
    NSString *path;
    NSString *type;
    
    switch (adhan) {
        case 2:
            path = @"Adhan-Alafasy";
            type = @"m4a";
            break;
        case 3:
            path = @"Adhan-Yusuf";
            type = @"mp3";
            break;
        case 4:
            path = @"Adhan-Makkah";
            type = @"mp3";
            break;
        case 5:
            path = @"Adhan-Istanbul";
            type = @"mp3";
            break;
        case 6:
            path = @"Adhan-Aqsa";
            type = @"mp3";
            break;
        case 7:
            path = @"Adhan-Fajr";
            type = @"mp3";
            break;
        default:
            path = @"Adhan-Alafasy";
            type = @"m4a";
            break;
    }
    
    return [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:path ofType:type]];
}

/* version */
- (NSString *)version
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kBAUserDefaultsVersion];
}


- (void)setVersion:(NSString *)version
{
    [[NSUserDefaults standardUserDefaults] setObject:version forKey:kBAUserDefaultsVersion];
    [self synchronize];
}


/* forceArabic */
- (BOOL)forceArabic
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsForceArabic];
}

- (void)setForceArabic:(BOOL)forceArabic
{
    [[NSUserDefaults standardUserDefaults] setBool:forceArabic forKey:kBAUserDefaultsForceArabic];
    [self synchronize];
}


/* displayNextPrayer */
- (BOOL)displayNextPrayer
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsDisplayNextPrayer];
}

- (void)setDisplayNextPrayer:(BOOL)displayNextPrayer
{
    [[NSUserDefaults standardUserDefaults] setBool:displayNextPrayer forKey:kBAUserDefaultsDisplayNextPrayer];
    [self synchronize];
}


/* nextPrayerDisplayType */
- (BANextPrayerDisplayType)nextPrayerDisplayType
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsDisplayNextPrayerType];
}

- (void)setNextPrayerDisplayType:(BANextPrayerDisplayType)nextPrayerDisplayType
{
    [[NSUserDefaults standardUserDefaults] setInteger:nextPrayerDisplayType forKey:kBAUserDefaultsDisplayNextPrayerType];
    [self synchronize];
}


/* nextPrayerDisplayName */
- (BANextPrayerDisplayName)nextPrayerDisplayName
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsDisplayNextPrayerName];
}

- (void)setNextPrayerDisplayName:(BANextPrayerDisplayName)nextPrayerDisplayName
{
    [[NSUserDefaults standardUserDefaults] setInteger:nextPrayerDisplayName forKey:kBAUserDefaultsDisplayNextPrayerName];
    [self synchronize];
}


/* displayIcon */
- (BOOL)displayIcon
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsDisplayIcon];
}

- (void)setDisplayIcon:(BOOL)displayIcon
{
    [[NSUserDefaults standardUserDefaults] setBool:displayIcon forKey:kBAUserDefaultsDisplayIcon];
    [self synchronize];
}


/* useCurrentLocation */
- (BOOL)useCurrentLocation
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsAutoLocation];
}

- (void)setUseCurrentLocation:(BOOL)useCurrentLocation
{
    [[NSUserDefaults standardUserDefaults] setBool:useCurrentLocation forKey:kBAUserDefaultsAutoLocation];
    [self synchronize];
}


/* city */
- (NSString *)city
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kBAUserDefaultsLocationCity];
}

- (void)setCity:(NSString *)city
{
    [[NSUserDefaults standardUserDefaults] setObject:city forKey:kBAUserDefaultsLocationCity];
    [self synchronize];
}


/* state */
- (NSString *)state
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kBAUserDefaultsLocationState];
}

- (void)setState:(NSString *)state
{
    [[NSUserDefaults standardUserDefaults] setObject:state forKey:kBAUserDefaultsLocationState];
    [self synchronize];
}


/* country */
- (NSString *)country
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kBAUserDefaultsLocationCountry];
}

- (void)setCountry:(NSString *)country
{
    [[NSUserDefaults standardUserDefaults] setObject:country forKey:kBAUserDefaultsLocationCountry];
    [self synchronize];
}


/* countryName */
- (NSString *)countryName
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kBAUserDefaultsLocationCountryName];
}

- (void)setCountryName:(NSString *)countryName
{
    [[NSUserDefaults standardUserDefaults] setObject:countryName forKey:kBAUserDefaultsLocationCountryName];
    [self synchronize];
}


/* timeZone */
- (NSString *)timeZone
{
    return [[NSUserDefaults standardUserDefaults] stringForKey:kBAUserDefaultsTimeZone];
}

- (void)setTimeZone:(NSString *)timeZone
{
    [[NSUserDefaults standardUserDefaults] setObject:timeZone forKey:kBAUserDefaultsTimeZone];
    [self synchronize];
}


/* latitude */
- (double)latitude
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:kBAUserDefaultsLatitude];
}

- (void)setLatitude:(double)latitude
{
    [[NSUserDefaults standardUserDefaults] setDouble:latitude forKey:kBAUserDefaultsLatitude];
    [self synchronize];
}


/* longitude */
- (double)longitude
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:kBAUserDefaultsLongitude];
}

- (void)setLongitude:(double)longitude
{
    [[NSUserDefaults standardUserDefaults] setDouble:longitude forKey:kBAUserDefaultsLongitude];
    [self synchronize];
}


/* autoDetectMethod */
- (BOOL)autoDetectMethod
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsAutoDetectMethod];
}

- (void)setAutoDetectMethod:(BOOL)autoDetectMethod
{
    [[NSUserDefaults standardUserDefaults] setBool:autoDetectMethod forKey:kBAUserDefaultsAutoDetectMethod];
    [self synchronize];
}


/* autoDetectHighLatitudeRule */
- (BOOL)autoDetectHighLatitudeRule
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsAutoDetectHighLatitudeRule];
}

- (void)setAutoDetectHighLatitudeRule:(BOOL)autoDetectHighLatitudeRule
{
    [[NSUserDefaults standardUserDefaults] setBool:autoDetectHighLatitudeRule forKey:kBAUserDefaultsAutoDetectHighLatitudeRule];
    [self synchronize];
}


/* customFajrAngle */
- (double)customFajrAngle
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:kBAUserDefaultsCustomFajrAngle];
}

- (void)setCustomFajrAngle:(double)customFajrAngle
{
    [[NSUserDefaults standardUserDefaults] setDouble:customFajrAngle forKey:kBAUserDefaultsCustomFajrAngle];
    [self synchronize];
}


/* customIshaAngle */
- (double)customIshaAngle
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:kBAUserDefaultsCustomIshaAngle];
}

- (void)setCustomIshaAngle:(double)customIshaAngle
{
    [[NSUserDefaults standardUserDefaults] setDouble:customIshaAngle forKey:kBAUserDefaultsCustomIshaAngle];
    [self synchronize];
}


/* madhab */
- (BAMadhabPreference)madhab
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsMadhab];
}

- (void)setMadhab:(BAMadhabPreference)madhab
{
    [[NSUserDefaults standardUserDefaults] setInteger:madhab forKey:kBAUserDefaultsMadhab];
    [self synchronize];
}


/* method */
- (BAMethodPreference)method
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsMethod];
}

- (void)setMethod:(BAMethodPreference)method
{
    [[NSUserDefaults standardUserDefaults] setInteger:method forKey:kBAUserDefaultsMethod];
    [self synchronize];
}


/* exteme method */
- (BAHighLatitudeRule)highLatitudeRule
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsHighLatitudeRule];
}

- (void)setHighLatitudeRule:(BAHighLatitudeRule)highLatitudeRule
{
    [[NSUserDefaults standardUserDefaults] setInteger:highLatitudeRule forKey:kBAUserDefaultsHighLatitudeRule];
    [self synchronize];
}


/* fajrAdjustment */
- (NSInteger)fajrAdjustment
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAdjustmentFajr];
}

- (void)setFajrAdjustment:(NSInteger)fajrAdjustment
{
    [[NSUserDefaults standardUserDefaults] setInteger:fajrAdjustment forKey:kBAUserDefaultsAdjustmentFajr];
    [self synchronize];
}


/* shuruqAdjustment */
- (NSInteger)shuruqAdjustment
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAdjustmentShuruq];
}

- (void)setShuruqAdjustment:(NSInteger)shuruqAdjustment
{
    [[NSUserDefaults standardUserDefaults] setInteger:shuruqAdjustment forKey:kBAUserDefaultsAdjustmentShuruq];
    [self synchronize];
}


/* dhuhrAdjustment */
- (NSInteger)dhuhrAdjustment
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAdjustmentDhuhr];
}

- (void)setDhuhrAdjustment:(NSInteger)dhuhrAdjustment
{
    [[NSUserDefaults standardUserDefaults] setInteger:dhuhrAdjustment forKey:kBAUserDefaultsAdjustmentDhuhr];
    [self synchronize];
}


/* asrAdjustment */
- (NSInteger)asrAdjustment
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAdjustmentAsr];
}

- (void)setAsrAdjustment:(NSInteger)asrAdjustment
{
    [[NSUserDefaults standardUserDefaults] setInteger:asrAdjustment forKey:kBAUserDefaultsAdjustmentAsr];
    [self synchronize];
}


/* maghribAdjustment */
- (NSInteger)maghribAdjustment
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAdjustmentMaghrib];
}

- (void)setMaghribAdjustment:(NSInteger)maghribAdjustment
{
    [[NSUserDefaults standardUserDefaults] setInteger:maghribAdjustment forKey:kBAUserDefaultsAdjustmentMaghrib];
    [self synchronize];
}


/* ishaAdjustment */
- (NSInteger)ishaAdjustment
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAdjustmentIsha];
}

- (void)setIshaAdjustment:(NSInteger)ishaAdjustment
{
    [[NSUserDefaults standardUserDefaults] setInteger:ishaAdjustment forKey:kBAUserDefaultsAdjustmentIsha];
    [self synchronize];
}


/* fajrReminderAlertEnabled */
- (BOOL)fajrReminderAlertEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsAlertFajrReminderEnabled];
}

- (void)setFajrReminderAlertEnabled:(BOOL)fajrReminderAlertEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:fajrReminderAlertEnabled forKey:kBAUserDefaultsAlertFajrReminderEnabled];
    [self synchronize];
}


/* fajrAlertEnabled */
- (BOOL)fajrAlertEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsAlertFajrEnabled];
}

- (void)setFajrAlertEnabled:(BOOL)fajrAlertEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:fajrAlertEnabled forKey:kBAUserDefaultsAlertFajrEnabled];
    [self synchronize];
}


/* shuruqReminderAlertEnabled */
- (BOOL)shuruqReminderAlertEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsAlertShuruqReminderEnabled];
}

- (void)setShuruqReminderAlertEnabled:(BOOL)shuruqReminderAlertEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:shuruqReminderAlertEnabled forKey:kBAUserDefaultsAlertShuruqReminderEnabled];
    [self synchronize];
}


/* dhuhrAlertEnabled */
- (BOOL)dhuhrAlertEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsAlertDhuhrEnabled];
}

- (void)setDhuhrAlertEnabled:(BOOL)dhuhrAlertEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:dhuhrAlertEnabled forKey:kBAUserDefaultsAlertDhuhrEnabled];
    [self synchronize];
}


/* asrAlertEnabled */
- (BOOL)asrAlertEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsAlertAsrEnabled];
}

- (void)setAsrAlertEnabled:(BOOL)asrAlertEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:asrAlertEnabled forKey:kBAUserDefaultsAlertAsrEnabled];
    [self synchronize];
}


/* maghribAlertEnabled */
- (BOOL)maghribAlertEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsAlertMaghribEnabled];
}

- (void)setMaghribAlertEnabled:(BOOL)maghribAlertEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:maghribAlertEnabled forKey:kBAUserDefaultsAlertMaghribEnabled];
    [self synchronize];
}


/* ishaAlertEnabled */
- (BOOL)ishaAlertEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsAlertIshaEnabled];
}

- (void)setIshaAlertEnabled:(BOOL)ishaAlertEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:ishaAlertEnabled forKey:kBAUserDefaultsAlertIshaEnabled];
    [self synchronize];
}


/* fajrAdhan */
- (NSInteger)fajrAdhan
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAlertFajrSound];
}

- (void)setFajrAdhan:(NSInteger)fajrAdhan
{
    [[NSUserDefaults standardUserDefaults] setInteger:fajrAdhan forKey:kBAUserDefaultsAlertFajrSound];
    [self synchronize];
}


/* dhuhrAdhan */
- (NSInteger)dhuhrAdhan
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAlertDhuhrSound];
}

- (void)setDhuhrAdhan:(NSInteger)dhuhrAdhan
{
    [[NSUserDefaults standardUserDefaults] setInteger:dhuhrAdhan forKey:kBAUserDefaultsAlertDhuhrSound];
    [self synchronize];
}


/* asrAdhan */
- (NSInteger)asrAdhan
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAlertAsrSound];
}

- (void)setAsrAdhan:(NSInteger)asrAdhan
{
    [[NSUserDefaults standardUserDefaults] setInteger:asrAdhan forKey:kBAUserDefaultsAlertAsrSound];
    [self synchronize];
}


/* maghribAdhan */
- (NSInteger)maghribAdhan
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAlertMaghribSound];
}

- (void)setMaghribAdhan:(NSInteger)maghribAdhan
{
    [[NSUserDefaults standardUserDefaults] setInteger:maghribAdhan forKey:kBAUserDefaultsAlertMaghribSound];
    [self synchronize];
}


/* ishaAdhan */
- (NSInteger)ishaAdhan
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAlertIshaSound];
}

- (void)setIshaAdhan:(NSInteger)ishaAdhan
{
    [[NSUserDefaults standardUserDefaults] setInteger:ishaAdhan forKey:kBAUserDefaultsAlertIshaSound];
    [self synchronize];
}


/* fajrCustomAdhan */
- (NSData *)fajrCustomAdhan
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:kBAUserDefaultsAlertFajrCustomSound];
}

- (void)setFajrCustomAdhan:(NSData *)fajrCustomAdhan
{
    [[NSUserDefaults standardUserDefaults] setObject:fajrCustomAdhan forKey:kBAUserDefaultsAlertFajrCustomSound];
    [self synchronize];
}


/* dhuhrCustomAdhan */
- (NSData *)dhuhrCustomAdhan
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:kBAUserDefaultsAlertDhuhrCustomSound];
}

- (void)setDhuhrCustomAdhan:(NSData *)dhuhrCustomAdhan
{
    [[NSUserDefaults standardUserDefaults] setObject:dhuhrCustomAdhan forKey:kBAUserDefaultsAlertDhuhrCustomSound];
    [self synchronize];
}


/* asrCustomAdhan */
- (NSData *)asrCustomAdhan
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:kBAUserDefaultsAlertAsrCustomSound];
}

- (void)setAsrCustomAdhan:(NSData *)asrCustomAdhan
{
    [[NSUserDefaults standardUserDefaults] setObject:asrCustomAdhan forKey:kBAUserDefaultsAlertAsrCustomSound];
    [self synchronize];
}


/* maghribCustomAdhan */
- (NSData *)maghribCustomAdhan
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:kBAUserDefaultsAlertMaghribCustomSound];
}

- (void)setMaghribCustomAdhan:(NSData *)maghribCustomAdhan
{
    [[NSUserDefaults standardUserDefaults] setObject:maghribCustomAdhan forKey:kBAUserDefaultsAlertMaghribCustomSound];
    [self synchronize];
}


/* ishaCustomAdhan */
- (NSData *)ishaCustomAdhan
{
    return [[NSUserDefaults standardUserDefaults] dataForKey:kBAUserDefaultsAlertIshaCustomSound];
}

- (void)setIshaCustomAdhan:(NSData *)ishaCustomAdhan
{
    [[NSUserDefaults standardUserDefaults] setObject:ishaCustomAdhan forKey:kBAUserDefaultsAlertIshaCustomSound];
    [self synchronize];
}


/* alertVolume */
- (NSInteger)alertVolume
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAlertVolume];
}

- (void)setAlertVolume:(NSInteger)alertVolume
{
    [[NSUserDefaults standardUserDefaults] setInteger:alertVolume forKey:kBAUserDefaultsAlertVolume];
    [self synchronize];
}


/* duaEnabled */
- (BOOL)duaEnabled
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsDua];
}

- (void)setDuaEnabled:(BOOL)duaEnabled
{
    [[NSUserDefaults standardUserDefaults] setBool:duaEnabled forKey:kBAUserDefaultsDua];
    [self synchronize];
}


/* silentMode */
- (BOOL)silentMode
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsSilentMode];
}

- (void)setSilentMode:(BOOL)silentMode
{
    [[NSUserDefaults standardUserDefaults] setBool:silentMode forKey:kBAUserDefaultsSilentMode];
    [self synchronize];
}


/* fajrReminderOffset */
- (NSInteger)fajrReminderOffset
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAlertFajrReminderOffset];
}

- (void)setFajrReminderOffset:(NSInteger)fajrReminderOffset
{
    [[NSUserDefaults standardUserDefaults] setInteger:fajrReminderOffset forKey:kBAUserDefaultsAlertFajrReminderOffset];
    [self synchronize];
}


/* shuruqReminderOffset */
- (NSInteger)shuruqReminderOffset
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsAlertShuruqReminderOffset];
}

- (void)setShuruqReminderOffset:(NSInteger)shuruqReminderOffset
{
    [[NSUserDefaults standardUserDefaults] setInteger:shuruqReminderOffset forKey:kBAUserDefaultsAlertShuruqReminderOffset];
    [self synchronize];
}


/* hijriOffset */
- (NSInteger)hijriOffset
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:kBAUserDefaultsHijriOffset];
}

- (void)setHijriOffset:(NSInteger)hijriOffset
{
    [[NSUserDefaults standardUserDefaults] setInteger:hijriOffset forKey:kBAUserDefaultsHijriOffset];
    [self synchronize];
}

/* delayedIshaInRamadan */

- (BOOL)delayedIshaInRamadan
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:kBAUserDefaultsDelayedIshaInRamadan];
}

- (void)setDelayedIshaInRamadan:(BOOL)delayedIshaInRamadan
{
    [[NSUserDefaults standardUserDefaults] setBool:delayedIshaInRamadan forKey:kBAUserDefaultsDelayedIshaInRamadan];
    [self synchronize];
}

@end
