//
//  BALocationManager.h
//  Guidance
//
//  Created by Ameir Al-Zoubi on 6/23/13.
//  Copyright (c) 2013 Batoul Apps. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

static NSString *kLocationDidUpdateNotification = @"kLocationDidUpdateNotification";
static NSString *kLocationDidFailNotification = @"kLocationDidFailNotification";

@interface BALocationManager : NSObject <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

+ (BALocationManager *)defaultManager;

@end
