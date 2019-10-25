//
//  BAAppDelegate.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 6/24/13.
//  Copyright (c) 2013 Batoul Apps. All rights reserved.
//

#import "BAAppDelegate.h"

#import "BAPrayerWindow.h"
#import "BABackgroundView.h"
#import "BASnapshotView.h"
#import "BAVerticallyCenteredTextFieldCell.h"

#import "BALocationManager.h"
#import "BAPreferences.h"

#import "MASPreferencesWindowController.h"
#import "BAGeneralPrefsViewController.h"
#import "BALocationPrefsViewController.h"
#import "BACalculationPrefsViewController.h"
#import "BANotificationPrefsViewController.h"
#import "BAAdvancedPrefsViewController.h"
#import "BALocalizer.h"
#import "BAConstants.h"

#import "Adhan-Swift.h"
#import "BAPrayerAlert.h"

#import "NSAttributedString+Guidance.h"
#import "NSColor+Guidance.h"
#import "NSSound+Guidance.h"

#import <Quartz/Quartz.h>
#import <tgmath.h>

#import "Guidance-Swift.h"

@interface BAAppDelegate ()

@property (strong, nonatomic) NSStatusItem *statusItem;

@property (weak, nonatomic) IBOutlet BAPrayerWindow *window;
@property (weak, nonatomic) IBOutlet BABackgroundView *backgroundView;
@property (weak, nonatomic) IBOutlet BASnapshotView *snapshotView;
@property (weak, nonatomic) IBOutlet NSImageView *statusView;

@property (weak, nonatomic) IBOutlet NSButton *settingsButton;
@property (weak, nonatomic) IBOutlet NSImageView *prayerHighlight;

@property (weak, nonatomic) IBOutlet NSTextField *dateLabel;
@property (weak, nonatomic) IBOutlet NSTextField *monthLabel;
@property (weak, nonatomic) IBOutlet NSTextField *yearLabel;

@property (weak, nonatomic) IBOutlet NSTextField *fajrLabel;
@property (weak, nonatomic) IBOutlet NSTextField *fajrTimeLabel;
@property (weak, nonatomic) IBOutlet NSTextField *shuruqLabel;
@property (weak, nonatomic) IBOutlet NSTextField *shuruqTimeLabel;
@property (weak, nonatomic) IBOutlet NSTextField *dhuhrLabel;
@property (weak, nonatomic) IBOutlet NSTextField *dhuhrTimeLabel;
@property (weak, nonatomic) IBOutlet NSTextField *asrLabel;
@property (weak, nonatomic) IBOutlet NSTextField *asrTimeLabel;
@property (weak, nonatomic) IBOutlet NSTextField *maghribLabel;
@property (weak, nonatomic) IBOutlet NSTextField *maghribTimeLabel;
@property (weak, nonatomic) IBOutlet NSTextField *ishaLabel;
@property (weak, nonatomic) IBOutlet NSTextField *ishaTimeLabel;

@property (weak, nonatomic) IBOutlet NSButton *fajrButton;
@property (weak, nonatomic) IBOutlet NSButton *shuruqButton;
@property (weak, nonatomic) IBOutlet NSButton *dhuhrButton;
@property (weak, nonatomic) IBOutlet NSButton *asrButton;
@property (weak, nonatomic) IBOutlet NSButton *maghribButton;
@property (weak, nonatomic) IBOutlet NSButton *ishaButton;

@property (weak, nonatomic) IBOutlet NSTextField *cityLabel;

@property (strong, nonatomic) NSWindowController *preferencesWindowController;
@property (strong, nonatomic) NSMenu *settingsMenu;

@property (strong, nonatomic) BAPrayerTimes *prayerTimes;
@property (strong, nonatomic) BAPrayerTimes *tomorrowPrayerTimes;
@property (assign, nonatomic) BAPrayer currentPrayer;
@property (assign, nonatomic) BAPrayer nextPrayer;

@property (strong, nonatomic) NSMutableArray *pendingAlerts;

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSSound *sound;

@property (strong, nonatomic) NSDateComponents *currentDay;

- (IBAction)showSettingsMenu:(id)sender;
- (IBAction)openPrefs:(id)sender;
- (IBAction)openHelp:(id)sender;
- (IBAction)openAboutWindow:(id)sender;

- (IBAction)toggleFajrAdhan:(id)sender;
- (IBAction)toggleShuruqAdhan:(id)sender;
- (IBAction)toggleDhuhrAdhan:(id)sender;
- (IBAction)toggleAsrAdhan:(id)sender;
- (IBAction)toggleMaghribAdhan:(id)sender;
- (IBAction)toggleIshaAdhan:(id)sender;

@end


//static CGFloat const kBAPanelOpenDuration = 0.15;
static CGFloat const kBAPanelCloseDuration = 0.10;


@implementation BAAppDelegate


#pragma mark - App Life Cycle

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.currentDay = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:[NSDate date]];
    
	// Register user defaults
    [[BAPreferences sharedPreferences] registerDefaults];
    [self migratePreferences];
	
	// setup status bar item
	self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
	[self.statusItem setHighlightMode:NO];
	[self.statusItem setTitle:@""];
	[self.statusItem setAction:@selector(togglePrayerTimes)];
	[self.statusItem setTarget:self];
    [self.statusItem sendActionOn:NSLeftMouseDownMask];
    
    if ([[BAPreferences sharedPreferences] displayIcon]) {
        NSImage *image = [NSImage imageNamed:@"menuBar"];
        [image setTemplate:YES];
        [self.statusItem setImage:image];
    } else {
        [self.statusItem setImage:nil];
    }
	
	// setup window
	[self.window setLevel:NSModalPanelWindowLevel];
	[self.window setDelegate:self];
	[self.window setOpaque:NO];
	[self.window setCollectionBehavior: NSWindowCollectionBehaviorCanJoinAllSpaces];
	[self.window setBackgroundColor:[NSColor clearColor]];
	[self.window setAlphaValue:0.0];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:[Localizer languageDidChangeNotification] object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userDefaultsDidChange:) name:kBAUserDefaultsDidChangeNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationDidUpdate:) name:kLocationDidUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationDidUpdate:) name:kLocationDidFailNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(significantTimeChange:) name:NSSystemTimeZoneDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(significantTimeChange:) name:NSSystemClockDidChangeNotification object:nil];
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(significantTimeChange:) name:NSWorkspaceDidWakeNotification object:nil];

    // register Guidance with the notification center
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];

	[self calculatePrayerTimes];
	[self checkPrayertimes];
	[self updateDate];
    
    self.cityLabel.stringValue = [[BAPreferences sharedPreferences] city];
    [self.statusView setImage:[NSImage imageNamed:@"highlight-blue"]];
    
    self.timer = [[NSTimer alloc] initWithFireDate:[NSDate date] interval:60.0 target:self selector:@selector(handleTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSDefaultRunLoopMode];
    
    [[BAPreferences sharedPreferences] updatePreferences];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([[BAPreferences sharedPreferences] useCurrentLocation]) {
            [[[BALocationManager defaultManager] locationManager] startUpdatingLocation];
            [[[BALocationManager defaultManager] locationManager] startMonitoringSignificantLocationChanges];
        }
    });
}

- (void)migratePreferences
{
    if ([[[BAPreferences sharedPreferences] version] compare:@"2.0.2" options:NSNumericSearch] == NSOrderedAscending) {
        if ([[BAPreferences sharedPreferences] method] == BAMethodPreferenceGulf) {
            [[BAPreferences sharedPreferences] setMethod:BAMethodPreferenceCustom];
        }
    }
    
    [[BAPreferences sharedPreferences] setVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
}

#pragma mark - Prayer time checking

- (void)handleTimer:(NSTimer *)timer
{
    NSDateComponents *date = [[NSCalendar currentCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:[NSDate date]];
    if (date.day != self.currentDay.day || date.month != self.currentDay.month || date.year != self.currentDay.year) {
        self.currentDay = date;
        [self calculatePrayerTimes];
        [self updateDate];
    }
    
    [self checkPrayertimes];
    
    double integer;
    double fraction = modf([NSDate timeIntervalSinceReferenceDate] / 60.0, &integer);
    
    NSTimeInterval currentSecond = fraction * 60.0;
    NSTimeInterval delta = 60.5 - currentSecond;
    self.timer.fireDate = [[NSDate date] dateByAddingTimeInterval:delta];
}


- (void)userDefaultsDidChange:(NSNotification *)notification
{
	[self calculatePrayerTimes];
	[self checkPrayertimes];
	[self updateDate];
    self.cityLabel.stringValue = [[BAPreferences sharedPreferences] city];
}


- (void)significantTimeChange:(NSNotification *)notification
{
    [self handleTimer:nil];
}


- (void)checkPrayertimes
{
    self.currentPrayer = [self.prayerTimes currentPrayer:[NSDate date]];
    self.nextPrayer = [self.prayerTimes nextPrayer:[NSDate date]];
    
    NSArray *alerts = [self.pendingAlerts copy];
    [alerts enumerateObjectsUsingBlock:^(BAPrayerAlert *alert, NSUInteger idx, BOOL *stop) {
        
        NSDate *alertTime = alert.time;
        
        // 1 second leeway in case the timer is off
        if ([alertTime timeIntervalSinceNow] <= 1 && [alertTime timeIntervalSinceNow] > -60) {
            [self.pendingAlerts removeObject:alert];
            [self displayAlert:alert];
        }
    }];
    
    [self updatePrayerTimeDisplay];
}


- (void)calculatePrayerTimes
{
    // get date components
    NSDate *today = [NSDate date];
    NSDate *tomorrow = [[Formatter gregorianCalendar] dateByAddingUnit:NSCalendarUnitDay value:1 toDate:today options:0];
    NSDateComponents *todayComponents = [[Formatter gregorianCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:today];
    NSDateComponents *tomorrowComponents = [[Formatter gregorianCalendar] components:NSCalendarUnitDay|NSCalendarUnitMonth|NSCalendarUnitYear fromDate:tomorrow];
    
    // compose preferences to calculation parameters
    BACalculationMethod method = [BAPreferences calculationMethodForPreference:[[BAPreferences sharedPreferences] method]];
    BACalculationParameters *params = [[BACalculationParameters alloc] initWithMethod:method];
    if (params.method == BACalculationMethodOther) {
        params.fajrAngle = [[BAPreferences sharedPreferences] customFajrAngle];
        params.ishaAngle = [[BAPreferences sharedPreferences] customIshaAngle];
    }
    params.madhab = [BAPreferences madhabForPreference:[[BAPreferences sharedPreferences] madhab]];
    params.highLatitudeRule = [[BAPreferences sharedPreferences] highLatitudeRule];
    BAPrayerAdjustments *adjustments = [[BAPrayerAdjustments alloc] initWithFajr:[[BAPreferences sharedPreferences] fajrAdjustment]
                                                                         sunrise:[[BAPreferences sharedPreferences] shuruqAdjustment]
                                                                           dhuhr:[[BAPreferences sharedPreferences] dhuhrAdjustment]
                                                                             asr:[[BAPreferences sharedPreferences] asrAdjustment]
                                                                         maghrib:[[BAPreferences sharedPreferences] maghribAdjustment]
                                                                            isha:[[BAPreferences sharedPreferences] ishaAdjustment]];
    params.adjustments = adjustments;
    if (params.ishaInterval > 0 && [[BAPreferences sharedPreferences] delayedIshaInRamadan]) {
        NSDate *hijriDate = [BALocalizer adjustedHijriDateForDate:today];
        NSDateComponents *components = [[Formatter hijriCalendar] components:NSCalendarUnitMonth fromDate:hijriDate];
        if (components.month == 9) {
            params.ishaInterval = 120;
        }
    }
    
    BACoordinates *coordinates = [[BACoordinates alloc] initWithLatitude:[[BAPreferences sharedPreferences] latitude] longitude:[[BAPreferences sharedPreferences] longitude]];
    
    self.prayerTimes = [[BAPrayerTimes alloc] initWithCoordinates:coordinates date:todayComponents calculationParameters:params];
    self.tomorrowPrayerTimes = [[BAPrayerTimes alloc] initWithCoordinates:coordinates date:tomorrowComponents calculationParameters:params];
    [self updatePendingAlerts];
}

- (void)updatePendingAlerts
{
	NSDate *fajrTime = self.prayerTimes.fajr;
	NSDate *sunriseTime = self.prayerTimes.sunrise;
	NSDate *dhuhrTime = self.prayerTimes.dhuhr;
	NSDate *asrTime = self.prayerTimes.asr;
	NSDate *maghribTime = self.prayerTimes.maghrib;
	NSDate *ishaTime = self.prayerTimes.isha;
    
    NSDate *fajrReminderTime = [fajrTime dateByAddingTimeInterval:-60.0 * [[BAPreferences sharedPreferences] fajrReminderOffset]];
    
    NSDate *shuruqReminderTime = [sunriseTime dateByAddingTimeInterval:-60.0 * [[BAPreferences sharedPreferences] shuruqReminderOffset]];
    
    [self.pendingAlerts removeAllObjects];
    
    if ([fajrTime timeIntervalSinceNow] > 0) {
        
        BAPrayerAlert *alert = [[BAPrayerAlert alloc] init];
        alert.time = fajrTime;
        alert.prayerType = BAPrayerFajr;
        alert.playAudio = [[BAPreferences sharedPreferences] fajrAlertEnabled];
        alert.audioFile = [BAPreferences fileForAdhan:[[BAPreferences sharedPreferences] fajrAdhan] customAdhan:[[BAPreferences sharedPreferences] fajrCustomAdhan]];
        alert.title = BALocalizedString(@"Fajr");
        alert.message = [NSString stringWithFormat:BALocalizedString(@"It's time for %@ (%@)"),
                         BALocalizedString(@"Fajr"),
                         [Formatter formattedTimeWithDate:fajrTime]];
        
        [self.pendingAlerts addObject:alert];
    }
    
    if ([dhuhrTime timeIntervalSinceNow] > 0) {

        BAPrayerAlert *alert = [[BAPrayerAlert alloc] init];
        alert.time = dhuhrTime;
        alert.prayerType = BAPrayerDhuhr;
        alert.playAudio = [[BAPreferences sharedPreferences] dhuhrAlertEnabled];
        alert.audioFile = [BAPreferences fileForAdhan:[[BAPreferences sharedPreferences] dhuhrAdhan] customAdhan:[[BAPreferences sharedPreferences] dhuhrCustomAdhan]];
        alert.title = [BALocalizer localizedDhuhr];
        alert.message = [NSString stringWithFormat:BALocalizedString(@"It's time for %@ (%@)"),
                         [BALocalizer localizedDhuhr],
                         [Formatter formattedTimeWithDate:dhuhrTime]];

        
        [self.pendingAlerts addObject:alert];
    }
    
    if ([asrTime timeIntervalSinceNow] > 0) {

        BAPrayerAlert *alert = [[BAPrayerAlert alloc] init];
        alert.time = asrTime;
        alert.prayerType = BAPrayerAsr;
        alert.playAudio = [[BAPreferences sharedPreferences] asrAlertEnabled];
        alert.audioFile = [BAPreferences fileForAdhan:[[BAPreferences sharedPreferences] asrAdhan] customAdhan:[[BAPreferences sharedPreferences] asrCustomAdhan]];
        alert.title = BALocalizedString(@"Asr");
        alert.message = [NSString stringWithFormat:BALocalizedString(@"It's time for %@ (%@)"),
                         BALocalizedString(@"Asr"),
                         [Formatter formattedTimeWithDate:asrTime]];

        
        [self.pendingAlerts addObject:alert];
    }
    
    if ([maghribTime timeIntervalSinceNow] > 0) {

        BAPrayerAlert *alert = [[BAPrayerAlert alloc] init];
        alert.time = maghribTime;
        alert.prayerType = BAPrayerMaghrib;
        alert.playAudio = [[BAPreferences sharedPreferences] maghribAlertEnabled];
        alert.audioFile = [BAPreferences fileForAdhan:[[BAPreferences sharedPreferences] maghribAdhan] customAdhan:[[BAPreferences sharedPreferences] maghribCustomAdhan]];
        alert.title = BALocalizedString(@"Maghrib");
        alert.message = [NSString stringWithFormat:BALocalizedString(@"It's time for %@ (%@)"),
                         BALocalizedString(@"Maghrib"),
                         [Formatter formattedTimeWithDate:maghribTime]];
        
        [self.pendingAlerts addObject:alert];
    }
    
    if ([ishaTime timeIntervalSinceNow] > 0) {

        BAPrayerAlert *alert = [[BAPrayerAlert alloc] init];
        alert.time = ishaTime;
        alert.prayerType = BAPrayerIsha;
        alert.playAudio = [[BAPreferences sharedPreferences] ishaAlertEnabled];
        alert.audioFile = [BAPreferences fileForAdhan:[[BAPreferences sharedPreferences] ishaAdhan] customAdhan:[[BAPreferences sharedPreferences] ishaCustomAdhan]];
        alert.title = BALocalizedString(@"Isha");
        alert.message = [NSString stringWithFormat:BALocalizedString(@"It's time for %@ (%@)"),
                         BALocalizedString(@"Isha"),
                         [Formatter formattedTimeWithDate:ishaTime]];
        
        [self.pendingAlerts addObject:alert];
    }
    
    if ([[BAPreferences sharedPreferences] fajrReminderAlertEnabled] && [fajrReminderTime timeIntervalSinceNow] > 0) {
        
        BAPrayerAlert *alert = [[BAPrayerAlert alloc] init];
        alert.time = fajrReminderTime;
        alert.prayerType = BAPrayerFajr;
        alert.playAudio = YES;
        alert.audioFile = [BAPreferences fileForAdhan:[[BAPreferences sharedPreferences] fajrAdhan] customAdhan:[[BAPreferences sharedPreferences] fajrCustomAdhan]];
        alert.title = BALocalizedString(@"Fajr");
        alert.message = [NSString stringWithFormat:BALocalizedString(@"Fajr is in %@ minutes"),
                         [Formatter formattedIntegerWithInt:[[BAPreferences sharedPreferences] fajrReminderOffset]]];
        
        [self.pendingAlerts addObject:alert];
    }
    
    if ([[BAPreferences sharedPreferences] shuruqReminderAlertEnabled] && [shuruqReminderTime timeIntervalSinceNow] > 0) {

        BAPrayerAlert *alert = [[BAPrayerAlert alloc] init];
        alert.time = shuruqReminderTime;
        alert.prayerType = BAPrayerSunrise;
        alert.playAudio = YES;
        alert.audioFile = [BAPreferences fileForAdhan:[[BAPreferences sharedPreferences] fajrAdhan] customAdhan:[[BAPreferences sharedPreferences] fajrCustomAdhan]];
        alert.title = BALocalizedString(@"Sunrise");
        alert.message = [NSString stringWithFormat:BALocalizedString(@"Sunrise is in %@ minutes"),
                         [Formatter formattedIntegerWithInt:[[BAPreferences sharedPreferences] shuruqReminderOffset]]];
        
        [self.pendingAlerts addObject:alert];
    }
}


- (void)displayAlert:(BAPrayerAlert *)alert
{
    [[NSUserNotificationCenter defaultUserNotificationCenter] removeAllDeliveredNotifications];
    
	NSUserNotification *notification = [[NSUserNotification alloc] init];
	[notification setTitle:alert.title];
	[notification setInformativeText:alert.message];
	NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
	[center setDelegate:self];
	[center scheduleNotification:notification];
    
    if (alert.playAudio && [[BAPreferences sharedPreferences] silentMode] == NO) {
        
        NSURL *scriptURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"pauseItunes" ofType:@"scpt"]];
        NSDictionary *errors = [NSDictionary dictionary];
        NSAppleScript *pauseItunesScript = [[NSAppleScript alloc] initWithContentsOfURL:scriptURL error:&errors];
        [pauseItunesScript executeAndReturnError:&errors];
        
        self.sound.prayerAlertInfo = nil;
        self.sound = nil;
        
        [alert.audioFile startAccessingSecurityScopedResource];
        NSData *audioData = [NSData dataWithContentsOfURL:alert.audioFile];
        [alert.audioFile stopAccessingSecurityScopedResource];
        
        self.sound = [[NSSound alloc] initWithData:audioData];
        self.sound.delegate = self;
        self.sound.volume = [[BAPreferences sharedPreferences] alertVolume] / 100.0;
        self.sound.prayerAlertInfo = @{kBAPrayerAlertInfoKeyPrayer: @(alert.prayerType), kBAPrayerAlertInfoKeyAdhan: @YES};
        [self.sound play];
    }
    
    [self updatePrayerTimeDisplay];
}


#pragma mark - Display

- (void)updatePrayerTimeDisplay
{
    [self.statusView setAlphaValue:0.0];
    
    BOOL audioPlaying = NO;
    BAPrayer audioPrayer = BAPrayerNone;
    
    if (self.sound && [self.sound isPlaying]) {
        NSDictionary *prayerAlertInfo = self.sound.prayerAlertInfo;
        
        audioPlaying = YES;
        audioPrayer = [prayerAlertInfo[kBAPrayerAlertInfoKeyPrayer] integerValue];
    }
    
    //set to green if audio playing
    if (audioPlaying && audioPrayer == self.currentPrayer) {
        [self.statusView setImage:[NSImage imageNamed:@"highlight-green"]];
    } else {
        [self.statusView setImage:[NSImage imageNamed:@"highlight-blue"]];
    }
    
	[self stylePrayerNameLabel:self.fajrLabel forName:BALocalizedString(@"Fajr") highlighted:(self.currentPrayer == BAPrayerFajr)];
	[self stylePrayerNameLabel:self.shuruqLabel forName:BALocalizedString(@"Sunrise") highlighted:NO];
	[self stylePrayerNameLabel:self.dhuhrLabel forName:[BALocalizer localizedDhuhr] highlighted:(self.currentPrayer == BAPrayerDhuhr)];
	[self stylePrayerNameLabel:self.asrLabel forName:BALocalizedString(@"Asr") highlighted:(self.currentPrayer == BAPrayerAsr)];
	[self stylePrayerNameLabel:self.maghribLabel forName:BALocalizedString(@"Maghrib") highlighted:(self.currentPrayer == BAPrayerMaghrib)];
	[self stylePrayerNameLabel:self.ishaLabel forName:BALocalizedString(@"Isha") highlighted:(self.currentPrayer == BAPrayerIsha)];
	
	[self stylePrayerTimeLabel:self.fajrTimeLabel forTime:self.prayerTimes.fajr highlighted:(self.currentPrayer == BAPrayerFajr)];
	[self stylePrayerTimeLabel:self.shuruqTimeLabel forTime:self.prayerTimes.sunrise highlighted:NO];
	[self stylePrayerTimeLabel:self.dhuhrTimeLabel forTime:self.prayerTimes.dhuhr highlighted:(self.currentPrayer == BAPrayerDhuhr)];
	[self stylePrayerTimeLabel:self.asrTimeLabel forTime:self.prayerTimes.asr highlighted:(self.currentPrayer == BAPrayerAsr)];
	[self stylePrayerTimeLabel:self.maghribTimeLabel forTime:self.prayerTimes.maghrib highlighted:(self.currentPrayer == BAPrayerMaghrib)];
	[self stylePrayerTimeLabel:self.ishaTimeLabel forTime:self.prayerTimes.isha highlighted:(self.currentPrayer == BAPrayerIsha)];
	
	[self updateStatusBar];
    
    [self updateAdhanButtonsForAudioPrayer:audioPrayer];
}


- (void)updateStatusBar
{
    if ([[BAPreferences sharedPreferences] displayIcon]) {
        NSImage *image = [NSImage imageNamed:@"menuBar"];
        [image setTemplate:YES];
        [self.statusItem setImage:image];
    } else {
        [self.statusItem setImage:nil];
    }
    
	if([[BAPreferences sharedPreferences] displayNextPrayer]) {
        
        NSString *nextPrayerName;
        NSString *nextPrayerAbbreviation;
        NSDate *nextPrayerTime;
        
        switch (self.nextPrayer) {
            case BAPrayerFajr:
                nextPrayerName = BALocalizedString(@"Fajr");
                nextPrayerAbbreviation = BALocalizedString(@"F");
                nextPrayerTime = self.prayerTimes.fajr;
                break;
            case BAPrayerSunrise:
                nextPrayerName = BALocalizedString(@"Sunrise");
                nextPrayerAbbreviation = BALocalizedString(@"S");
                nextPrayerTime = self.prayerTimes.sunrise;
                break;
            case BAPrayerDhuhr:
                nextPrayerName = [BALocalizer localizedDhuhr];
                nextPrayerAbbreviation = [BALocalizer localizedDhuhrAbbreviation];
                nextPrayerTime = self.prayerTimes.dhuhr;
                break;
            case BAPrayerAsr:
                nextPrayerName = BALocalizedString(@"Asr");
                nextPrayerAbbreviation = BALocalizedString(@"A");
                nextPrayerTime = self.prayerTimes.asr;
                break;
            case BAPrayerMaghrib:
                nextPrayerName = BALocalizedString(@"Maghrib");
                nextPrayerAbbreviation = BALocalizedString(@"M");
                nextPrayerTime = self.prayerTimes.maghrib;
                break;
            case BAPrayerIsha:
                nextPrayerName = BALocalizedString(@"Isha");
                nextPrayerAbbreviation = BALocalizedString(@"I");
                nextPrayerTime = self.prayerTimes.isha;
                break;
            case BAPrayerNone:
                nextPrayerName = BALocalizedString(@"Fajr");
                nextPrayerAbbreviation = BALocalizedString(@"F");
                nextPrayerTime = self.tomorrowPrayerTimes.fajr;
                break;
        }
        
        NSDateComponents *components = [[Formatter gregorianCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate date] toDate:nextPrayerTime options:0];
        components.minute += 1;
        if (components.minute >= 60) {
            components.minute -= 60;
            components.hour += 1;
        }
        
        NSString *nameComponent = @"";
        
        if ([[BAPreferences sharedPreferences] nextPrayerDisplayName] == BANextPrayerDisplayNameFull) {
            nameComponent = nextPrayerName;
        } else if ([[BAPreferences sharedPreferences] nextPrayerDisplayName] == BANextPrayerDisplayNameAbbreviation) {
            nameComponent = nextPrayerAbbreviation;
        }

        NSString *timeComponent = @"";
        
		if ([[BAPreferences sharedPreferences] nextPrayerDisplayType] == BANextPrayerDisplayTypeTimeUntilNextPrayer) {
            
            NSString *minuteString = [Formatter formattedIntegerWithInt:components.minute];
            if (minuteString.length == 1) {
                minuteString = [NSString stringWithFormat:@"%@%@",[Formatter formattedIntegerWithInt:0],minuteString];
            }
            
            timeComponent = [NSString stringWithFormat:@"-%@:%@", [Formatter formattedIntegerWithInt:components.hour], minuteString];

		} else if ([[BAPreferences sharedPreferences] nextPrayerDisplayType] == BANextPrayerDisplayTypeTimeOfNextPrayer) {
            timeComponent = [Formatter formattedTimeWithDate:nextPrayerTime];
            NSString *amPmString = [Formatter formattedPeriodWithDate:nextPrayerTime];
            timeComponent = [timeComponent stringByReplacingOccurrencesOfString:amPmString withString:@""];
            timeComponent = [timeComponent stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		}
        
        NSString *title;
        if (nameComponent.length > 0 && timeComponent.length > 0) {
            title = [NSString stringWithFormat:@"%@ %@", nameComponent, timeComponent];
        } else {
            title = [NSString stringWithFormat:@"%@%@", nameComponent, timeComponent];
        }

        NSMutableAttributedString *attrTitle = [[NSMutableAttributedString alloc] initWithString:title];
        [attrTitle addAttribute:NSFontAttributeName value:[NSFont menuBarFontOfSize:0.0] range:NSMakeRange(0, attrTitle.string.length)];
        
        if (self.sound && [self.sound isPlaying]) {
            [attrTitle addAttribute:NSForegroundColorAttributeName value:[NSColor ba_menuBarGreen] range:NSMakeRange(0, attrTitle.string.length)];
            [self.statusItem setAttributedTitle:attrTitle];
        } else if (components.minute <= 15 && components.hour == 0) {
            [attrTitle addAttribute:NSForegroundColorAttributeName value:[NSColor ba_menuBarRed] range:NSMakeRange(0, attrTitle.string.length)];
            [self.statusItem setAttributedTitle:attrTitle];
        } else {
            [self.statusItem setAttributedTitle:attrTitle];
        }
	} else {
		[self.statusItem setTitle:@""];
	}
}


- (void)updateAdhanButtonsForAudioPrayer:(BAPrayer)audioPrayer
{
    [self setImageForAdhanButton:self.fajrButton
                         enabled:[[BAPreferences sharedPreferences] fajrAlertEnabled]
                     highlighted:(self.currentPrayer == BAPrayerFajr)
                           pause:(audioPrayer == BAPrayerFajr)];
    
    [self setImageForAdhanButton:self.shuruqButton
                         enabled:[[BAPreferences sharedPreferences] shuruqReminderAlertEnabled]
                     highlighted:NO
                           pause:(audioPrayer == BAPrayerSunrise)];
    
    [self setImageForAdhanButton:self.dhuhrButton
                         enabled:[[BAPreferences sharedPreferences] dhuhrAlertEnabled]
                     highlighted:(self.currentPrayer == BAPrayerDhuhr)
                           pause:(audioPrayer == BAPrayerDhuhr)];
    
    [self setImageForAdhanButton:self.asrButton
                         enabled:[[BAPreferences sharedPreferences] asrAlertEnabled]
                     highlighted:(self.currentPrayer == BAPrayerAsr)
                           pause:(audioPrayer == BAPrayerAsr)];
    
    [self setImageForAdhanButton:self.maghribButton
                         enabled:[[BAPreferences sharedPreferences] maghribAlertEnabled]
                     highlighted:(self.currentPrayer == BAPrayerMaghrib)
                           pause:(audioPrayer == BAPrayerMaghrib)];
    
    [self setImageForAdhanButton:self.ishaButton
                         enabled:[[BAPreferences sharedPreferences] ishaAlertEnabled]
                     highlighted:(self.currentPrayer == BAPrayerIsha)
                           pause:(audioPrayer == BAPrayerIsha)];

}


- (void)setImageForAdhanButton:(NSButton *)button enabled:(BOOL)enabled highlighted:(BOOL)highlighted pause:(BOOL)pause
{
    if ([[BAPreferences sharedPreferences] silentMode]) {
        [button setEnabled:NO];
        if (highlighted) {
            button.image = [NSImage imageNamed:@"sound-off-white"];
        } else {
            button.image = [NSImage imageNamed:@"sound-off"];
        }
        
        return;
    }
    
    [button setEnabled:YES];
    
    if (pause) {
        if (highlighted) {
            button.image = [NSImage imageNamed:@"paused"];
        } else {
            button.image = [NSImage imageNamed:@"paused-green"];
        }
    } else {
        if (enabled) {
            if (highlighted) {
                button.image = [NSImage imageNamed:@"sound-on-white"];
            } else {
                button.image = [NSImage imageNamed:@"sound-on"];
            }
        } else {
            if (highlighted) {
                button.image = [NSImage imageNamed:@"sound-off-white"];
            } else {
                button.image = [NSImage imageNamed:@"sound-off"];
            }
        }
    }
    
    if (highlighted) {
        button.alternateImage = [NSImage imageNamed:@"sound-pressed-white"];
    } else {
        button.alternateImage = [NSImage imageNamed:@"sound-pressed"];
    }
}


- (void)updateDate
{
    NSDate *adjustedDate = [BALocalizer adjustedHijriDateForDate:[NSDate date]];
    
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	NSMutableParagraphStyle *altParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    
	if([Localizer displayRightToLeft]) {
		[paragraphStyle setAlignment:NSRightTextAlignment];
		[altParagraphStyle setAlignment:NSLeftTextAlignment];
	} else {
		[paragraphStyle setAlignment:NSLeftTextAlignment];
		[altParagraphStyle setAlignment:NSRightTextAlignment];
	}
    
    NSDictionary *dayAttributes;
    NSDictionary *monthAttributes;
    NSDictionary *yearAttributes;
    
    NSFont *dayFont = [NSFont fontWithName:@"HelveticaNeue-UltraLight" size:54];
    NSString *regularFontName = @"HelveticaNeue";
    
    dayAttributes = @{ NSFontAttributeName : dayFont,
                       NSForegroundColorAttributeName : [NSColor blackColor],
                       NSParagraphStyleAttributeName : altParagraphStyle};
    
    monthAttributes = @{ NSFontAttributeName : [NSFont fontWithName:regularFontName size:19],
                         NSForegroundColorAttributeName : [NSColor blackColor],
                         NSParagraphStyleAttributeName : paragraphStyle};
    
    yearAttributes = @{ NSFontAttributeName : [NSFont fontWithName:regularFontName size:15],
                        NSForegroundColorAttributeName : [NSColor blackColor],
                        NSParagraphStyleAttributeName : paragraphStyle};

    NSAttributedString *attributedDayString = [[NSAttributedString alloc] initWithString:[Formatter formattedHijriDayWithDate:adjustedDate] attributes:dayAttributes];
    NSAttributedString *attributedMonthString = [[NSAttributedString alloc] initWithString:[Formatter formattedHijriMonthWithDate:adjustedDate] attributes:monthAttributes];
    NSAttributedString *attributedYearString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@%@",[Formatter formattedHijriYearWithDate:adjustedDate],BALocalizedString(@"h")] attributes:yearAttributes];
    
    self.snapshotView.day = [attributedDayString ba_fittedAttributedStringToWidth:NSWidth([self.snapshotView dayRect])];
    self.snapshotView.month = [attributedMonthString ba_fittedAttributedStringToWidth:NSWidth([self.snapshotView monthRect])];
    self.snapshotView.year = [attributedYearString ba_fittedAttributedStringToWidth:NSWidth([self.snapshotView yearRect])];
    
    self.snapshotView.arabicMode = [Localizer displayArabic];
    
    [self.snapshotView setNeedsDisplay:YES];
}

- (void)updateDisplayForLanguage
{	
	[self updateDate];
	[self checkPrayertimes];
}


#pragma mark - Text Styling

- (void)stylePrayerNameLabel:(NSTextField *)label forName:(NSString *)name highlighted:(BOOL)highlighted
{
    [label setStringValue:name];
    
    NSMutableAttributedString *attrLabel = [[NSMutableAttributedString alloc] initWithString:label.stringValue];
    
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    
	if([Localizer displayRightToLeft]) {
		[paragraphStyle setAlignment:NSRightTextAlignment];
	} else {
		[paragraphStyle setAlignment:NSLeftTextAlignment];
	}
    
	[attrLabel addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attrLabel.string.length)];
	
	if(highlighted) {
		[attrLabel addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, attrLabel.string.length)];
	} else {
		[attrLabel addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, attrLabel.string.length)];
	}
    
	[(BAVerticallyCenteredTextFieldCell *)[label cell] setFontOffset:0.0];
    [attrLabel addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"HelveticaNeue-Medium" size:16] range:NSMakeRange(0, attrLabel.string.length)];
	
	[label setAttributedStringValue:attrLabel];
}


- (void)stylePrayerTimeLabel:(NSTextField *)label forTime:(NSDate *)time highlighted:(BOOL)highlighted
{
    [label setStringValue:[Formatter formattedTimeWithDate:time]];
    
    NSString *amPmString = [Formatter formattedPeriodWithDate:time];
	label.stringValue = [label.stringValue stringByReplacingOccurrencesOfString:@"AM" withString:@"am"];
	label.stringValue = [label.stringValue stringByReplacingOccurrencesOfString:@"PM" withString:@"pm"];
    amPmString = [amPmString stringByReplacingOccurrencesOfString:@"AM" withString:@"am"];
    amPmString = [amPmString stringByReplacingOccurrencesOfString:@"PM" withString:@"pm"];
	NSRange amPmRange = [label.stringValue rangeOfString:amPmString];
	
	
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	if([Localizer displayRightToLeft]) {
		[paragraphStyle setAlignment:NSLeftTextAlignment];
	} else {
		[paragraphStyle setAlignment:NSRightTextAlignment];
	}
	
	NSMutableAttributedString *attrLabel = [[NSMutableAttributedString alloc] initWithString:label.stringValue];
	[attrLabel addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attrLabel.string.length)];
	
	if(highlighted) {
		[attrLabel addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, attrLabel.string.length)];
	} else {
		[attrLabel addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, attrLabel.string.length)];
		if(amPmRange.location != NSNotFound) {
			[attrLabel addAttribute:NSForegroundColorAttributeName value:[NSColor colorWithCalibratedRed:100.0/255.0 green:100.0/255.0 blue:100.0/255.0 alpha:1.0] range:amPmRange];
		}
	}
    
    [(BAVerticallyCenteredTextFieldCell *)[label cell] setFontOffset:0.0];
    [attrLabel addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"HelveticaNeue" size:16.0] range:NSMakeRange(0, attrLabel.string.length)];
    if(amPmRange.location != NSNotFound) {
        [attrLabel addAttribute:NSFontAttributeName value:[NSFont fontWithName:@"HelveticaNeue-Light" size:16.0] range:amPmRange];
    }
	
	[label setAttributedStringValue:attrLabel];
    
    if (highlighted) {
        NSRect frame = self.statusView.frame;
        frame.origin.y = label.frame.origin.y;
        [self.statusView setFrame:frame];
        [self.statusView setAlphaValue:1.0];
    }
}


#pragma mark - Displaying Window

- (void)togglePrayerTimes
{
	if(self.window.alphaValue == 0.0) {
		[self showPrayerTimes];
	} else {
		[self hidePrayerTimes];
	}
}


- (void)hidePrayerTimes
{
    if (self.window.alphaValue < 1.0) {
        return;
    }
    
	[NSAnimationContext beginGrouping];
	[[NSAnimationContext currentContext] setDuration:kBAPanelCloseDuration];
	[[[self window] animator] setAlphaValue:0];
	[NSAnimationContext endGrouping];
	   
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (kBAPanelCloseDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.window orderOut:nil];
    });
}


- (void)showPrayerTimes
{
    //update display on demand
    [self handleTimer:nil];

    NSRect panelRect = [self panelRect];
    
    self.snapshotView.arabicMode = [Localizer displayArabic];
    
    [self.snapshotView setNeedsDisplay:YES];

    [NSApp activateIgnoringOtherApps:NO];
	[self.window makeKeyAndOrderFront:nil];
    
    [self.window setAlphaValue:1];
    [self.window setFrame:panelRect display:YES];
}


- (NSRect)panelRect
{
    NSRect screenRect = [[NSScreen mainScreen] frame];    
    NSRect statusRect = [[self.statusItem valueForKey:@"window"] frame];
	statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);

	NSRect panelRect = [self.window frame];
    panelRect.size.width = kBAPanelWidth;
    panelRect.size.height = kBAPanelHeight;
    panelRect.origin.x = statusRect.origin.x;
    panelRect.origin.y = (NSMaxY(statusRect) - NSHeight(panelRect));
	
	if (NSMaxX(panelRect) > NSMaxX(screenRect)) {
		panelRect.origin.x -= NSMaxX(panelRect) - NSMaxX(screenRect);
	}

	if (NSMaxY(panelRect) > NSMaxY(screenRect)) {
		panelRect.origin.y -= NSMaxY(panelRect) - NSMaxY(screenRect);
	}

    return panelRect;
}

#pragma mark - IBActions

- (IBAction)toggleFajrAdhan:(id)sender
{
    if ([self audioIsPlayingForPrayer:BAPrayerFajr]) {
        [self.sound stop];
    } else {
        [[BAPreferences sharedPreferences] setFajrAlertEnabled:![[BAPreferences sharedPreferences] fajrAlertEnabled]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kBAAlertsDidChangeNotification object:nil];
    }
    [self userDefaultsDidChange:nil];
}


- (IBAction)toggleShuruqAdhan:(id)sender
{
    if ([self audioIsPlayingForPrayer:BAPrayerSunrise]) {
        [self.sound stop];
    } else {
        [[BAPreferences sharedPreferences] setShuruqReminderAlertEnabled:![[BAPreferences sharedPreferences] shuruqReminderAlertEnabled]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kBAAlertsDidChangeNotification object:nil];
    }
    [self userDefaultsDidChange:nil];
}


- (IBAction)toggleDhuhrAdhan:(id)sender
{
    if ([self audioIsPlayingForPrayer:BAPrayerDhuhr]) {
        [self.sound stop];
    } else {
        [[BAPreferences sharedPreferences] setDhuhrAlertEnabled:![[BAPreferences sharedPreferences] dhuhrAlertEnabled]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kBAAlertsDidChangeNotification object:nil];
    }
    [self userDefaultsDidChange:nil];
}


- (IBAction)toggleAsrAdhan:(id)sender
{
    if ([self audioIsPlayingForPrayer:BAPrayerAsr]) {
        [self.sound stop];
    } else {
        [[BAPreferences sharedPreferences] setAsrAlertEnabled:![[BAPreferences sharedPreferences] asrAlertEnabled]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kBAAlertsDidChangeNotification object:nil];
    }
    [self userDefaultsDidChange:nil];
}


- (IBAction)toggleMaghribAdhan:(id)sender
{
    if ([self audioIsPlayingForPrayer:BAPrayerMaghrib]) {
        [self.sound stop];
    } else {
        [[BAPreferences sharedPreferences] setMaghribAlertEnabled:![[BAPreferences sharedPreferences] maghribAlertEnabled]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kBAAlertsDidChangeNotification object:nil];
    }
    [self userDefaultsDidChange:nil];
}


- (IBAction)toggleIshaAdhan:(id)sender
{
    if ([self audioIsPlayingForPrayer:BAPrayerIsha]) {
        [self.sound stop];
    } else {
        [[BAPreferences sharedPreferences] setIshaAlertEnabled:![[BAPreferences sharedPreferences] ishaAlertEnabled]];
        [[NSNotificationCenter defaultCenter] postNotificationName:kBAAlertsDidChangeNotification object:nil];
    }
    [self userDefaultsDidChange:nil];
}


- (BOOL)audioIsPlayingForPrayer:(BAPrayer)prayer
{
    if (self.sound && [self.sound isPlaying]) {
        NSDictionary *prayerAlertInfo = self.sound.prayerAlertInfo;
        
        return ([prayerAlertInfo[kBAPrayerAlertInfoKeyPrayer] integerValue] == prayer);
    }
    
    return NO;
}


#pragma mark - Location Manager Notifications

- (void)locationDidUpdate:(NSNotification*)notification
{
    [self userDefaultsDidChange:nil];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    [self hidePrayerTimes];
}


#pragma mark - NSWindow Delegate

- (void)windowDidResignKey:(NSNotification *)notification;
{
	[self hidePrayerTimes];
}


#pragma mark - NSNotificationCenterDelegate

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
	if (self.sound && [self.sound isPlaying]) {
        [self.sound stop];
    }
}


- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}


#pragma mark - Preferences

- (IBAction)showSettingsMenu:(id)sender
{
	[NSMenu popUpContextMenu:self.settingsMenu withEvent:[NSApp currentEvent] forView:(NSButton *)sender];
}


- (IBAction)openAboutWindow:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];
	[NSApp orderFrontStandardAboutPanel:sender];
}


- (IBAction)openHelp:(id)sender
{
	[self hidePrayerTimes];
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://batoulapps.com/software/guidance/help/"]];
}


- (IBAction)openPrefs:(id)sender
{
    [NSApp activateIgnoringOtherApps:YES];
	[self.preferencesWindowController showWindow:nil];
    [[self.preferencesWindowController window] makeKeyAndOrderFront:nil];
    [[self.preferencesWindowController window] setLevel:NSFloatingWindowLevel];
}


#pragma mark - Preferences Accessors

- (NSWindowController *)preferencesWindowController
{
    if (_preferencesWindowController == nil)
    {
        BAGeneralPrefsViewController *generalPrefsViewController = [[BAGeneralPrefsViewController alloc] initWithNibName:@"BAGeneralPrefsViewController" bundle:nil];
        BALocationPrefsViewController *locationPrefsViewController = [[BALocationPrefsViewController alloc] initWithNibName:@"BALocationPrefsViewController" bundle:nil];
		BACalculationPrefsViewController *calculationPrefsViewController = [[BACalculationPrefsViewController alloc] initWithNibName:@"BACalculationPrefsViewController" bundle:nil];
		BANotificationPrefsViewController *notificationPrefsViewController = [[BANotificationPrefsViewController alloc] initWithNibName:@"BANotificationPrefsViewController" bundle:nil];
		BAAdvancedPrefsViewController *advancedPrefsViewController = [[BAAdvancedPrefsViewController alloc] initWithNibName:@"BAAdvancedPrefsViewController" bundle:nil];
		
        NSString *title = NSLocalizedString(@"Preferences", @"Common title for Preferences window");
        _preferencesWindowController = [[MASPreferencesWindowController alloc] initWithViewControllers:@[generalPrefsViewController, locationPrefsViewController,calculationPrefsViewController,notificationPrefsViewController,advancedPrefsViewController] title:title];
    }
    return _preferencesWindowController;
}


- (NSMenu *)settingsMenu
{
	if(_settingsMenu == nil) {
		_settingsMenu = [[NSMenu alloc] initWithTitle:@"Guidance"];
		
		NSMenuItem *aboutItem = [[NSMenuItem alloc] initWithTitle:@"About Guidance" action:@selector(openAboutWindow:) keyEquivalent:@""];
		NSMenuItem *helpItem = [[NSMenuItem alloc] initWithTitle:@"Guidance Help" action:@selector(openHelp:) keyEquivalent:@""];
		
		NSMenuItem *prefItem = [[NSMenuItem alloc] initWithTitle:@"Preferences..." action:@selector(openPrefs:) keyEquivalent:@","];
		[prefItem setKeyEquivalentModifierMask:NSCommandKeyMask];
		
		NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
		[quitItem setKeyEquivalentModifierMask:NSCommandKeyMask];
		
		[_settingsMenu addItem:aboutItem];
		[_settingsMenu addItem:helpItem];
		[_settingsMenu addItem:[NSMenuItem separatorItem]];
		[_settingsMenu addItem:prefItem];
		[_settingsMenu addItem:[NSMenuItem separatorItem]];
		[_settingsMenu addItem:quitItem];
	}
	
	return _settingsMenu;
}


#pragma mark - Accessors

- (NSMutableArray *)pendingAlerts
{
    if (_pendingAlerts == nil) {
        _pendingAlerts = [NSMutableArray arrayWithCapacity:7];
    }
    
    return _pendingAlerts;
}


#pragma mark - NSSoundDelegate

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)finishedPlaying
{
    if (finishedPlaying) {
        NSDictionary *prayerAlertInfo = sound.prayerAlertInfo;
        if ([prayerAlertInfo[kBAPrayerAlertInfoKeyAdhan] boolValue] && [[BAPreferences sharedPreferences] duaEnabled]) {
            self.sound.prayerAlertInfo = nil;
            self.sound = nil;
            
            self.sound = [[NSSound alloc] initWithContentsOfURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Dua" ofType:@"m4a"]] byReference:NO];
            self.sound.delegate = self;
            self.sound.volume = [[BAPreferences sharedPreferences] alertVolume] / 100.0;
            self.sound.prayerAlertInfo = @{kBAPrayerAlertInfoKeyPrayer: prayerAlertInfo[kBAPrayerAlertInfoKeyPrayer], kBAPrayerAlertInfoKeyAdhan: @NO};
            [self.sound play];
        }
    }
    
    [self updatePrayerTimeDisplay];
}

@end
