//
//  ServiceViewController.h
//  KubiApp
//
//  Copyright (c) 2013 Revolve Robotics Inc. All rights reserved.
//
#import <CoreBluetooth/CoreBluetooth.h>

@class ScanViewController;

@interface ServiceViewController : UIViewController

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSMutableArray *peripherals;
@property (nonatomic, strong) ScanViewController *scanViewController;
@property (nonatomic, strong) NSMutableDictionary *discoveryRSSIs;

@property (nonatomic, assign) short xPosition;
@property (nonatomic, assign) short yPosition;
@property (nonatomic, assign) NSString *deviceName;
@property (nonatomic, assign) int stepSize;
@property (nonatomic, assign) int speed;

- (void) startScan;
- (void) stopScan;
- (void) connectToPeripheralAtIndex:(NSInteger) index;

- (void) position:(CGPoint) point;
- (void) recenter:(id) sender;
- (void) moveUp:(id) sender;
- (void) moveDown:(id) sender;
- (void) moveLeft:(id) sender;
- (void) moveRight:(id) sender;
@end
