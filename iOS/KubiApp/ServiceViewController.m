//
//  ServiceViewController.m
//  KubiApp
//
//  Copyright (c) 2013 Revolve Robotics Inc. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "ServiceViewController.h"
#import "ScanViewController.h"
#import "RoomViewController.h"

#define DISCONNECTED_BACKGROUND_COLOR [UIColor grayColor]
#define CONNECTED_BACKGROUND_COLOR [UIColor colorWithRed:248/255.0 green:54/255.0 blue:36/255.0 alpha:1]

#define ACCESS_PROFILE_UUID [CBUUID UUIDWithString:CBUUIDGenericAccessProfileString]
#define MANUFACTURER_UUID   [CBUUID UUIDWithString:@"180A"]
#define BATTERY_STATUS_UUID [CBUUID UUIDWithString:@"e001"]
#define REVOLVE_SERVO_UUID  [CBUUID UUIDWithString:@"2A001800-2803-2801-2800-1D9FF2D5C442"]

#define DEVICE_NAME_UUID [CBUUID UUIDWithString:CBUUIDDeviceNameString]

#define REGISTER_WRITE1P_UUID [CBUUID UUIDWithString:@"9141"]
#define REGISTER_WRITE2P_UUID [CBUUID UUIDWithString:@"9142"]
#define REGISTER_TOMONITOR_UUID [CBUUID UUIDWithString:@"9143"]
#define REGISTER_MONITOREDVALUE_UUID [CBUUID UUIDWithString:@"9144"]
#define SERVO_HORIZONTAL_UUID [CBUUID UUIDWithString:@"9145"]
#define SERVO_VERTICAL_UUID [CBUUID UUIDWithString:@"9146"]

#define LABEL_WIDTH 320
#define LABEL_HEIGHT 50

@interface ServiceViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UIButton *actionButton;

@property (nonatomic, strong) UIButton *roomButton;
@property (nonatomic, strong) UISlider *stepSlider;
@property (nonatomic, strong) UILabel *stepLabel;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedLabel;
@property (nonatomic, strong) UILabel *deviceNameLabel;
@property (nonatomic, strong) UILabel *roomNameLabel;
@property (nonatomic, strong) UIAlertView *connectionAlertView;

@property (nonatomic, strong) NSMutableSet *canceledPeripherals;

@property (nonatomic, strong) CBService *accessProfileService;
@property (nonatomic, strong) CBService *manufacturerService;
@property (nonatomic, strong) CBService *revolveServoService;
@property (nonatomic, strong) CBService *batteryStatusService;

@property (nonatomic, strong) CBCharacteristic *deviceNameCharacteristic;
@property (nonatomic, strong) CBCharacteristic *registerWrite1pCharacteristic;
@property (nonatomic, strong) CBCharacteristic *registerWrite2pCharacteristic;
@property (nonatomic, strong) CBCharacteristic *registerToMonitorCharacteristic;
@property (nonatomic, strong) CBCharacteristic *registerMonitoredValueCharacteristic;
@property (nonatomic, strong) CBCharacteristic *servoHorizontalCharacteristic;
@property (nonatomic, strong) CBCharacteristic *servoVerticalCharacteristic;
@property (nonatomic, strong) CBCharacteristic *servoRegisterWrite1Characteristic; // 9141
@property (nonatomic, strong) CBCharacteristic *servoRegisterWrite2Characteristic; // 9142
@property (nonatomic, strong) CBCharacteristic *servoRegisterToMonitorCharacteristic; // 9143
@property (nonatomic, strong) CBCharacteristic *servoRegisterMonitoredValueCharacteristic; // 9144

- (void) updateSpeed;

@end

@implementation ServiceViewController{
    OTSession* _session;
    OTPublisher* _publisher;
    OTSubscriber* _subscriber;
    NSString* _apiKey;
    NSString* _sid;
    NSString* _token;
    NSMutableDictionary *subscriberDictionary;
}

- (id) init {
    if (self = [super init]) {
        self.peripherals = [NSMutableArray array];
        self.discoveryRSSIs = [NSMutableDictionary dictionary];
        self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        self.canceledPeripherals = [NSMutableSet set];
        self.deviceName = @"Kubi Not Connected";
        self.stepSize = 10;
        self.speed = 60;
    }
    return self;
}

#define VERTICAL_MARGIN 20
#define BUTTON_HEIGHT 50
#define BUTTON_WIDTH 120

#define PAD_HEIGHT 210
#define PAD_WIDTH 300

#define KUBI_BUTTON @"Connect Kubi"

- (void) updateStepText
{
    self.stepLabel.text = [NSString stringWithFormat:@"Step: %d", self.stepSize];
}

- (void) updateSpeedText
{
    self.speedLabel.text = [NSString stringWithFormat:@"Speed: %d", self.speed];
}

- (void) hideAccessories:(BOOL) hidden
{
    self.stepLabel.hidden = hidden;
    self.stepSlider.hidden = hidden;
    self.speedLabel.hidden = hidden;
    self.speedSlider.hidden = hidden;
}

- (void)loadView
{
    [super loadView];
    self.view.backgroundColor = DISCONNECTED_BACKGROUND_COLOR;
    
    self.stepSlider = [[UISlider alloc] initWithFrame:CGRectMake(0,0,300,20)];
    self.stepSlider.transform = CGAffineTransformMakeRotation(-M_PI*0.5);
    self.stepSlider.center = CGPointMake(60,300);
    self.stepSlider.minimumValue = 1;
    self.stepSlider.maximumValue = 100;
    self.stepSlider.value = self.stepSize;
    [self.stepSlider addTarget:self action:@selector(stepSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.stepSlider];
    
    self.stepLabel = [[UILabel alloc] initWithFrame:CGRectMake(10,100,100,40)];
    self.stepLabel.textAlignment = NSTextAlignmentCenter;
    self.stepLabel.backgroundColor = [UIColor clearColor];
    self.stepLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.stepLabel];
    [self updateStepText];
    
    self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(0,0,300,20)];
    self.speedSlider.transform = CGAffineTransformMakeRotation(-M_PI*0.5);
    self.speedSlider.center = CGPointMake(140,300);
    self.speedSlider.minimumValue = 1;
    self.speedSlider.maximumValue = 1023;
    self.speedSlider.value = self.speed;
    [self.speedSlider addTarget:self action:@selector(speedSliderDidChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:self.speedSlider];
    
    self.speedLabel = [[UILabel alloc] initWithFrame:CGRectMake(90,100,100,40)];
    self.speedLabel.textAlignment = NSTextAlignmentCenter;
    self.speedLabel.backgroundColor = [UIColor clearColor];
    self.speedLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:self.speedLabel];
    [self updateSpeedText];
    
    [self createPublisher];
    subscriberDictionary = [[NSMutableDictionary alloc] init];
    
    self.roomButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.roomButton setTitle:@"Choose Room" forState:UIControlStateNormal];
    [self.roomButton addTarget:self action:@selector(roomButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    CGRect actionButtonFrame = self.view.bounds;
    actionButtonFrame.origin.x = 80;
    actionButtonFrame.origin.y = actionButtonFrame.size.height - VERTICAL_MARGIN - BUTTON_HEIGHT;
    actionButtonFrame.size.width = BUTTON_WIDTH;
    actionButtonFrame.size.height = BUTTON_HEIGHT;
    self.roomButton.frame = actionButtonFrame;
    self.roomButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin + UIViewAutoresizingFlexibleLeftMargin + UIViewAutoresizingFlexibleRightMargin;
    [self.view insertSubview:self.roomButton atIndex:11];
    
    
    self.actionButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [self.actionButton setTitle:KUBI_BUTTON forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    actionButtonFrame = self.view.bounds;
    actionButtonFrame.origin.x = 80;
    actionButtonFrame.origin.y = actionButtonFrame.size.height - VERTICAL_MARGIN*2 - BUTTON_HEIGHT*2;
    actionButtonFrame.size.width = BUTTON_WIDTH;
    actionButtonFrame.size.height = BUTTON_HEIGHT;
    self.actionButton.frame = actionButtonFrame;
    self.actionButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin + UIViewAutoresizingFlexibleLeftMargin + UIViewAutoresizingFlexibleRightMargin;
    [self.view insertSubview:self.actionButton atIndex:10];
    
    
    CGRect deviceNameLabelFrame = CGRectMake(0,
                                             actionButtonFrame.origin.y - LABEL_HEIGHT,
                                             LABEL_WIDTH,
                                             LABEL_HEIGHT);
    
    self.deviceNameLabel = [[UILabel alloc] initWithFrame:deviceNameLabelFrame];
    self.deviceNameLabel.text = self.deviceName;
    self.deviceNameLabel.textAlignment = UITextAlignmentCenter;
    self.deviceNameLabel.font = [UIFont boldSystemFontOfSize:24];
    self.deviceNameLabel.backgroundColor = [UIColor clearColor];
    self.deviceNameLabel.textColor = [UIColor whiteColor];
    self.deviceNameLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin + UIViewAutoresizingFlexibleLeftMargin + UIViewAutoresizingFlexibleRightMargin;
    [self.view insertSubview:self.deviceNameLabel atIndex: 10];
    
    CGRect roomNameLabelFrame = CGRectMake(0.5*(self.view.bounds.size.width - LABEL_WIDTH),
                                             LABEL_HEIGHT - VERTICAL_MARGIN,
                                             LABEL_WIDTH,
                                             LABEL_HEIGHT);
    self.roomNameLabel = [[UILabel alloc] initWithFrame:roomNameLabelFrame];
    self.roomNameLabel.text = @"Please select a room";
    self.roomNameLabel.textAlignment = UITextAlignmentCenter;
    self.roomNameLabel.font = [UIFont boldSystemFontOfSize:24];
    self.roomNameLabel.backgroundColor = [UIColor clearColor];
    self.roomNameLabel.textColor = [UIColor whiteColor];
    self.roomNameLabel.autoresizingMask = UIViewAutoresizingFlexibleTopMargin + UIViewAutoresizingFlexibleLeftMargin + UIViewAutoresizingFlexibleRightMargin;
    [self.view insertSubview:self.roomNameLabel atIndex: 10];
    
    [self hideAccessories:YES];
}

- (void) createPublisher{
    CGRect screen = [[UIScreen mainScreen] bounds];
    CGFloat width = CGRectGetWidth(screen);
    CGFloat height = CGRectGetHeight(screen);
    
    _publisher = [[OTPublisher alloc] initWithDelegate:self];
    [_publisher.view setFrame:CGRectMake(width-240, height-255, 240, 240)];

    CGPoint saveCenter = _publisher.view.center;
    CGRect newFrame = CGRectMake(width-240, height-240, 240, 240);
    _publisher.view.frame = newFrame;
    _publisher.view.layer.cornerRadius = 240 / 2.0;
    _publisher.view.center = saveCenter;
    [self.view insertSubview:_publisher.view atIndex:5];
}

- (void)setupSession{
    NSLog(@" SETTING UP SESSION");
    NSLog(@" api key: %@", _apiKey);
    NSLog(@" session: %@", _sid);
    NSLog(@" token: %@", _token);
    if (_apiKey && _sid && _token) {
        _session = [[OTSession alloc] initWithSessionId:_sid delegate:self];
        [_session connectWithApiKey:_apiKey token:_token];
        _apiKey = NULL;
        _sid = NULL;
        _token = NULL;
    }
}

- (void)joinNewSession:(NSString *)apiKey withSession:(NSString *)sid withRoomName:(NSString *)roomName andToken:(NSString *)token{

    NSLog(@" api key: %@", apiKey);
    NSLog(@" session: %@", sid);
    NSLog(@" token: %@", token);

    _apiKey = [[NSString alloc] initWithString:apiKey];
    _sid = [[NSString alloc] initWithString:sid];
    _token = [[NSString alloc] initWithString:token];
    
    self.roomNameLabel.text = roomName;
    
    if (_session) {
        [_session disconnect];
        return;
    }
    
    [self setupSession];
}

- (void)updateStreamsView{
    
    CGRect screen = [[UIScreen mainScreen] bounds];
    double containerStreamsWidth = CGRectGetWidth(screen);
    double containerStreamsHeight = CGRectGetHeight(screen) - 240;
    double xStreams = 5;
    double yStreams = 20;
    
    int margin = 10;
    int centerx = 0;
    int centery = 0;
    
    double videoCount = [subscriberDictionary count];
    double rows = 1.0;
    double cols = ceil(videoCount/rows);
    double eWidth = containerStreamsWidth/cols;
    double eHeight = eWidth*(3.0/4.0);
    
    while (rows*eHeight < containerStreamsHeight) {
        if (cols==1) {
            break;
        }
        rows += 1;
        cols = ceil( videoCount/rows);
        double nWidth = containerStreamsWidth/cols;
        double nHeight = (nWidth/4.0)*3.0;
        
        double testHeight = containerStreamsHeight/rows;
        double testWidth = floor( testHeight*4.0/3.0 );
        
        NSLog(@"%f", (nHeight));
        
        if (nHeight > testHeight && (rows*nHeight) > containerStreamsHeight) {
            nHeight = testHeight;
            nWidth = testWidth;
        }
        
        if(nWidth < eWidth || rows*nHeight > containerStreamsHeight){
            rows -= 1;
            cols = ceil( videoCount/rows);
            break;
        }
        eWidth = nWidth;
        eHeight = nHeight;
    }
    if (eHeight*rows > containerStreamsHeight) {
        eWidth = (containerStreamsHeight/rows)*(4/3);
    }
    eWidth -= 10;
    
    int iRow = 0;
    int iCol = 0;
    int index = 0;
    
    eHeight = eWidth*(3.0/4.0);
    centery = ( containerStreamsHeight - rows*(eHeight+margin) )/2.0;
    if (centery< 0) {
        centery=0;
    }
    
    for(id key in subscriberDictionary){
        index ++;
        if ( iCol == 0 ) {
            if ( (videoCount - (iRow)*cols) <= cols ) {
                centerx = (containerStreamsWidth - (videoCount - (iRow)*cols)*(eWidth+margin) )/2.0;
            }else{
                centerx = (containerStreamsWidth - cols*(eWidth+margin) )/2.0;
            }
        }
        OTSubscriber* eSubscriber = [subscriberDictionary objectForKey:key];
        eSubscriber.view.frame = CGRectMake( xStreams+(eWidth+margin)*iCol + centerx, yStreams+(eHeight+margin)*iRow + centery, eWidth, (eWidth*(3.0/4.0)));
        iCol += 1;
        if (iCol>=cols) {
            iCol = 0;
            iRow += 1;
        }
    }
}

- (void)session:(OTSession*)session didFailWithError:(OTError*)error {
    NSLog(@"sessionDidFail");
    NSLog(@"%@", error);
    [self showAlert:[NSString stringWithFormat:@"There was an error connecting to session %@", session.sessionId]];
}
- (void)showAlert:(NSString*)string {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Message from video session"
                                                    message:string
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)sessionDidConnect:(OTSession*)session
{
    NSLog(@"sessionDidConnect (%@)", session.sessionId);
    [_session publish:_publisher];
    [_session receiveSignalType:@"x" withHandler:^(NSString *type, id data, OTConnection *fromConnection){
        
        int command = [(NSString* )data intValue];
        self.xPosition = command;
        NSLog(@"new position: %d", self.xPosition);
        if (self.xPosition > 100) {
            self.xPosition = 100;
        }
        NSLog(@"x signal");
        [self moveToCurrentPosition];
    }];
    [_session receiveSignalType:@"y" withHandler:^(NSString *type, id data, OTConnection *fromConnection){
        
        int command = [(NSString* )data intValue];
        self.yPosition = command;
        NSLog(@"new position: %d", self.yPosition);
        if (self.yPosition > 100) {
            self.yPosition = 100;
        }
        NSLog(@"y signal");
        [self moveToCurrentPosition];
    }];

    
    
}

- (void)session:(OTSession*)mySession didReceiveStream:(OTStream*)stream
{
    NSLog(@"session didReceiveStream (%@)", stream.streamId);
    
    // See the declaration of subscribeToSelf above.
    if (![stream.connection.connectionId isEqualToString: _session.connection.connectionId] && [subscriberDictionary count] < 2){
        OTSubscriber* newSubscriber = [[OTSubscriber alloc] initWithStream:stream delegate:self];
        [subscriberDictionary setObject:newSubscriber forKey:stream.streamId];
        [self.view insertSubview:newSubscriber.view atIndex:4];
    }
    [self updateStreamsView];
}
- (void)subscriberDidConnectToStream:(OTSubscriber*)subscriber
{
    NSLog(@"subscriberDidConnectToStream (%@)", subscriber.stream.connection.connectionId);
    
}

- (void)sessionDidDisconnect:(OTSession *)session{
    _session = NULL;
    [self createPublisher];
    [self setupSession];
}

- (void)session:(OTSession*)session didDropStream:(OTStream*)stream{
    NSLog(@"session didDropStream (%@)", stream.streamId);
    
    if ([subscriberDictionary objectForKey:stream.streamId])
    {
        [subscriberDictionary removeObjectForKey:stream.streamId];
    }
    [self updateStreamsView];
}

- (void)subscriber:(OTSubscriber*)subscriber didFailWithError:(OTError*)error
{
    NSLog(@"subscriber %@ didFailWithError %@", subscriber.stream.streamId, error);
    [self showAlert:[NSString stringWithFormat:@"There was an error subscribing to stream %@", subscriber.stream.streamId]];
    
    if ([subscriberDictionary objectForKey:subscriber.stream.streamId])
    {
        [subscriberDictionary removeObjectForKey:subscriber.stream.streamId];
    }
    [self updateStreamsView];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    } else {
        return toInterfaceOrientation == UIInterfaceOrientationPortrait;
    }
}

- (void) stepSliderDidChange:(UISlider *) slider
{
    self.stepSize = (int) self.stepSlider.value;
    [self updateStepText];
}

- (void) speedSliderDidChange:(UISlider *) slider
{
    self.speed = (int) self.speedSlider.value;
    [self updateSpeedText];
    [self updateSpeed];
}

- (void) roomButtonPressed:(UIButton *) sender{
    if ([sender.currentTitle isEqualToString:@"Choose Room"]) {
        self.roomViewController = [[RoomViewController alloc] init];
        self.roomViewController.serviceViewController = self;
        UINavigationController *scanViewNavigationController = [[UINavigationController alloc]
                                                                initWithRootViewController:self.roomViewController];
        scanViewNavigationController.navigationBar.tintColor = CONNECTED_BACKGROUND_COLOR;
        scanViewNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentModalViewController:scanViewNavigationController animated:YES];
    } else if ([sender.currentTitle isEqualToString:@"Leave Room"]) {
        [sender setTitle:@"Choose Room" forState:UIControlStateNormal];
    }
}

- (void) actionButtonPressed:(UIButton *) sender
{
    if ([sender.currentTitle isEqualToString:KUBI_BUTTON]) {
        self.scanViewController = [[ScanViewController alloc] init];
        self.scanViewController.serviceViewController = self;
        UINavigationController *scanViewNavigationController = [[UINavigationController alloc]
                                                                initWithRootViewController:self.scanViewController];
        scanViewNavigationController.navigationBar.tintColor = CONNECTED_BACKGROUND_COLOR;
        scanViewNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        [self presentModalViewController:scanViewNavigationController animated:YES];
    } else if ([sender.currentTitle isEqualToString:@"Disconnect"]) {
        if (self.peripheral) {
            [self.canceledPeripherals addObject:self.peripheral];
            [self.manager cancelPeripheralConnection:self.peripheral];
            self.peripheral = nil;
        }
        [sender setTitle:@"Scan" forState:UIControlStateNormal];
    }
}

static void swap_bytes(short *value) {
    char *bytes = (char *) value;
    char temp = bytes[0];
    bytes[0] = bytes[1];
    bytes[1] = temp;
}

- (void) updateHorizontalSpeed {
    //value : 4 bytes: device:reg_address:register_value_low:register_value_high
    unsigned char buffer[4];
    buffer[0] = 2; // HORIZONTAL
    buffer[1] = 0x20;
    buffer[2] = (unsigned char) (self.speed & 0xFF);
    buffer[3] = (unsigned char) ((self.speed >> 8) & 0xFF);
    [self.peripheral writeValue:[NSData dataWithBytes:buffer length:4]
              forCharacteristic:self.servoRegisterWrite2Characteristic
                           type:CBCharacteristicWriteWithResponse];

}

- (void) updateVerticalSpeed {
    //value : 4 bytes: device:reg_address:register_value_low:register_value_high
    unsigned char buffer[4];
    buffer[0] = 1; // VERTICAL
    buffer[1] = 0x20;
    buffer[2] = (unsigned char) (self.speed & 0xFF);
    buffer[3] = (unsigned char) ((self.speed >> 8) & 0xFF);
    [self.peripheral writeValue:[NSData dataWithBytes:buffer length:4]
              forCharacteristic:self.servoRegisterWrite2Characteristic
                           type:CBCharacteristicWriteWithResponse];
}

- (void) updateSpeed {
    if (self.servoRegisterWrite2Characteristic) {
        [self updateVerticalSpeed];
        // wait a half second and send the other one
        [self performSelector:@selector(updateHorizontalSpeed) withObject:nil afterDelay:0.5];
    }
}

#define MIN_VERTICAL 360
#define MAX_VERTICAL 670
#define MIN_HORIZONTAL 206
#define MAX_HORIZONTAL 818

- (void) moveToCurrentPosition {
    short vertical = (MAX_VERTICAL - MIN_VERTICAL) * (-self.yPosition + 100) / 200.0 + MIN_VERTICAL;
    short horizontal = (MAX_HORIZONTAL - MIN_HORIZONTAL) * (-self.xPosition + 100) / 200.0 + MIN_HORIZONTAL;
                
    swap_bytes(&vertical);
    swap_bytes(&horizontal);
    
    if (self.servoVerticalCharacteristic) {
        [self.peripheral writeValue:[NSData dataWithBytes:&vertical length:2]
                  forCharacteristic:self.servoVerticalCharacteristic
                               type:CBCharacteristicWriteWithResponse];
    }
    
    if (self.servoHorizontalCharacteristic) {
        [self.peripheral writeValue:[NSData dataWithBytes:&horizontal length:2]
                  forCharacteristic:self.servoHorizontalCharacteristic
                               type:CBCharacteristicWriteWithResponse];
    }
}

- (void) position:(CGPoint) point {
    self.xPosition = point.x;
    self.yPosition = point.y;
    [self moveToCurrentPosition];
}


#pragma mark - Start/Stop Scan methods

// Use CBCentralManager to check whether the current platform/hardware supports Bluetooth LE.
- (BOOL) isLECapableHardware
{
    NSString * state = nil;
    switch ([self.manager state]) {
        case CBCentralManagerStateUnsupported:
            state = @"The platform/hardware doesn't support Bluetooth Low Energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            state = @"The app is not authorized to use Bluetooth Low Energy.";
            break;
        case CBCentralManagerStatePoweredOff:
            state = @"Bluetooth is currently powered off.";
            break;
        case CBCentralManagerStatePoweredOn:
            return TRUE;
        case CBCentralManagerStateUnknown:
        default:
            return FALSE;
    }
    NSLog(@"Central manager state: %@", state);
    return FALSE;
}

// Request CBCentralManager to scan for peripherals
- (void) startScan
{
    [self.peripherals removeAllObjects];
    self.peripheral = nil;
    
    // currently iOS6 is failing to scan for the specified service, but we find it when we scan for all devices
    // NSArray *services = [NSArray arrayWithObject:[CBUUID UUIDWithString:@"2A001800-2803-2801-2800-1D9FF2D5C442"]];
    [self.manager scanForPeripheralsWithServices:nil options:nil];
}

// Request CBCentralManager to stop scanning for peripherals
- (void) stopScan
{
    [self.manager stopScan];
}

- (void) clearAllServicesAndCharacteristics
{
    // clear all services and characteristics before discovery
    self.accessProfileService = nil;
    self.manufacturerService = nil;
    self.revolveServoService = nil;
    self.batteryStatusService = nil;
    self.deviceNameCharacteristic = nil;
    self.registerWrite1pCharacteristic = nil;
    self.registerWrite2pCharacteristic = nil;
    self.registerToMonitorCharacteristic = nil;
    self.registerMonitoredValueCharacteristic = nil;
    self.servoHorizontalCharacteristic = nil;
    self.servoVerticalCharacteristic = nil;
    self.servoRegisterWrite1Characteristic = nil;
    self.servoRegisterWrite2Characteristic = nil;
    self.servoRegisterToMonitorCharacteristic = nil;
    self.servoRegisterMonitoredValueCharacteristic = nil;
}

- (void) connectToPeripheralAtIndex:(NSInteger) index
{
    if (self.peripheral) {
        [self.canceledPeripherals addObject:self.peripheral];
        [self.manager cancelPeripheralConnection:self.peripheral];
        self.peripheral = nil;
    }
    
    self.peripheral = [self.peripherals objectAtIndex:index];
    [self.manager connectPeripheral:self.peripheral
                            options:[NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES]
                                                                forKey:CBConnectPeripheralOptionNotifyOnDisconnectionKey]];
    NSString *name = self.peripheral.name;
    if (!name) {
        name = [self.peripheral description];
    }
    self.connectionAlertView = [[UIAlertView alloc]
                                initWithTitle:@"Connecting"
                                message:[NSString stringWithFormat:@"Connecting to %@", name]
                                delegate:self
                                cancelButtonTitle:@"Cancel"
                                otherButtonTitles:nil];
    [self.connectionAlertView show];
}

- (void) alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        if (self.peripheral) {
            [self.canceledPeripherals addObject:self.peripheral];
            [self.manager cancelPeripheralConnection:self.peripheral];
            self.peripheral = nil;
        }
    }
}


#pragma mark - CBCentralManager delegate methods

// Invoked when the central manager's state is updated.
- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    [self isLECapableHardware];
}

// Invoked when the central discovers peripheral while scanning.
- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI
{
    NSString *name = peripheral.name;
    if (!name) {
        name = [peripheral description];
    }
    [self.discoveryRSSIs setObject:RSSI forKey:name];
    if (![self.peripherals containsObject:peripheral]) {
        [self.peripherals addObject:peripheral];
        [self.scanViewController reload];
    }
    // Retrieve already known devices
    //[self.manager retrievePeripherals:[NSArray arrayWithObject:(id)aPeripheral.UUID]];
}

// Invoked when the central manager retrieves the list of known peripherals.
// Automatically connect to first known peripheral
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals
{
    NSLog(@"Retrieved peripheral: %u - %@", [peripherals count], peripherals);
}

// Invoked when a connection is succesfully created with the peripheral.
// Discover available services on the peripheral
- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"connected");
    [self.connectionAlertView dismissWithClickedButtonIndex:-1 animated:NO];
    [self.scanViewController dismissModalViewControllerAnimated:YES];
    [self.actionButton setTitle:@"Disconnect" forState:UIControlStateNormal];
    
    NSString *name = peripheral.name;
    if (!name) {
        name = [peripheral description];
    }
    self.deviceName = name;
    self.deviceNameLabel.text = self.deviceName;
    self.peripheral = peripheral;
    [peripheral setDelegate:self];
    [self clearAllServicesAndCharacteristics];
    [peripheral discoverServices:nil];
}

// Invoked when an existing connection with the peripheral is torn down.
// Reset local variables
- (void) centralManager:(CBCentralManager *)central
didDisconnectPeripheral:(CBPeripheral *)aPeripheral
                  error:(NSError *)error
{
    if (self.peripheral) {
        [self.peripheral setDelegate:nil];
        self.peripheral = nil;
    }
    [self clearAllServicesAndCharacteristics];
    self.deviceName = @"Kubi Not Connected";
    self.deviceNameLabel.text = self.deviceName;
    [self hideAccessories:YES];
    [self.actionButton setTitle:@"Scan" forState:UIControlStateNormal];
    self.view.backgroundColor = DISCONNECTED_BACKGROUND_COLOR;
}

// Invoked when the central manager fails to create a connection with the peripheral.
- (void) centralManager:(CBCentralManager *)central
didFailToConnectPeripheral:(CBPeripheral *)aPeripheral
                  error:(NSError *)error
{
    NSLog(@"Fail to connect to peripheral: %@ with error = %@", aPeripheral, [error localizedDescription]);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection Failed"
                                                    message:@"Unable to Connect to device"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    if (self.peripheral) {
        [self.canceledPeripherals addObject:self.peripheral];
        self.peripheral = nil;
    }
}

#pragma mark - CBPeripheral delegate methods

// Invoked upon completion of a -[discoverServices:] request.
// Discover available characteristics on interested services
- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    if (peripheral != self.peripheral) {
        NSString *name = peripheral.name;
        if (!name) {
            name = [peripheral description];
        }
        NSLog(@"received services for inactive peripheral (%@)", name);
        return;
    }
    
    for (CBService *service in peripheral.services) {
        NSLog(@"Service found with UUID: %@", service.UUID.data);
        if ([service.UUID isEqual:ACCESS_PROFILE_UUID]) {
            self.accessProfileService = service;
        } else if ([service.UUID isEqual:MANUFACTURER_UUID]) {
            self.manufacturerService = service;
        } else if ([service.UUID isEqual:REVOLVE_SERVO_UUID]) {
            self.revolveServoService = service;
        } else if ([service.UUID isEqual:BATTERY_STATUS_UUID]) {
            self.batteryStatusService = service;
        } else {
            NSLog(@"UNKNOWN UUID: %@", service.UUID);
        }
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

/*
 Invoked upon completion of a -[discoverCharacteristics:forService:] request.
 */
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service
             error:(NSError *)error
{
    if (error) {
        NSLog(@"Discovered characteristics for %@ with error: %@", service.UUID, [error localizedDescription]);
        return;
    }
    
    NSString *name = peripheral.name;
    if (!name) {
        name = [peripheral description];
    }
    NSLog(@"Discovered characteristics for %@:%@ ", name, service.UUID);
    if (service == self.accessProfileService) {
        for (CBCharacteristic * characteristic in service.characteristics) {
            NSLog(@"Discovered characteristic: %@", characteristic.UUID.data);
            if ([characteristic.UUID isEqual:DEVICE_NAME_UUID]) {
                self.deviceNameCharacteristic = characteristic;
            }
            //[self.peripheral discoverDescriptorsForCharacteristic:characteristic];
        }
    } else if (service == self.manufacturerService) {
        for (CBCharacteristic * characteristic in service.characteristics) {
            NSLog(@"Discovered characteristic: %@", characteristic.UUID.data);
            //[self.peripheral discoverDescriptorsForCharacteristic:characteristic];
        }
    } else if (service == self.revolveServoService) {
        for (CBCharacteristic * characteristic in service.characteristics) {
            NSLog(@"Discovered characteristic: %@", characteristic.UUID.data);
            
            if ([characteristic.UUID isEqual:REGISTER_WRITE1P_UUID]) {
                self.servoRegisterWrite1Characteristic = characteristic;
            } else if ([characteristic.UUID isEqual:REGISTER_WRITE2P_UUID]) {
                self.servoRegisterWrite2Characteristic = characteristic;
            } else if ([characteristic.UUID isEqual:REGISTER_TOMONITOR_UUID]) {
                self.servoRegisterToMonitorCharacteristic = characteristic;
            } else if ([characteristic.UUID isEqual:REGISTER_MONITOREDVALUE_UUID]) {
                self.servoRegisterMonitoredValueCharacteristic = characteristic;
            } else if ([characteristic.UUID isEqual:SERVO_HORIZONTAL_UUID]) {
                self.servoHorizontalCharacteristic = characteristic;
            } else if ([characteristic.UUID isEqual:SERVO_VERTICAL_UUID]) {
                self.servoVerticalCharacteristic = characteristic;
            }
            
            if (self.servoHorizontalCharacteristic &&
                self.servoVerticalCharacteristic &&
                self.servoRegisterWrite1Characteristic &&
                self.servoRegisterWrite2Characteristic &&
                self.servoRegisterToMonitorCharacteristic &&
                self.servoRegisterMonitoredValueCharacteristic) {
                self.view.backgroundColor = CONNECTED_BACKGROUND_COLOR;
                
                
                
                
                [self updateSpeed];
            }
            [self.peripheral discoverDescriptorsForCharacteristic:characteristic];
        }
    } else if (service == self.batteryStatusService) {
        for (CBCharacteristic * characteristic in service.characteristics) {
            NSLog(@"Discovered characteristic: %@", characteristic.UUID.data);
            //[self.peripheral discoverDescriptorsForCharacteristic:characteristic];
        }
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverDescriptorsForCharacteristic:(CBCharacteristic *)characteristic
              error:(NSError *)error {
    NSLog(@"DID DISCOVER DESCRIPTORS");
    for (CBDescriptor *descriptor in characteristic.descriptors) {
        NSLog(@"discovered descriptor %@ (%@) for characteristic %@", [descriptor description], [descriptor value], characteristic.UUID);
    }
}

/*
 Invoked upon completion of a -[readValueForCharacteristic:] request or on the reception of a notification/indication.
 */
- (void) peripheral:(CBPeripheral *)peripheral
didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
              error:(NSError *)error
{
    if (error)
    {
        NSLog(@"Error updating value for characteristic %@ error: %@", characteristic.UUID, [error localizedDescription]);
        return;
    }
    
    if (characteristic == self.deviceNameCharacteristic) {
        
        NSLog(@"received device name: %@", characteristic.value);
    }
}

- (void)peripheral:(CBPeripheral *)peripheral
didWriteValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error {
    if (error) {
            NSLog(@"didWriteValueWithError:%@", [error description]);
    }

    
}

@end
