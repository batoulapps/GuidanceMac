//
//  BACalculationPrefsViewController.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 7/5/13.
//  Copyright (c) 2013 Batoul Apps. All rights reserved.
//

#import "BACalculationPrefsViewController.h"

#import "BAConstants.h"
#import "BAPreferences.h"
#import "Adhan-Swift.h"

@interface BACalculationPrefsViewController ()

@property (weak, nonatomic) IBOutlet NSMatrix *madhabMatrix;
@property (weak, nonatomic) IBOutlet NSPopUpButton *methodButton;
@property (weak, nonatomic) IBOutlet NSButton *automaticMethodButton;
@property (weak, nonatomic) IBOutlet NSButton *delayedIshaButton;

@property (weak, nonatomic) IBOutlet NSWindow *customMethodWindow;
@property (weak, nonatomic) IBOutlet NSTextField *customFajrAngle;
@property (weak, nonatomic) IBOutlet NSTextField *customIshaAngle;

@property (strong, nonatomic) NSArray *methodMap;

@end

@implementation BACalculationPrefsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.methodMap = @[@(BAMethodPreferenceEgyptian),
                           @(BAMethodPreferenceKarachi),
                           @(BAMethodPreferenceMuslimWorldLeague),
                           @(BAMethodPreferenceMoonsightingCommittee),
                           @(BAMethodPreferenceKuwait),
                           @(BAMethodPreferenceUmmAlQura),
                           @(BAMethodPreferenceGulf),
                           @(BAMethodPreferenceQatar),
                           @(BAMethodPreferenceSingapore),
                           @(BAMethodPreferenceTehran),
                           @(BAMethodPreferenceNorthAmerica),
                           @(BAMethodPreferenceCustom)
                           ];
    }
    
    return self;
}

- (void)loadView
{
    [super loadView];
    [self.methodButton removeAllItems];
    for (NSNumber *method in self.methodMap) {
        [self.methodButton addItemWithTitle:[self titleForMethod:(BAMethodPreference)[method integerValue]]];
    }
}

- (void)viewWillAppear
{	
    [self loadPreferences];
	[self updateUI];
}

- (void)loadPreferences
{
    NSInteger madhab = [[BAPreferences sharedPreferences] madhab];
	[self.madhabMatrix selectCellAtRow:madhab column:0];
    
    if ([[BAPreferences sharedPreferences] autoDetectMethod]) {
        [self.automaticMethodButton setState:NSOnState];
    } else {
        [self.automaticMethodButton setState:NSOffState];
    }
    
    if ([[BAPreferences sharedPreferences] delayedIshaInRamadan]) {
        [self.delayedIshaButton setState:NSOnState];
    } else {
        [self.delayedIshaButton setState:NSOffState];
    }
}

- (void)updateUI
{
	NSString *customMethodTitle = [NSString stringWithFormat:@"Custom Method (%.1f°, %.1f°)",[[BAPreferences sharedPreferences] customFajrAngle],[[BAPreferences sharedPreferences] customIshaAngle]];
	
	[[[self.methodButton menu] itemAtIndex:[self buttonIndexForMethod:BAMethodPreferenceCustom]] setTitle:customMethodTitle];
	
	NSInteger index = [self buttonIndexForMethod:[[BAPreferences sharedPreferences] method]];
	[self.methodButton selectItemAtIndex:index];
    
    if ([[BAPreferences sharedPreferences] autoDetectMethod]) {
        [self.methodButton setEnabled:NO];
    } else {
        [self.methodButton setEnabled:YES];
    }
    
    BACalculationParameters *calcParams = [[BACalculationParameters alloc] initWithMethod:[BAPreferences calculationMethodForPreference:[[BAPreferences sharedPreferences] method]]];
    [self.delayedIshaButton setHidden:!(calcParams.ishaInterval > 0)];
}

#pragma mark - Preferences methods

- (IBAction)toggleAutomaticMethod:(id)sender
{
	NSButton *button = sender;
	if ([button state] == NSOnState) {
		[[BAPreferences sharedPreferences] setAutoDetectMethod:YES];
        
        [[BAPreferences sharedPreferences] updatePreferences];
        [self updateUI];
	} else {
		[[BAPreferences sharedPreferences] setAutoDetectMethod:NO];
        [self updateUI];
	}
}

- (IBAction)toggleDelayedIsha:(id)sender
{
    NSButton *button = sender;
    [[BAPreferences sharedPreferences] setDelayedIshaInRamadan:([button state] == NSOnState)];
}

- (IBAction)changeMadhab:(id)sender
{
	NSMatrix *matrix = (NSMatrix *)sender;
    [[BAPreferences sharedPreferences] setMadhab:[matrix selectedRow]];
}

- (IBAction)changeMethod:(id)sender
{
	NSPopUpButton *button = (NSPopUpButton *)sender;
    BAMethodPreference pref = [self methodForButtonIndex:[button indexOfSelectedItem]];

	if (pref == BAMethodPreferenceCustom) {
		[self showCustomMethodModal];
	} else {
		[[BAPreferences sharedPreferences] setMethod:pref];
	}
    
    [self updateUI];
}

- (void)showCustomMethodModal
{
	[self.customFajrAngle setStringValue:[NSString stringWithFormat:@"%.1f",[[BAPreferences sharedPreferences] customFajrAngle]]];
	[self.customIshaAngle setStringValue:[NSString stringWithFormat:@"%.1f",[[BAPreferences sharedPreferences] customIshaAngle]]];

    [[self.view window] beginSheet:self.customMethodWindow completionHandler:^(NSModalResponse returnCode) {
        [self.customMethodWindow orderOut:self];
    }];
}

- (IBAction)customMethodSave:(id)sender
{
	if(self.customFajrAngle.doubleValue > 0.0 && self.customIshaAngle.doubleValue > 0.0) {
        [[BAPreferences sharedPreferences] setCustomFajrAngle:self.customFajrAngle.doubleValue];
        [[BAPreferences sharedPreferences] setCustomIshaAngle:self.customIshaAngle.doubleValue];
        [[BAPreferences sharedPreferences] setMethod:BAMethodPreferenceCustom];
	}
	
	[NSApp endSheet:self.customMethodWindow];
	[self updateUI];
}

- (IBAction)customMethodCancel:(id)sender
{
	[NSApp endSheet:self.customMethodWindow];
	[self updateUI];
}

#pragma mark - Utils

- (BAMethodPreference)methodForButtonIndex:(NSInteger)index
{
    if (index >= 0 && index < self.methodMap.count) {
        return (BAMethodPreference)[[self.methodMap objectAtIndex:index] integerValue];
    }
    
    return BAMethodPreferenceMuslimWorldLeague;
}

- (NSInteger)buttonIndexForMethod:(BAMethodPreference)method
{
    __block NSInteger buttonIndex = 0;
    
    [self.methodMap enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BAMethodPreference pref = (BAMethodPreference)[obj integerValue];
        if (pref == method) {
            buttonIndex = idx;
            *stop = YES;
        }
    }];
    
    return buttonIndex;
}

- (NSString *)titleForMethod:(BAMethodPreference)method
{
    switch (method) {
        case BAMethodPreferenceEgyptian:
            return @"Egyptian General Authority";
        case BAMethodPreferenceKarachi:
            return @"Islamic University, Karachi";
        case BAMethodPreferenceMuslimWorldLeague:
            return @"Muslim World League";
        case BAMethodPreferenceMoonsightingCommittee:
            return @"Moonsighting Committee";
        case BAMethodPreferenceKuwait:
            return @"Kuwait";
        case BAMethodPreferenceUmmAlQura:
            return @"Umm Al-Qura";
        case BAMethodPreferenceGulf:
            return @"Dubai";
        case BAMethodPreferenceQatar:
            return @"Qatar";
        case BAMethodPreferenceNorthAmerica:
            return @"North America";
        case BAMethodPreferenceCustom:
            return @"Custom Method...";
        case BAMethodPreferenceSingapore:
            return @"Singapore";
        case BAMethodPreferenceTehran:
            return @"Tehran";
    }
    
    return @"";
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"CalculationPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"setting-times"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Prayer Times", @"Toolbar item name for the Calculations preference pane");
}

@end
