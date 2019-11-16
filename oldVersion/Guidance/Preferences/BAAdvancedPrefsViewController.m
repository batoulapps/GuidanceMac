//
//  BAAdvancedPrefsViewController.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 7/5/13.
//  Copyright (c) 2013 Batoul Apps. All rights reserved.
//

#import "BAAdvancedPrefsViewController.h"
#import "BAPreferences.h"

@interface BAAdvancedPrefsViewController ()

@property (weak, nonatomic) IBOutlet NSButton *autoRuleButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *hijriAdjustmentTypeButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *highLatitudeMethodButton;
@property (weak, nonatomic) IBOutlet NSTextField *fajrAdjustment;
@property (weak, nonatomic) IBOutlet NSTextField *shuruqAdjustment;
@property (weak, nonatomic) IBOutlet NSTextField *dhuhrAdjustment;
@property (weak, nonatomic) IBOutlet NSTextField *asrAdjustment;
@property (weak, nonatomic) IBOutlet NSTextField *maghribAdjustment;
@property (weak, nonatomic) IBOutlet NSTextField *ishaAdjustment;

@end

@implementation BAAdvancedPrefsViewController

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
	if([[BAPreferences sharedPreferences] autoDetectHighLatitudeRule]) {
		[self.autoRuleButton setState:NSOnState];
	} else {
		[self.autoRuleButton setState:NSOffState];
	}
    
    NSInteger hijriOffset = [[BAPreferences sharedPreferences] hijriOffset];
    [self.hijriAdjustmentTypeButton selectItemAtIndex:hijriOffset + 3];
    
    self.fajrAdjustment.stringValue = [NSString stringWithFormat:@"%d",(int)[[BAPreferences sharedPreferences] fajrAdjustment]];
    self.shuruqAdjustment.stringValue = [NSString stringWithFormat:@"%d",(int)[[BAPreferences sharedPreferences] shuruqAdjustment]];
    self.dhuhrAdjustment.stringValue = [NSString stringWithFormat:@"%d",(int)[[BAPreferences sharedPreferences] dhuhrAdjustment]];
    self.asrAdjustment.stringValue = [NSString stringWithFormat:@"%d",(int)[[BAPreferences sharedPreferences] asrAdjustment]];
    self.maghribAdjustment.stringValue = [NSString stringWithFormat:@"%d",(int)[[BAPreferences sharedPreferences] maghribAdjustment]];
    self.ishaAdjustment.stringValue = [NSString stringWithFormat:@"%d",(int)[[BAPreferences sharedPreferences] ishaAdjustment]];
}

- (void)updateUI
{
    if ([[BAPreferences sharedPreferences] autoDetectHighLatitudeRule]) {
        [self.highLatitudeMethodButton setEnabled:NO];
    } else {
        [self.highLatitudeMethodButton setEnabled:YES];
    }
    
    switch ([[BAPreferences sharedPreferences] highLatitudeRule]) {
        case BAHighLatitudeRuleMiddleOfTheNight:
            [self.highLatitudeMethodButton selectItemAtIndex:0];
            break;
        case BAHighLatitudeRuleSeventhOfTheNight:
            [self.highLatitudeMethodButton selectItemAtIndex:1];
            break;
        case BAHighLatitudeRuleTwilightAngle:
            [self.highLatitudeMethodButton selectItemAtIndex:2];
            break;
    }
}

#pragma mark - Preferences methods

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    NSTextField *changedField = [aNotification object];
    if (changedField.stringValue.integerValue == 0) {
        changedField.stringValue = @"0";
    }
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    NSTextField *changedField = [aNotification object];
    
    if (changedField == self.fajrAdjustment) {
        [self changeFajrAdjustment:changedField];
    } else if (changedField == self.shuruqAdjustment) {
        [self changeShuruqAdjustment:changedField];
    } else if (changedField == self.dhuhrAdjustment) {
        [self changeDhuhrAdjustment:changedField];
    } else if (changedField == self.asrAdjustment) {
        [self changeAsrAdjustment:changedField];
    } else if (changedField == self.maghribAdjustment) {
        [self changeMaghribAdjustment:changedField];
    } else if (changedField == self.ishaAdjustment) {
        [self changeIshaAdjustment:changedField];
    }
}

- (IBAction)changeFajrAdjustment:(id)sender
{
    NSTextField *textField = sender;
    [[BAPreferences sharedPreferences] setFajrAdjustment:textField.stringValue.integerValue];
}

- (IBAction)changeShuruqAdjustment:(id)sender
{
    NSTextField *textField = sender;
    [[BAPreferences sharedPreferences] setShuruqAdjustment:textField.stringValue.integerValue];
}

- (IBAction)changeDhuhrAdjustment:(id)sender
{
    NSTextField *textField = sender;
    [[BAPreferences sharedPreferences] setDhuhrAdjustment:textField.stringValue.integerValue];
}

- (IBAction)changeAsrAdjustment:(id)sender
{
    NSTextField *textField = sender;
    [[BAPreferences sharedPreferences] setAsrAdjustment:textField.stringValue.integerValue];
}

- (IBAction)changeMaghribAdjustment:(id)sender
{
    NSTextField *textField = sender;
    [[BAPreferences sharedPreferences] setMaghribAdjustment:textField.stringValue.integerValue];
}

- (IBAction)changeIshaAdjustment:(id)sender
{
    NSTextField *textField = sender;
    [[BAPreferences sharedPreferences] setIshaAdjustment:textField.stringValue.integerValue];
}

- (IBAction)changeHijriAdjustment:(id)sender
{
	NSPopUpButton *button = sender;

	[[BAPreferences sharedPreferences] setHijriOffset:([button indexOfSelectedItem] - 3)];
}

- (IBAction)changeHighLatitudeMethod:(id)sender
{
    NSPopUpButton *button = sender;
    
    switch ([button indexOfSelectedItem]) {
        case 0:
            [[BAPreferences sharedPreferences] setHighLatitudeRule:BAHighLatitudeRuleMiddleOfTheNight];
            break;
        case 1:
            [[BAPreferences sharedPreferences] setHighLatitudeRule:BAHighLatitudeRuleSeventhOfTheNight];
            break;
        case 2:
            [[BAPreferences sharedPreferences] setHighLatitudeRule:BAHighLatitudeRuleTwilightAngle];
            break;
        default:
            // no change
            break;
    }
}

- (IBAction)toggleAutomaticRule:(id)sender
{
	NSButton *button = sender;
    if ([button state] == NSOnState) {
        [[BAPreferences sharedPreferences] setAutoDetectHighLatitudeRule:YES];
        
        [[BAPreferences sharedPreferences] updatePreferences];
        [self updateUI];
    } else {
        [[BAPreferences sharedPreferences] setAutoDetectHighLatitudeRule:NO];
        [self updateUI];
    }
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"AdvancedPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"setting-advanced"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Advanced", @"Toolbar item name for the Advanced preference pane");
}

@end
