//
//  BALocationManager.m
//  Guidance
//
//  Created by Ameir Al-Zoubi on 6/23/13.
//  Copyright (c) 2013 Batoul Apps. All rights reserved.
//

#import "BALocationManager.h"

#import <AddressBook/AddressBook.h>

#import "BAPreferences.h"

@implementation BALocationManager

+ (BALocationManager *)defaultManager
{
	__strong static id defaultManager;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		defaultManager = [[BALocationManager alloc] init];
	});
	
	return defaultManager;
}

- (CLLocationManager*)locationManager
{
	if(!_locationManager) {
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;
		_locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
		_locationManager.distanceFilter = kCLLocationAccuracyThreeKilometers;
	}
	
	return _locationManager;
}

#pragma mark - CLLocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	if(newLocation != nil && newLocation.horizontalAccuracy >= 0 && newLocation.horizontalAccuracy <= kCLLocationAccuracyThreeKilometers) {
		CLGeocoder *geocoder = [[CLGeocoder alloc] init];
		[geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *placemarks, NSError *error) {
            CLPlacemark *placemark = [placemarks firstObject];
            if (placemark) { 
                [manager stopUpdatingLocation];
                
                [[BAPreferences sharedPreferences] updateLocationWithPlacemark:placemark];
                
                [NSTimeZone resetSystemTimeZone];
                NSTimeZone *timeZone = [NSTimeZone systemTimeZone];
                [[BAPreferences sharedPreferences] setTimeZone:[timeZone name]];

                [[BAPreferences sharedPreferences] updatePreferences];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:kLocationDidUpdateNotification object:nil];
            }
		}];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if (error.code == kCLErrorDenied) {
        [[BAPreferences sharedPreferences] setUseCurrentLocation:NO];
        [manager stopUpdatingLocation];
        [manager stopMonitoringSignificantLocationChanges];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kLocationDidFailNotification object:error];
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager
{
	
}

- (void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager
{
	
}

@end
