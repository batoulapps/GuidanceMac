//
//  BALocationPrefsViewController.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 7/5/13.
//  Copyright (c) 2013 Batoul Apps. All rights reserved.
//

#import "BALocationPrefsViewController.h"

#import <CoreLocation/CoreLocation.h>

#import "BAConstants.h"
#import "BALocationManager.h"
#import "BAPreferences.h"

@interface BALocationPrefsViewController ()

@property (weak, nonatomic) IBOutlet NSButton *useCurrentLocationButton;
@property (weak, nonatomic) IBOutlet NSButton *findLocationButton;
@property (weak, nonatomic) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak, nonatomic) IBOutlet NSImageView *lookupSuccessIndicator;
@property (weak, nonatomic) IBOutlet NSTextField *userLocationLabel;
@property (weak, nonatomic) IBOutlet NSTextField *userLocationField;
@property (weak, nonatomic) IBOutlet NSTextField *timeZoneLabel;
@property (weak, nonatomic) IBOutlet NSButton *useSystemTimeZoneButton;
@property (weak, nonatomic) IBOutlet NSPopUpButton *timeZoneButton;

@property (strong, nonatomic) NSArray *timeZones;

@end

@implementation BALocationPrefsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationDidUpdate:) name:kLocationDidUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(locationDidFail:) name:kLocationDidFailNotification object:nil];
}

- (void)viewWillAppear
{
	[self.lookupSuccessIndicator setAlphaValue:0.0];
    [self.progressIndicator stopAnimation:nil];
	
    [self loadPreferences];
	[self updateUI];
}

- (void)loadPreferences
{
    if ([[BAPreferences sharedPreferences] useCurrentLocation]) {
        self.useCurrentLocationButton.state = NSOnState;
    } else {
        self.useCurrentLocationButton.state = NSOffState;
    }
    
    int index = 0;
    [self.timeZoneButton removeAllItems];
    for (NSDictionary *timeZone in self.timeZones) {
        [self.timeZoneButton addItemWithTitle:timeZone[@"title"]];
        if ([timeZone[@"timezone"] isEqualToString:[[BAPreferences sharedPreferences] timeZone]]) {
            [self.timeZoneButton selectItemAtIndex:index];
        }
        
        index++;
    }
    
    [self setLocationText];
}

- (void)updateUI
{
	if ([[BAPreferences sharedPreferences] useCurrentLocation]) {
        [self.userLocationField setEnabled:NO];
        [self.findLocationButton setEnabled:NO];
        [self.timeZoneButton setEnabled:NO];
		[self.userLocationLabel setTextColor:[NSColor grayColor]];
        [self.timeZoneLabel setTextColor:[NSColor grayColor]];
    } else {
        [self.userLocationField setEnabled:YES];
        [self.findLocationButton setEnabled:YES];
        [self.timeZoneButton setEnabled:YES];
		[self.userLocationLabel setTextColor:[NSColor blackColor]];
        [self.timeZoneLabel setTextColor:[NSColor blackColor]];
    }
}

- (void)locationDidUpdate:(NSNotification*)notification
{
    [self.progressIndicator stopAnimation:nil];
	
    [self loadPreferences];
    [self updateUI];
}

- (void)locationDidFail:(NSNotification*)notification
{
    [self.progressIndicator stopAnimation:nil];
	
    [self loadPreferences];
    [self updateUI];
    
    NSError *error = (NSError *)notification.object;
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:@"Error"];
    if (error.code == kCLErrorNetwork) {
        [alert setInformativeText:@"Network connection unavailable"];
    } else if (error.code == kCLErrorDenied) {
        [alert setInformativeText:@"Location services for Guidance is not enabled"];
    } else {
        [alert setInformativeText:@"Unable to get current location"];
    }
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
}

- (void)setLocationText
{
    NSString *city = [[BAPreferences sharedPreferences] city];
    NSString *state = [[BAPreferences sharedPreferences] state];
    NSString *countryCode = [[BAPreferences sharedPreferences] country];
    NSString *countryName = [[BAPreferences sharedPreferences] countryName];
    
    
    NSArray *titleComponents;
    
    if ([countryCode isEqualToString:@"US"] && ![city isEqualToString:state]) {
        titleComponents = @[city, state];
    } else {
        titleComponents = @[city, countryName];
    }
    
    self.userLocationField.stringValue = [titleComponents componentsJoinedByString:@", "];
}

#pragma mark - Preferences methods

- (IBAction)toggleUseCurrentLocation:(id)sender
{
    NSButton *button = (NSButton *)sender;
    
    if (button.state == NSOnState) {
        [[BAPreferences sharedPreferences] setUseCurrentLocation:YES];
        
        [[[BALocationManager defaultManager] locationManager] stopUpdatingLocation];
        [[[BALocationManager defaultManager] locationManager] startUpdatingLocation];
        [[[BALocationManager defaultManager] locationManager] startMonitoringSignificantLocationChanges];
        [self.lookupSuccessIndicator setAlphaValue:0.0];
        [self.progressIndicator startAnimation:nil];
    } else {
        [[BAPreferences sharedPreferences] setUseCurrentLocation:NO];
        
        [[[BALocationManager defaultManager] locationManager] stopUpdatingLocation];
        [[[BALocationManager defaultManager] locationManager] stopMonitoringSignificantLocationChanges];
        [self.progressIndicator stopAnimation:nil];
    }
    
    [self updateUI];
}

- (IBAction)findLocation:(id)sender
{
    [self.lookupSuccessIndicator setAlphaValue:0.0];
    [self.progressIndicator startAnimation:nil];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
	[geocoder geocodeAddressString:self.userLocationField.stringValue completionHandler:^(NSArray *placemarks, NSError *error) {
        if ([placemarks firstObject]) {
            CLPlacemark *placemark = [placemarks firstObject];
            [[BAPreferences sharedPreferences] updateLocationWithPlacemark:placemark];
            [self.progressIndicator stopAnimation:nil];
            [self.lookupSuccessIndicator setImage:[NSImage imageNamed:@"check"]];
            [self.lookupSuccessIndicator setAlphaValue:1.0];
            [self loadPreferences];
            
            [[BAPreferences sharedPreferences] updatePreferences];
        } else {
            [self.progressIndicator stopAnimation:nil];
            [self.lookupSuccessIndicator setImage:[NSImage imageNamed:@"error"]];
            [self.lookupSuccessIndicator setAlphaValue:1.0];
            
            NSAlert *alert = [[NSAlert alloc] init];
            [alert addButtonWithTitle:@"OK"];
            [alert setMessageText:@"Error"];
            if (error.code == kCLErrorNetwork) {
                [alert setInformativeText:@"Network connection unavailable"];
            } else if (error.code == kCLErrorGeocodeCanceled) {
                [alert setInformativeText:@"Lookup was canceled"];
            } else if (error.code == kCLErrorGeocodeFoundNoResult) {
                [alert setInformativeText:@"Location was not found"];
            } else if (error.code == kCLErrorGeocodeFoundPartialResult) {
                [alert setInformativeText:@"Lookup yielded a partial result"];
            } else {
                [alert setInformativeText:@"Unable to lookup location"];
            }
            [alert setAlertStyle:NSCriticalAlertStyle];
            [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
        }
    }];
}

- (IBAction)changeCustomTimeZone:(id)sender
{
    NSDictionary *timezone = [self.timeZones objectAtIndex:self.timeZoneButton.indexOfSelectedItem];

    [[BAPreferences sharedPreferences] setTimeZone:timezone[@"timezone"]];
}

#pragma mark - Accessors

- (NSArray *)timeZones
{
    if (_timeZones == nil) {
        NSMutableArray *timeZoneList = [[NSMutableArray alloc] initWithCapacity:[[NSTimeZone knownTimeZoneNames] count]];
        NSArray *timeZoneNames = [NSTimeZone knownTimeZoneNames];
        for (NSString *timeZoneName in timeZoneNames) {
            NSArray *nameComponents = [timeZoneName componentsSeparatedByString:@"/"];
            NSString *title = [[nameComponents lastObject] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            [timeZoneList addObject:@{@"title": title, @"timezone": timeZoneName}];
        }
        [timeZoneList sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES]]];
        
        _timeZones = [timeZoneList copy];
    }
    
    return _timeZones;
}

#pragma mark - MASPreferencesViewController

- (NSString *)viewIdentifier
{
    return @"LocationPreferences";
}

- (NSImage *)toolbarItemImage
{
    return [NSImage imageNamed:@"setting-location"];
}

- (NSString *)toolbarItemLabel
{
    return NSLocalizedString(@"Location", @"Toolbar item name for the Location preference pane");
}

@end
