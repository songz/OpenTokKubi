//
//  RoomViewController.h
//  KubiApp
//
//  Created by Song Zheng on 7/2/13.
//  Copyright (c) 2013 Revolve Robotics Inc. All rights reserved.
//


@class ServiceViewController;

@interface RoomViewController : UITableViewController <UITableViewDataSource>{
    NSArray *tableData;
}
@property (nonatomic, weak) ServiceViewController *serviceViewController;
@property (nonatomic, retain) NSArray *tableData;

- (void) reload;

@end


