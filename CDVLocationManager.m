//
//  CDVLocationManager.m
//
//  Created by alex on 21.09.15.
//  Copyright © 2015 Codeveyor. All rights reserved.
//

#import "CDVLocationManager.h"

@import CoreLocation;

static CDVLocationManager *Instance;

@interface CDVLocationManager () <CLLocationManagerDelegate>

@property (nonatomic, strong) CLLocationManager *locationManager;

@property (nonatomic, copy) CDVLocationManagerCallbackBlock callbackBlock;

- (void)startUpdateLocation;
- (void)stopUpdateLocation;

@end

@implementation CDVLocationManager

#pragma mark - Init

+ (void)setupWithCallbackBlock:(CDVLocationManagerCallbackBlock)callbackBlock
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        Instance = [self new];
        Instance.callbackBlock = callbackBlock;
    });
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.locationManager = [CLLocationManager new];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
        
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(startUpdateLocation)
                   name:UIApplicationDidBecomeActiveNotification object:nil];
        [notificationCenter addObserver:self selector:@selector(stopUpdateLocation)
                   name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.locationManager stopUpdatingLocation];
    [self.locationManager setDelegate:nil];
}

#pragma mark - Actions

- (void)startUpdateLocation
{
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)] && [CLLocationManager locationServicesEnabled])
    {
        [self.locationManager requestWhenInUseAuthorization];
    }
}

- (void)stopUpdateLocation
{
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - LocationManager Delegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse)
    {
        [self.locationManager startUpdatingLocation];
    }
    else
    {
        NSLog(@"User denied access to location services");
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    [self stopUpdateLocation];
    if (error.code != kCLErrorDenied)
    {
        self.callbackBlock(NO, nil, error);
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    [self stopUpdateLocation];
    
    CLLocation *location = [locations lastObject];
    CLGeocoder *geocoder = [CLGeocoder new];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        
        if (error)
        {
            self.callbackBlock(NO, nil, error);
            return;
        }
        
        CLPlacemark *placemark = [placemarks lastObject];
        if (placemark.country == nil)
        {
            NSError *error = nil;
            self.callbackBlock(NO, nil, error);
            
            return;
        }

        if (self.callbackBlock)
        {
            self.callbackBlock(YES, location, nil);
        }
    }];
}

@end
