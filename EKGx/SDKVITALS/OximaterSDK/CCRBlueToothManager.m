//
//  CRBlueToothManager.m
//  PC300SDKDemo
//
//  Created by Creative on 2018/2/1.
//  Copyright © 2018年 creative. All rights reserved.
//

#import "CCRBlueToothManager.h"
#import "CRAP20SDK.h"
@interface CCRBlueToothManager ()<CBCentralManagerDelegate,CBPeripheralDelegate>
/** The central */
@property (nonatomic, strong) CBCentralManager *centralManager;
/** Scan duration timer */
@property (nonatomic, weak) NSTimer *searchTimer;
/** Search for a collection of matching, to-be-connected devices */
@property (nonatomic, strong) NSMutableArray <CRBleDevice *> *fitDevices;
/** Timeout timer for devices being connected */
@property (nonatomic, strong) NSMutableDictionary <NSString *,NSTimer *> *outTimers;

@end

@implementation CCRBlueToothManager

-(NSMutableArray *)fitDevices
{
    if (!_fitDevices)
        _fitDevices = [NSMutableArray array];
    return _fitDevices;
}

- (NSMutableDictionary<NSString *,NSTimer *> *)outTimers
{
    if (!_outTimers)
        _outTimers = [NSMutableDictionary dictionary];
    return _outTimers;
}

- (NSMutableDictionary *)connectedDevices
{
    if (!_connectedDevices)
        _connectedDevices = [NSMutableDictionary dictionary];
    return _connectedDevices;
}

- (CBManagerState)state
{
    return self.centralManager.state;
}
//
+(instancetype)shareInstance
{
    static CCRBlueToothManager *manager;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        manager = [[CCRBlueToothManager alloc] init];
        [manager initManager];
    });
    return manager;
}

- (void)initManager
{
    self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
}
#pragma mark Set working mode
- (void)setWorkMode:(CRBLESDKWorkMode)mode
{
    if ((mode == CRBLESDKWorkModeForeground) && (_modeState == CRBLESDKWorkModeBackground))
    {
        if (self.centralManager.isScanning)
        {
            [self stopSearch];
            _modeState = mode;
            [self startSearchDevicesForSeconds:5];
        }
    }
    _modeState = mode;
}

#pragma mark - --------------------------- Business Logic
#pragma mark -
#pragma mark  Start Search
- (void)startSearchDevice
{
    if (self.centralManager.isScanning)
    {
        return;
    }
    int waitTime = 0;
    if (self.centralManager.state != CBManagerStatePoweredOn)
        waitTime = 1;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.centralManager scanForPeripheralsWithServices:@[] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@YES}];
        //    [self.centralManager scanForPeripheralsWithServices:nil options:nil];
    });
    
}
#pragma mark Scanning device
- (void)startSearchDevicesForSeconds:(NSUInteger)seconds
{
    if ([self.centralManager isScanning])
    {
        [self stopSearch];
    }
    [self.fitDevices removeAllObjects];
    NSUInteger realSeconds = seconds;
    // Judge some strange parameters
    if (seconds <= 0)
        realSeconds = 5;
    // Start scanning
    [self startSearchDevice];
    // Timing
    if (_modeState == CRBLESDKWorkModeForeground)
    {
        _searchTimer = [NSTimer scheduledTimerWithTimeInterval:realSeconds target:self selector:@selector(finishSearch) userInfo:nil repeats:NO];
    }
}
#pragma mark Stop searching
- (void)stopSearch
{
    [_searchTimer invalidate];
    [self.centralManager stopScan];
}
#pragma mark Search completed
- (void)finishSearch
{
    [_searchTimer invalidate];
    [self.centralManager stopScan];
    //2.Tell the delegate that the search is complete
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleManager:didSearchCompleteWithResult:)])
        [self.delegate bleManager:self didSearchCompleteWithResult:self.fitDevices];
}
#pragma mark Connecting Devices
- (void)connectDevice:(CRBleDevice *)device
{
    // Stop scanning
    [self  stopSearch];
    if (!device)
    {
        if (_delegate && [_delegate respondsToSelector:@selector(bleManager:didFailToConnectDevice:Error:)])
        {
            [_delegate bleManager:self didFailToConnectDevice:device Error:[NSError errorWithDomain:NSCocoaErrorDomain code:CRBLESDKConnectErrorDeviceIsNil userInfo:@{NSLocalizedDescriptionKey:@"Device cannot be nil"}]];
        }
        return;
    }
    device.connectionState = CRBLESDKConnectionStateConnecting;
    [self.centralManager connectPeripheral:device.peripheral options:nil];
    [self startOutTimerForDevice:device];
}

#pragma mark Disconnect and reconnect
- (void)reconnectDevice:(CRBleDevice *)device{
    [self.fitDevices addObject:[[CRBleDevice alloc] initDeviceWithPeripheral:device.peripheral BLEName:device.peripheral.name] ];
    [self connectDevice:device];
}


#pragma mark Disconnect
- (void)disconnectDevice:(CRBleDevice *)device
{
    if (!device)
        return;
    if([device.peripheral.name containsString:pc100] || [device.peripheral.name containsString:pc200] || [device.peripheral.name containsString:pc300])
    {
        //       [[CRPC_300SDK shareInstance] performSelector:@selector(deviceWillDisconnect)];
    }
    else if ([device.peripheral.name containsString:pc_68b] || [device.peripheral.name containsString:pc_60nw] || [device.peripheral.name containsString:pod] || [device.peripheral.name containsString:sp_20] || [device.peripheral.name containsString:ap_10] || [device.peripheral.name containsString:ap_20])
    {
        //        [[CRAP20SDK shareInstance] performSelector:@selector(deviceWillDisconnect)];
    }
    else if([device.peripheral.name containsString:pc80b])
    {
        
    }
    [self stopSearch];
    [_centralManager cancelPeripheralConnection:device.peripheral];
}

#pragma  mark Timeout processing
/** Get the timeout timer according to the device */
- (NSTimer *)getOutTimerForDevice:(CRBleDevice *)device
{
    NSString *key = [self getKeyStringForPeripheral:device.peripheral];
    return self.outTimers[key];
}

/** Start the timeout timer according to the device */
- (void)startOutTimerForDevice:(CRBleDevice *)device
{
    // Timer already exists
    NSTimer *timer = [self getOutTimerForDevice:device];
    if (timer)
        return;
    // Start the timer and store it in self.outTimers
    NSString *key = [self getKeyStringForPeripheral:device.peripheral];
    timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(handleConnectionOutTimeWithTimer:) userInfo:device repeats:NO];
    [self.outTimers setObject:timer forKey:key];
}

/** Stop the timeout timer according to the device */
- (void)stopOutTimerForDevice:(CRBleDevice *)device
{
    NSTimer *timer = [self getOutTimerForDevice:device];
    if (timer)
    {
        CRBleDevice *device = timer.userInfo;
        [timer invalidate];
        NSString *key = [self getKeyStringForPeripheral:device.peripheral];
        [self.outTimers removeObjectForKey:key];
    }
}


- (void)handleConnectionOutTimeWithTimer:(NSTimer *)timer
{
    CRBleDevice *device = timer.userInfo;
    NSError *error = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"Connection OutTime"}];
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleManager:didFailToConnectDevice:Error:)])
    {
        [self.delegate bleManager:self didFailToConnectDevice:device Error:error];
    }
    // Connection timed out, remove the set to be connected
    [self.fitDevices removeAllObjects];
    [self stopOutTimerForDevice:device];
}

//#pragma mark - 95 seconds to reconnect
///** Scan a specified device --> 95 seconds disconnect and reconnect test */
////Fed in information about previously connected devices.
//-(void)scanForPeripheralsWithSerivesPeripheral:(CBPeripheral *)connectedPeripheral{
//    NSString *serviceID = [self getServiceIDForPeriName:connectedPeripheral.name];
//    CBUUID *deviceUUID =  [CBUUID UUIDWithString:serviceID];
//    [_centralManager scanForPeripheralsWithServices:@[deviceUUID] options:@{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)}];
//}


#pragma mark - --------------------------- centralManager Delegate
#pragma mark -
#pragma mark Central manager status
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state)
    {
        case CBManagerStateUnknown:
            //CRLog(@"CBManagerStateUnknown");
            break;
        case CBManagerStateResetting:
            //CRLog(@"CBManagerStateResetting");
            break;
        case CBManagerStateUnsupported:
            //CRLog(@"CBManagerStateUnsupported");
            break;
        case CBManagerStateUnauthorized:
            //CRLog(@"CBManagerStateUnauthorized");
            break;
        case CBManagerStatePoweredOff:
            //CRLog(@"CBManagerStatePoweredOff");
            break;
        case CBManagerStatePoweredOn:
            //CRLog(@"CBManagerStatePoweredOn");
            break;
        default:
            break;
    }
    if (_delegate && [_delegate respondsToSelector:@selector(bleManager:didUpdateState:)])
        [_delegate bleManager:self didUpdateState:central.state];
}
#pragma mark Found the device
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary<NSString *,id> *)advertisementData RSSI:(NSNumber *)RSSI
{
    //    NSLog(@"%@",peripheral.name);
    // Avoid a repeat of joining the same device
    for (CRBleDevice *device in self.fitDevices)
    {
        if (device.peripheral == peripheral )
            return;
    }
    // 🚫ZSY--TODO
    NSString *localName = [advertisementData objectForKey:@"kCBAdvDataLocalName"];
    localName = localName?localName:@"NULL";
    
    [self.fitDevices addObject:[[CRBleDevice alloc] initDeviceWithPeripheral:peripheral BLEName:localName] ];
    
    if (_modeState == 1)
    {
        if (_delegate &&[_delegate respondsToSelector:@selector(bleManager:didFindDevice:)])
        {
            [_delegate bleManager:self didFindDevice:self.fitDevices];
        }
    }
}
#pragma mark Connect the device
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
//    CRBleDevice *device = [self getFitDeviceForPeripheral:peripheral];
//    if (device.peripheral == peripheral)
//    {
        // Remove timeout timer
    NSLog(@"-----didConnectPeripheral----");
        NSString *key = [self getKeyStringForPeripheral:peripheral];
        [self.outTimers[key] invalidate];
    
        peripheral.delegate = self;
        [peripheral discoverServices:nil];
        return;
//    }
}

#pragma mark Disconnect
-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(nonnull CBPeripheral *)peripheral error:(nullable NSError *)error
{
    // Remove the device from the Connected list
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleManager:didDisconnectDevice:Error:)])
    {
        [self.delegate bleManager:self didDisconnectDevice:[self getConnectedDeviceForPeripheral:peripheral] Error:error];
        [self.connectedDevices removeObjectForKey:[self getKeyStringForPeripheral:peripheral]];
    }
}
#pragma mark Connection failed
- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    // Remove the device from the Connected list
    if (self.delegate && [self.delegate respondsToSelector:@selector(bleManager:didFailToConnectDevice:Error:)])
    {
        [self.delegate bleManager:self didFailToConnectDevice:[self getConnectedDeviceForPeripheral:peripheral] Error:error];
    }
    
}
#pragma mark - --------------------------- peripheral Delegate
#pragma mark -
#pragma mark Discovery Device Service
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSLog(@"-- Discovery Device Service --");
    
    NSArray *services = nil;
    if (error != nil)
    {
        //CRLog(@"Error %@\n", error);
        return ;
    }
    services = [peripheral services];
    if (!services || ![services count])
    {
        //CRLog(@"No Services");

        return ;
    }
    // Case-by-case handling service UUID
    [self handleDifferentDevice:peripheral ForService:services];
}

#pragma mark Sub-equipment handling services
- (void)handleDifferentDevice:(CBPeripheral *)peripheral ForService:(NSArray<CBService *> *)services
{
    // Obtaining specified service name based on the device name
    NSString *serviceID = [self getServiceIDForPeriName:peripheral.name];
    // If not, return
    if (!serviceID)
        return;
    // Search for characteristic values in the service
    [self discoverCharaterForServiceID:serviceID FromServices:services periperal:peripheral];
}

/* Search for the specified service name from different devices */
- (NSString *)getServiceIDForPeriName:(NSString *)periName
{
    if ([periName containsString:pc_60nw] && ![periName containsString:pc_60nw_1])
    {
//        return @"49535343-FE7D-4AE5-8FA9-9FAFD205E455";
        return @"FFF0";
    }
    if ([periName containsString:ap_10] || [periName containsString:ap_20] || [periName containsString:pc_60nw_1] || [periName containsString:h600] || [periName containsString:pc_68b] || [periName containsString:pod])
        return @"FFB0";
    else if ([periName containsString:sp_20] || [periName containsString:pc300] || [periName containsString:pc200] || [periName containsString:pc100] || [periName containsString:pc80b] || [periName containsString:eBody_Scale] || [periName containsString:pc_66b])
        return @"FFF0";
    if ([periName containsString:pc_60f] || [periName containsString:OxySmart] || [periName containsString:BabyOximeter] || [periName containsString:OxyKnight]|| [periName containsString:pc_60e])
        return @"6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
    return nil;
}

/* Iterate over Service array, and find its specified service and characteristic value. */
- (void)discoverCharaterForServiceID:(NSString *)serviceID FromServices:(NSArray<CBService *> *)services periperal:(CBPeripheral *)peri
{
    // Iterate over Service array
    for (CBService *service in services)
    {
        if ([service.UUID isEqual:[CBUUID UUIDWithString:serviceID]])
            [peri discoverCharacteristics:nil forService:service];
    }
}

#pragma mark Discover the characteristic values of the specified service
- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if (error != nil)
    {
        //CRLog(@"Error %@\n", error);
        return ;
    }
    // Find the corresponding device
    CRBleDevice *device = [self getFitDeviceForPeripheral:peripheral];
    if (!device)
        return;
    // Save characteristic values
    [self handleCharacteristicsForService:service device:device];
}

- (void)handleCharacteristicsForService:(CBService *)service device:(CRBleDevice *)device
{
    NSArray *characteristics = [service characteristics];
    //PC100，PC200，PC300，PC80B
    if ([device.peripheral.name containsString:pc100] || [device.peripheral.name containsString:pc200] || [device.peripheral.name containsString:pc300] || [device.peripheral.name containsString:pc80b] || [device.peripheral.name containsString:pc_66b] || [device.peripheral.name containsString:sp_20 ])
    {
        // Save characteristic values
        for (CBCharacteristic *cha in characteristics)
        {
            // Notification characteristic, subscribe
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF1"]])
                [device.peripheral setNotifyValue:YES forCharacteristic:cha];
            // write characteristic, save
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF2"]])
                device.writeCharact = cha;
        }
        return;
    }
    if ([device.peripheral.name containsString:pc_60nw] || [device.peripheral.name containsString:h600] || [device.peripheral.name containsString:pc_68b] || [device.peripheral.name containsString:pod] || [device.peripheral.name containsString:ap_10] || [device.peripheral.name containsString:ap_20])
    {
        // Both pc_60nw and pc_60nw_1 can be entered here, here is the distinction that does not contain the bits FFF1 and FFF2 of pc_60nw_1
        if (![device.peripheral.name containsString:pc_60nw_1] && [device.peripheral.name containsString:pc_60nw])
        {
            // Save characteristic value
            for (CBCharacteristic *cha in characteristics)
            {
                if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF1"]])             // Notification characteristic, subscribe
                    [device.peripheral setNotifyValue:YES forCharacteristic:cha];
                if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF2"]])               // write characteristic, save
                    device.writeCharact = cha;
            }
            return;
        }
        // Save characteristic value
        for (CBCharacteristic *cha in characteristics)
        {
            // Notification characteristic, subscribe
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFB2"]])
            {
                [device.peripheral setNotifyValue:YES forCharacteristic:cha];
                // write characteristic, save
                device.writeCharact = cha;
            }
        }
        return;
    }
    if ([device.peripheral.name containsString:eBody_Scale])
    {
        // Save characteristic value
        for (CBCharacteristic *cha in characteristics)
        {
            // Notification characteristic, subscribe
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"FFF4"]])
                [device.peripheral setNotifyValue:YES forCharacteristic:cha];
        }
        return;
    }
    if ([device.peripheral.name containsString:pc_60f] || [device.peripheral.name containsString:OxySmart] || [device.peripheral.name containsString:BabyOximeter]|| [device.peripheral.name containsString:OxyKnight]|| [device.peripheral.name containsString:pc_60e])
    {
        // Save characteristic value
        for (CBCharacteristic *cha in characteristics)
        {
            // Notification characteristic, subscribe
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"6E400003-B5A3-F393-E0A9-E50E24DCCA9E"]])
                [device.peripheral setNotifyValue:YES forCharacteristic:cha];
            if ([cha.UUID isEqual:[CBUUID UUIDWithString:@"6E400002-B5A3-F393-E0A9-E50E24DCCA9E"]])
                // write characteristic, save
                device.writeCharact = cha;
        }
        return;
    }
}

- (CRBleDevice *)getFitDeviceForPeripheral:(CBPeripheral *)peripheral
{
    CRBleDevice *device;
    for (CRBleDevice *dev in self.fitDevices)
    {
        if (dev.peripheral == peripheral)
        {
            device = dev;
            break;
        }
    }
    return device;
}

- (CRBleDevice *)getConnectedDeviceForPeripheral:(CBPeripheral *)peripheral
{
    if (!peripheral)
        return nil;
    return self.connectedDevices[[NSString stringWithFormat:@"%@-%@",peripheral.name,peripheral.identifier.UUIDString]];
}

- (NSString *)getKeyStringForPeripheral:(CBPeripheral *)peripheral
{
    return [NSString stringWithFormat:@"%@-%@",peripheral.name,peripheral.identifier];
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    
    NSLog(@"--- Here is to discover the service characteristics ---");
    
    NSStringFromSelector(@selector(setName:));
    if (characteristic.isNotifying)
    {
        CRBleDevice *device = [self getFitDeviceForPeripheral:peripheral];
        // Change connection status
        device.connectionState = CRBLESDKConnectionStateConnecting;
        // Join a connected collection
        [self.connectedDevices setObject:device forKey:[NSString stringWithFormat:@"%@-%@",device.peripheral.name,device.peripheral.identifier.UUIDString]];
        // 1. Notify the delegate that the connection is successful
        if (self.delegate &&[self.delegate respondsToSelector:@selector(bleManager:didConnectDevice:)])
        {
            [self.delegate bleManager:self didConnectDevice:device];
        }
        // Connection successful, remove the set to be connected
        [self.fitDevices removeObject:device];

        // 2. Start sending heartbeat packets
    }
}
#pragma mark After the device writes binary data
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(nonnull CBCharacteristic *)characteristic error:(nullable NSError *)error
{
    if (error)
    {
        return;
    }
    [peripheral readValueForCharacteristic:characteristic];
}
#pragma mark Obtain the binary data sent by the device
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSData *data = characteristic.value;
    //NSLog(@"data == %@",data);
    /*   For debugging(-------------------Start) */
    NSUInteger len = data.length;
    Byte *byte = (Byte *)[data bytes];
    NSString *commandString = @"";
    for (int i = 0; i < len; i++)
    {
        NSString *byteS =  [NSString stringWithFormat:@"-%02x",byte[i]];
        commandString =  [commandString stringByAppendingString:byteS];
    }
//    if ([commandString containsString:@"aa-55-53-07-01"])
//    {
//        NSLog(@"%@",commandString);
//
//    }
    /*   For debugging(-------------------End) */
    if (!data || !data.length)
        return;
    CRBleDevice *device = [self getConnectedDeviceForPeripheral:peripheral];
    // If the data is not empty, add data
    // PC100,PC200,PC300 shared
    if ([peripheral.name containsString:pc100] || [peripheral.name containsString:pc200] || [peripheral.name containsString:pc300]){}
        //[[CRPC_300SDK shareInstance] appendingNewData:data FromDevice:device];
    //pc_60nw,pod,ap_20,sp_20, pc_68b shared
    else if ([peripheral.name containsString:pc_60nw] ||[peripheral.name containsString:pod] ||[peripheral.name containsString:ap_10] ||[peripheral.name containsString:ap_20] ||[peripheral.name containsString:sp_20] ||[peripheral.name containsString:pc_68b]||[peripheral.name containsString:pc_66b] ||[peripheral.name containsString:pc_60f] || [device.peripheral.name containsString:OxySmart] || [device.peripheral.name containsString:BabyOximeter]|| [device.peripheral.name containsString:OxyKnight]|| [peripheral.name containsString:pc_60e])
        [[CRAP20SDK shareInstance] appendingNewData:data FromDevice:device];
    else if([peripheral.name containsString:pc80b]){}
        //[[CRPC80BSDK shareInstance] appendingNewData:data FromDevice:device];
    else if([peripheral.name containsString:h600]){}
        //[[CRH600SDK shareInstance] appendingNewData:data FromDevice:device];
    else if ([peripheral.name containsString:eBody_Scale]){}
        //[[CRWeightingScaleSDK shareInstance] appendingNewData:data FromDevice:device];
}


@end

