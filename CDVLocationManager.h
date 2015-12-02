//
//  CDVLocationManager.h
//
//  Created by alex on 21.09.15.
//  Copyright © 2015 Codeveyor. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CLLocation;

typedef void (^CDVLocationManagerCallbackBlock)(BOOL success, CLLocation *location, NSError *error);

@interface CDVLocationManager : NSObject

+ (void)setupWithCallbackBlock:(CDVLocationManagerCallbackBlock)callbackBlock;

@end
