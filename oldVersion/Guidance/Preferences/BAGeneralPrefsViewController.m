//
//  BAGeneralPrefsViewController.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 7/4/13.
//  Copyright (c) 2013 Batoul Apps. All rights reserved.
//

#import "BAGeneralPrefsViewController.h"
#import "BALocalizer.h"
#import "BAPreferences.h"

#import "StartAtLoginController.h"

@interface BAGeneralPrefsViewController ()

@property (weak, nonatomic) IBOutlet NSButton *displayNextPrayerButton;
@property (weak, nonatomic) IBOutlet NSTextField *displayNextPrayerTypeLabel;
@property (weak, nonatomic) IBOutlet NSPopUpButton *displayNextPrayerTypeButton;
@property (weak, nonatomic) IBOutlet NSTextField *displayNextPrayerNameLabel;
@property (weak, nonatomic) IBOutlet NSPopUpButton *displayNextPrayerNameButton;
@property (weak, nonatomic) IBOutlet NSButton *displayIconButton;
@property (weak, nonatomic) IBOutlet NSButton *arabicModeButton;
@property (weak, nonatomic) IBOutlet NSButton *startAtLoginButton;
@property (strong, nonatomic) StartAtLoginController *loginController;

@end

@implementation BAGeneralPrefsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)viewWillAppear
{
    [self loadPreferences];
	[self updateUI];
}

- (void)loadPreferences
{
	BOOL displayNextPrayer = [[BAPreferences sharedPreferences] displayNextPrayer];
	if(displayNextPrayer) {
		[self.displayNextPrayerButton setState:NSOnState];
	} else {
		[self.displayNextPrayerButton setState:NSOffState];
	}
	
	NSInteger displayNextPrayerType = [[BAPreferences sharedPreferences] nextPrayerDisplayType];
	[self.displayNextPrayerTypeButton selectItemAtIndex:displayNextPrayerType];
    
	NSInteger displayNextPrayerName = [[BAPreferences sharedPreferences] nextPrayerDisplayName];
	[self.displayNextPrayerNameButton selectItemAtIndex:displayNextPrayerName];
    
    BOOL displayIcon = [[BAPreferences sharedPreferences] displayIcon];
	if (displayIcon) {
		[self.displayIconButton setState:NSOnState];
	} else {
		[self.displayIconButton setState:NSOffState];
	}
	
	BOOL arabicMode = [Localizer displayArabic];
	if(arabicMode) {
		[self.arabicModeButton setState:NSOnState];
	} else {
		[self.arabicModeButton setState:NSOffState];
	}
    
    if ([[Localizer shared] nativeArabic]) {
        [self.arabicModeButton setEnabled:NO];
    } else {
        [self.arabicModeButton setEnabled:YES];
    }
	
	BOOL launch = [self.loginController startAtLogin];
	if(launch) {
		[self.startAtLoginButton setState:NSOnState];
	} else {
		[self.startAtLoginButton setState:NSOffState];
	}
}

- (void)updateUI
{
	if([self.displayNextPrayerButton state] == NSOnState) {
		[self.displayNextPrayerTypeButton setEnabled:YES];
		[self.displayNextPrayerTypeLabel setTextColor:[NSColor blackColor]];
        [self.displayNextPrayerNameButton setEnabled:YES];
        [self.displayNextPrayerNameLabel setTextColor:[NSColor blackColor]];
	} else {
		[self.displayNextPrayerTypeButton setEnabled:NO];
		[self.displayNextPrayerTypeLabel setTextColor:[NSColor grayColor]];
		[self.displayNextPrayerNameButton setEnabled:NO];
		[self.displayNextPrayerNameLabel setTextColor:[NSColor grayColor]];
	}
    
    if ([[BAPreferences sharedPreferences] nextPrayerDisplayType] == BANextPrayerDisplayTypeNone) {
        [[self.displayNextPrayerNameButton itemAtIndex:2] setEnabled:NO];
        [[self.displayNextPrayerTypeButton itemAtIndex:2] setEnabled:YES];
    } else if ([[BAPreferences sharedPreferences] nextPrayerDisplayName] == BANextPrayerDisplayNameNone) {
        [[self.displayNextPrayerNameButton itemAtIndex:2] setEnabled:YES];
        [[self.displayNextPrayerTypeButton itemAtIndex:2] setEnabled:NO];
    } else {
        [[self.displayNextPrayerNameButton itemAtIndex:2] setEnabled:YES];
        [[self.displayNextPrayerTypeButton itemAtIndex:2] setEnabled:YES];
    }
}

#pragma mark - Preferences methods

- (IBAction)toggleArabicMode:(id)sender
{
	NSButton *button = sender;
    [[BAPreferences sharedPreferences] setForceArabic:([button state] == NSOnState)];
}

- (IBAction)toggleStartAtLogin:(id)sender
{
	NSButton *button = sender;
    [self.loginController setStartAtLogin:([button state] == NSOnState)];
}

- (IBAction)toggleDisplayNextPrayer:(id)sender
{
	NSButton *button = sender;
    [[BAPreferences sharedPreferences] setDisplayNextPrayer:([button state] == NSOnState)];
	
    if (![[BAPreferences sharedPreferences] displayNextPrayer] && ![[BAPreferences sharedPreferences] displayIcon]) {
        [[BAPreferences sharedPreferences] setDisplayIcon:YES];
        [self loadPreferences];
    }

	[self updateUI];
}

- (IBAction)changeDisplayNextPrayerType:(id)sender
{
	NSPopUpButton *button = sender;
	[[BAPreferences sharedPreferences] setNextPrayerDisplayType:[button indexOfSelectedItem]];
    
	[self updateUI];
}

- (IBAction)changeDisplayNextPrayerName:(id)sender
{
	NSPopUpButton *button = sender;
	[[BAPreferences sharedPreferences] setNextPrayerDisplayName:[button indexOfSelectedItem]];
    
	[self updateUI];
}

- (IBAction)toggleDisplayIcon:(id)sender
{
	NSButton *button = sender;
    [[BAPreferences sharedPreferences] setDisplayIcon:([button state] == NSOnState)];
    
    if (![[BAPreferences sharedPreferences] displayIcon] && ![[BAPreferences sharedPreferences] displayNextPrayer]) {
        [[BAPreferences sharedPreferences] setDisplayNextPrayer:YES];
        [self loadPreferences];
    }
	
	[self updateUI];
}

#pragma mark - Accessors

- (StartAtLoginController *)loginController
{
	if(_loginController == nil) {
		_loginController = [[StartAtLoginController alloc] initWithIdentifier:@"com.batoulapps.GuidanceLauncher"];
	}
	
	return _loginController;
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"GeneralPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"setting-general"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"General", @"Toolbar item name for the General preference pane");
}

@end
