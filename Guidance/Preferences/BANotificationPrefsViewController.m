//
//  BANotificationPrefsViewController.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 7/5/13.
//  Copyright (c) 2013 Batoul Apps. All rights reserved.
//

#import "BANotificationPrefsViewController.h"
#import "BAPreferences.h"

@interface BANotificationPrefsViewController ()

@property (weak, nonatomic) IBOutlet NSButton *silentModeButton;
@property (weak, nonatomic) IBOutlet NSButton *enableDuaButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *fajrAdhanButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *dhuhrAdhanButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *asrAdhanButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *maghribAdhanButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *ishaAdhanButton;
@property (weak, nonatomic) IBOutlet NSSlider *volumeSlider;
@property (weak, nonatomic) IBOutlet NSButton *fajrReminderButton;
@property (weak, nonatomic) IBOutlet NSButton *shuruqReminderButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *fajrReminderOffsetButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *shuruqReminderOffsetButton;

@property (weak, nonatomic) IBOutlet NSButton *fajrPreviewButton;
@property (weak, nonatomic) IBOutlet NSButton *dhuhrPreviewButton;
@property (weak, nonatomic) IBOutlet NSButton *asrPreviewButton;
@property (weak, nonatomic) IBOutlet NSButton *maghribPreviewButton;
@property (weak, nonatomic) IBOutlet NSButton *ishaPreviewButton;

@property (weak, nonatomic) IBOutlet NSTextField *notificationsLabel;
@property (weak, nonatomic) IBOutlet NSButton *notificationsButton;

@property (strong, nonatomic) NSSound *sound;

@property (copy, nonatomic) NSArray *offsetValues;

@end

NSString * const kBAPreviewFajr = @"kBAPreviewFajr";
NSString * const kBAPreviewDhuhr = @"kBAPreviewDhuhr";
NSString * const kBAPreviewAsr = @"kBAPreviewAsr";
NSString * const kBAPreviewMaghrib = @"kBAPreviewMaghrib";
NSString * const kBAPreviewIsha = @"kBAPreviewIsha";
NSInteger const kBAAdhanOptionNone = 0;
NSInteger const kBAAdhanOptionSelect = 9;

@implementation BANotificationPrefsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _offsetValues = @[ @15, @20, @30, @45, @60, @90, @120 ];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    [super loadView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertsDidChange:) name:kBAAlertsDidChangeNotification object:nil];
}

- (void)viewWillAppear
{
    [self loadPreferences];
	[self updateUI];
}

- (void)loadPreferences
{
    self.silentModeButton.state = [[BAPreferences sharedPreferences] silentMode] ? NSOnState : NSOffState;
    self.enableDuaButton.state = [[BAPreferences sharedPreferences] duaEnabled] ? NSOnState : NSOffState;
    self.fajrReminderButton.state = [[BAPreferences sharedPreferences] fajrReminderAlertEnabled] ? NSOnState : NSOffState;
    self.shuruqReminderButton.state = [[BAPreferences sharedPreferences] shuruqReminderAlertEnabled] ? NSOnState : NSOffState;
    
    self.volumeSlider.integerValue = [[BAPreferences sharedPreferences] alertVolume];
    
    [self updateAdhanButton:self.fajrAdhanButton customAdhan:[[BAPreferences sharedPreferences] fajrCustomAdhan]];
    [self updateAdhanButton:self.dhuhrAdhanButton customAdhan:[[BAPreferences sharedPreferences] dhuhrCustomAdhan]];
    [self updateAdhanButton:self.asrAdhanButton customAdhan:[[BAPreferences sharedPreferences] asrCustomAdhan]];
    [self updateAdhanButton:self.maghribAdhanButton customAdhan:[[BAPreferences sharedPreferences] maghribCustomAdhan]];
    [self updateAdhanButton:self.ishaAdhanButton customAdhan:[[BAPreferences sharedPreferences] ishaCustomAdhan]];
    
    [self.fajrAdhanButton selectItemAtIndex:
     [[BAPreferences sharedPreferences] fajrAlertEnabled] ? [[BAPreferences sharedPreferences] fajrAdhan] : 0];
    
    [self.dhuhrAdhanButton selectItemAtIndex:
     [[BAPreferences sharedPreferences] dhuhrAlertEnabled] ? [[BAPreferences sharedPreferences] dhuhrAdhan] : 0];
    
    [self.asrAdhanButton selectItemAtIndex:
     [[BAPreferences sharedPreferences] asrAlertEnabled] ? [[BAPreferences sharedPreferences] asrAdhan] : 0];
    
    [self.maghribAdhanButton selectItemAtIndex:
     [[BAPreferences sharedPreferences] maghribAlertEnabled] ? [[BAPreferences sharedPreferences] maghribAdhan] : 0];
    
    [self.ishaAdhanButton selectItemAtIndex:
     [[BAPreferences sharedPreferences] ishaAlertEnabled] ? [[BAPreferences sharedPreferences] ishaAdhan] : 0];
    
    NSInteger fajrOffsetIndex = [self.offsetValues indexOfObject:@([[BAPreferences sharedPreferences] fajrReminderOffset])];
    [self.fajrReminderOffsetButton selectItemAtIndex:fajrOffsetIndex];

    NSInteger shuruqOffsetIndex = [self.offsetValues indexOfObject:@([[BAPreferences sharedPreferences] shuruqReminderOffset])];
    [self.shuruqReminderOffsetButton selectItemAtIndex:shuruqOffsetIndex];
}

- (void)updateUI
{
    [self updatePreviewButton:self.fajrPreviewButton soundName:kBAPreviewFajr];
    [self updatePreviewButton:self.dhuhrPreviewButton soundName:kBAPreviewDhuhr];
    [self updatePreviewButton:self.asrPreviewButton soundName:kBAPreviewAsr];
    [self updatePreviewButton:self.maghribPreviewButton soundName:kBAPreviewMaghrib];
    [self updatePreviewButton:self.ishaPreviewButton soundName:kBAPreviewIsha];
    
    for (id subview in self.view.subviews) {
        if ([subview isKindOfClass:[NSTextField class]] && subview != self.notificationsLabel) {
            NSTextField *textField = (NSTextField *)subview;
            if ([[BAPreferences sharedPreferences] silentMode]) {
                [textField setTextColor:[NSColor grayColor]];
            } else {
                [textField setTextColor:[NSColor blackColor]];
            }
        } else if ([subview isKindOfClass:[NSButton class]] && subview != self.silentModeButton && subview != self.notificationsButton) {
            NSButton *button = (NSButton *)subview;
            if ([[BAPreferences sharedPreferences] silentMode]) {
                [button setEnabled:NO];
            } else {
                [button setEnabled:YES];
            }
        }
    }
}

- (void)updateAdhanButton:(NSPopUpButton *)button customAdhan:(NSData *)customAdhan
{
    if ([button numberOfItems] > kBAAdhanOptionCustom) {
        [button removeItemAtIndex:kBAAdhanOptionCustom];
    }
    
    if (customAdhan.length > 0) {
        BOOL stale;
        NSError *resolveError;
        NSURL *fileURL = [NSURL URLByResolvingBookmarkData:customAdhan options:NSURLBookmarkResolutionWithoutUI|NSURLBookmarkResolutionWithSecurityScope relativeToURL:nil bookmarkDataIsStale:&stale error:&resolveError];
        
        if (resolveError) {
            NSLog(@"Resolve error: %@", [resolveError localizedDescription]);
        }
        
        if (fileURL) {
            [button insertItemWithTitle:[fileURL lastPathComponent] atIndex:kBAAdhanOptionCustom];
        }
    }
}

- (void)updatePreviewButton:(NSButton *)button soundName:(NSString *)name
{
    if (self.sound && [self.sound isPlaying] && [self.sound.name isEqualToString:name]) {
        [button setTitle:@"Stop"];
    } else {
        [button setTitle:@"Play"];
    }
}

- (void)alertsDidChange:(NSNotification*)notification
{
    [self loadPreferences];
    [self updateUI];
}

#pragma mark - Preferences methods

- (IBAction)toggleSilentMode:(id)sender
{
    [[BAPreferences sharedPreferences] setSilentMode:(self.silentModeButton.state == NSOnState)];
    
    [self updateUI];
}

- (IBAction)toggleDuaEnabled:(id)sender
{
    [[BAPreferences sharedPreferences] setDuaEnabled:(self.enableDuaButton.state == NSOnState)];
}

- (IBAction)previewFajr:(NSButton *)button
{
    NSInteger index = self.fajrAdhanButton.indexOfSelectedItem;
    NSString *name = kBAPreviewFajr;
    
    [self togglePreview:index name:name custom:[[BAPreferences sharedPreferences] fajrCustomAdhan]];
}

- (IBAction)previewDhuhr:(NSButton *)button
{
    NSInteger index = self.dhuhrAdhanButton.indexOfSelectedItem;
    NSString *name = kBAPreviewDhuhr;
    
    [self togglePreview:index name:name custom:[[BAPreferences sharedPreferences] dhuhrCustomAdhan]];
}

- (IBAction)previewAsr:(NSButton *)button
{
    NSInteger index = self.asrAdhanButton.indexOfSelectedItem;
    NSString *name = kBAPreviewAsr;
    
    [self togglePreview:index name:name custom:[[BAPreferences sharedPreferences] asrCustomAdhan]];
}

- (IBAction)previewMaghrib:(NSButton *)button
{
    NSInteger index = self.maghribAdhanButton.indexOfSelectedItem;
    NSString *name = kBAPreviewMaghrib;
    
    [self togglePreview:index name:name custom:[[BAPreferences sharedPreferences] maghribCustomAdhan]];
}

- (IBAction)previewIsha:(NSButton *)button
{
    NSInteger index = self.ishaAdhanButton.indexOfSelectedItem;
    NSString *name = kBAPreviewIsha;
    
    [self togglePreview:index name:name custom:[[BAPreferences sharedPreferences] ishaCustomAdhan]];
}

- (void)togglePreview:(NSInteger)selectedIndex name:(NSString *)name custom:(NSData *)custom
{
    if (selectedIndex == 0) {
        return;
    }
    
    if (self.sound && [self.sound isPlaying] && [self.sound.name isEqualToString:name]) {
        [self.sound stop];
    } else {
        [self playPreview:selectedIndex name:name custom:custom];
    }
    
    [self updateUI];
}

- (void)playPreview:(NSInteger)selectedIndex name:(NSString *)name custom:(NSData *)custom
{
    [self.sound stop];
    
    NSURL *fileURL = [BAPreferences fileForAdhan:selectedIndex customAdhan:custom];
    [fileURL startAccessingSecurityScopedResource];
    NSData *audioData = [NSData dataWithContentsOfURL:fileURL];
    [fileURL stopAccessingSecurityScopedResource];
    
    self.sound = [[NSSound alloc] initWithData:audioData];
    self.sound.volume = self.volumeSlider.integerValue / 100.0;
    self.sound.name = name;
    self.sound.delegate = self;
    [self.sound play];
}

- (void)sound:(NSSound *)sound didFinishPlaying:(BOOL)aBool
{
    [self updateUI];
}

- (void)chooseAdhanForPrayer:(BAPrayer)prayer
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowedFileTypes:@[@"m4a", @"mp3", @"wav"]];
    [openPanel setAllowsMultipleSelection:NO];
    
    if ([openPanel runModal] == NSModalResponseOK) {
        NSURL *fileURL = [[openPanel URLs] firstObject];
        
        NSError *error;
        NSData *data = [fileURL bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope | NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:&error];
        
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
            [self loadPreferences];
            return;
        }

        switch (prayer) {
            case BAPrayerFajr:
                [[BAPreferences sharedPreferences] setFajrAlertEnabled:YES];
                [[BAPreferences sharedPreferences] setFajrAdhan:kBAAdhanOptionCustom];
                [[BAPreferences sharedPreferences] setFajrCustomAdhan:data];
                break;
            case BAPrayerDhuhr:
                [[BAPreferences sharedPreferences] setDhuhrAlertEnabled:YES];
                [[BAPreferences sharedPreferences] setDhuhrAdhan:kBAAdhanOptionCustom];
                [[BAPreferences sharedPreferences] setDhuhrCustomAdhan:data];
                break;
            case BAPrayerAsr:
                [[BAPreferences sharedPreferences] setAsrAlertEnabled:YES];
                [[BAPreferences sharedPreferences] setAsrAdhan:kBAAdhanOptionCustom];
                [[BAPreferences sharedPreferences] setAsrCustomAdhan:data];
                break;
            case BAPrayerMaghrib:
                [[BAPreferences sharedPreferences] setMaghribAlertEnabled:YES];
                [[BAPreferences sharedPreferences] setMaghribAdhan:kBAAdhanOptionCustom];
                [[BAPreferences sharedPreferences] setMaghribCustomAdhan:data];
                break;
            case BAPrayerIsha:
                [[BAPreferences sharedPreferences] setIshaAlertEnabled:YES];
                [[BAPreferences sharedPreferences] setIshaAdhan:kBAAdhanOptionCustom];
                [[BAPreferences sharedPreferences] setIshaCustomAdhan:data];
                break;
            default:
                break;
        }
    }
    
    [self loadPreferences];
}

- (IBAction)changeAdhanFajr:(NSPopUpButton *)button
{
    if (button.indexOfSelectedItem == kBAAdhanOptionNone) {
        [[BAPreferences sharedPreferences] setFajrAlertEnabled:NO];
    } else if (button.indexOfSelectedItem == kBAAdhanOptionSelect) {
        [self chooseAdhanForPrayer:BAPrayerFajr];
    } else {
        [[BAPreferences sharedPreferences] setFajrAlertEnabled:YES];
        [[BAPreferences sharedPreferences] setFajrAdhan:button.indexOfSelectedItem];
    }
}

- (IBAction)changeAdhanDhuhr:(NSPopUpButton *)button
{
    if (button.indexOfSelectedItem == 0) {
        [[BAPreferences sharedPreferences] setDhuhrAlertEnabled:NO];
    } else if (button.indexOfSelectedItem == kBAAdhanOptionSelect) {
        [self chooseAdhanForPrayer:BAPrayerDhuhr];
    } else {
        [[BAPreferences sharedPreferences] setDhuhrAlertEnabled:YES];
        [[BAPreferences sharedPreferences] setDhuhrAdhan:button.indexOfSelectedItem];
    }
}

- (IBAction)changeAdhanAsr:(NSPopUpButton *)button
{
    if (button.indexOfSelectedItem == 0) {
        [[BAPreferences sharedPreferences] setAsrAlertEnabled:NO];
    } else if (button.indexOfSelectedItem == kBAAdhanOptionSelect) {
        [self chooseAdhanForPrayer:BAPrayerAsr];
    } else {
        [[BAPreferences sharedPreferences] setAsrAlertEnabled:YES];
        [[BAPreferences sharedPreferences] setAsrAdhan:button.indexOfSelectedItem];
    }
}

- (IBAction)changeAdhanMaghrib:(NSPopUpButton *)button
{
    if (button.indexOfSelectedItem == 0) {
        [[BAPreferences sharedPreferences] setMaghribAlertEnabled:NO];
    } else if (button.indexOfSelectedItem == kBAAdhanOptionSelect) {
        [self chooseAdhanForPrayer:BAPrayerMaghrib];
    } else {
        [[BAPreferences sharedPreferences] setMaghribAlertEnabled:YES];
        [[BAPreferences sharedPreferences] setMaghribAdhan:button.indexOfSelectedItem];
    }
}

- (IBAction)changeAdhanIsha:(NSPopUpButton *)button
{
    if (button.indexOfSelectedItem == 0) {
        [[BAPreferences sharedPreferences] setIshaAlertEnabled:NO];
    } else if (button.indexOfSelectedItem == kBAAdhanOptionSelect) {
        [self chooseAdhanForPrayer:BAPrayerIsha];
    } else {
        [[BAPreferences sharedPreferences] setIshaAlertEnabled:YES];
        [[BAPreferences sharedPreferences] setIshaAdhan:button.indexOfSelectedItem];
    }
}

- (IBAction)changeVolume:(id)sender
{
    [[BAPreferences sharedPreferences] setAlertVolume:self.volumeSlider.integerValue];
    if (self.sound && [self.sound isPlaying]) {
        self.sound.volume = self.volumeSlider.integerValue / 100.0;
    }
}

- (IBAction)toggleFajrReminder:(id)sender
{
    [[BAPreferences sharedPreferences] setFajrReminderAlertEnabled:(self.fajrReminderButton.state == NSOnState)];
}

- (IBAction)toggleShuruqReminder:(id)sender
{
    [[BAPreferences sharedPreferences] setShuruqReminderAlertEnabled:(self.shuruqReminderButton.state == NSOnState)];
}

- (IBAction)changeFajrReminderOffset:(NSPopUpButton *)button
{
    NSInteger offset = [[self.offsetValues objectAtIndex:button.indexOfSelectedItem] integerValue];
    [[BAPreferences sharedPreferences] setFajrReminderOffset:offset];
}

- (IBAction)changeShuruqReminderOffset:(NSPopUpButton *)button
{
    NSInteger offset = [[self.offsetValues objectAtIndex:button.indexOfSelectedItem] integerValue];
    [[BAPreferences sharedPreferences] setShuruqReminderOffset:offset];
}

- (IBAction)openNotificationCenterPreferences:(id)sender
{
	[[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:@"/System/Library/PreferencePanes/Notifications.prefPane"]];
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"NotificationPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"setting-alerts"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Notifications", @"Toolbar item name for the Notification preference pane");
}

@end
