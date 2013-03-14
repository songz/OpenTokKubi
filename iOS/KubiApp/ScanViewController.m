//
//  ScanViewController.m
//  KubiApp
//
//  Copyright (c) 2013 Revolve Robotics Inc. All rights reserved.
//

#import "ScanViewController.h"
#import "ServiceViewController.h"

@interface ScanViewController ()

@end

@implementation ScanViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) loadView
{
    [super loadView];
    self.tableView.rowHeight = 80;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
                                             initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                             target:self
                                             action:@selector(rescan:)];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
                                              initWithTitle:@"Cancel"
                                              style:UIBarButtonItemStyleDone
                                              target:self
                                              action:@selector(cancel:)];
    self.navigationItem.title = @"Scanning";
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.serviceViewController startScan];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.serviceViewController stopScan];
}

- (void) rescan:(id) sender
{
    [self.serviceViewController stopScan];
    [self.serviceViewController startScan];
}

- (void) cancel:(id) sender
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void) reload {
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.serviceViewController.peripherals count];;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                                   reuseIdentifier:CellIdentifier];

    CBPeripheral *peripheral = [self.serviceViewController.peripherals objectAtIndex:[indexPath row]];    
    NSString *name = peripheral.name;
    if (!name) {
        name = [peripheral description];
    }
    cell.textLabel.text = name;
    
    NSNumber *RSSI = peripheral.RSSI;
    if (!RSSI) {
        RSSI = [self.serviceViewController.discoveryRSSIs objectForKey:name];        
    }
    cell.detailTextLabel.text = [NSString stringWithFormat:@"RSSI: %@", RSSI];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    UIButton *connectButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    connectButton.frame = CGRectMake(0,0,80,40);
    [connectButton setTitle:@"Connect" forState:UIControlStateNormal];
    [connectButton addTarget:self action:@selector(connect:) forControlEvents:UIControlEventTouchUpInside];
    connectButton.tag = [indexPath row];
    cell.accessoryView = connectButton;
    return cell;
}

- (void) connect:(id) sender {
    [self.serviceViewController connectToPeripheralAtIndex:[sender tag]];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return toInterfaceOrientation == UIInterfaceOrientationPortrait;
    }
}

@end
