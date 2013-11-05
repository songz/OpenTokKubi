//
//  ServiceViewController.h
//  KubiApp
//
//  Copyright (c) 2013 Revolve Robotics Inc. All rights reserved.
//
#import <CoreBluetooth/CoreBluetooth.h>
#import <Opentok/Opentok.h>

@class ScanViewController;
@class RoomViewController;

@interface ServiceViewController : UIViewController<OTSessionDelegate, OTSubscriberDelegate, OTPublisherDelegate>

@property (nonatomic, strong) CBCentralManager *manager;
@property (nonatomic, strong) CBPeripheral *peripheral;
@property (nonatomic, strong) NSMutableArray *peripherals;
@property (nonatomic, strong) ScanViewController *scanViewController;
@property (nonatomic, strong) RoomViewController *roomViewController;
@property (nonatomic, strong) NSMutableDictionary *discoveryRSSIs;

@property (nonatomic, assign) short xPosition;
@property (nonatomic, assign) short yPosition;
@property (nonatomic, assign) NSString *deviceName;
@property (nonatomic, assign) int stepSize;
@property (nonatomic, assign) int speed;

- (void) startScan;
- (void) stopScan;
- (void) connectToPeripheralAtIndex:(NSInteger) index;

- (void) joinNewSession:(NSString*)apiKey withSession:(NSString*)sid withRoomName:(NSString*)roomName andToken:(NSString*)token;

- (void) position:(CGPoint) point;
- (void) recenter:(id) sender;
- (void) moveUp:(id) sender;
- (void) moveDown:(id) sender;
- (void) moveLeft:(id) sender;
- (void) moveRight:(id) sender;
@end