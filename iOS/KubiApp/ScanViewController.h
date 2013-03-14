//
//  ScanViewController.h
//  KubiApp
//
//  Copyright (c) 2013 Revolve Robotics Inc. All rights reserved.
//

@class ServiceViewController;

@interface ScanViewController : UITableViewController

@property (nonatomic, weak) ServiceViewController *serviceViewController;

- (void) reload;

@end
