//
//  AppDelegate.m
//  KubiApp
//
//  Copyright (c) 2013 Revolve Robotics Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "ServiceViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{        
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.serviceViewController = [[ServiceViewController alloc] init];
    [self.window makeKeyAndVisible];    
    return YES;
}

@end
