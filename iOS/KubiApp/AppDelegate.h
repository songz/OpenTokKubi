//
//  AppDelegate.h
//  KubiApp
//
//  Copyright (c) 2013 Revolve Robotics Inc. All rights reserved.
//

@class ServiceViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate, NSNetServiceDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) ServiceViewController *serviceViewController;

@end

extern AppDelegate *DELEGATE;