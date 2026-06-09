//
//  CRBlueToothManager.h
//  PC300SDKDemo
//
//  Created by Creative on 2018/2/1.
//  Copyright © 2018年 creative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRBleDevice.h"

@class CCRBlueToothManager;
/** SDK working mode */
typedef NS_ENUM(NSUInteger, CRBLESDKWorkMode)
{
    CRBLESDKWorkModeForeground = 0,
    CRBLESDKWorkModeBackground,
};

/** The error codes that connect to device failed */
typedef NS_ENUM(int, CRBLESDKConnectError)
{
    /* Device is empty */
    CRBLESDKConnectErrorDeviceIsNil = 90000,
    /* The device is not PC100 */
    CRBLESDKConnectErrorDeviceNotFit = 90001,
    /* Connected device status */
    CRBLESDKConnectErrorDeviceConnected = 90002,
};


@protocol CRBlueToothManagerDelegate <NSObject>
@optional
#pragma mark - --------------------------- Device scanning and connection

/** BLE state updated */
- (void)bleManager:(CCRBlueToothManager *)manager didUpdateState:(CBManagerState)state;

/** Scan completed */
- (void)bleManager:(CCRBlueToothManager *)manager didSearchCompleteWithResult:(NSArray <CRBleDevice *>*)deviceList;

/** Device successfully connected */
- (void)bleManager:(CCRBlueToothManager *)manager didConnectDevice:(CRBleDevice *)device;
/** Successfully disconnected the device */
- (void)bleManager:(CCRBlueToothManager *)manager didDisconnectDevice:(CRBleDevice *)device Error:(NSError *)error;
/** Failed to connect to device */
- (void)bleManager:(CCRBlueToothManager *)manager didFailToConnectDevice:(CRBleDevice *)device Error:(NSError *)error;
/** Found the device */
- (void)bleManager:(CCRBlueToothManager *)manager didFindDevice:(NSArray <CRBleDevice *>*)deviceList;

@end
@interface CCRBlueToothManager : NSObject
/** Delegate  */
@property (nonatomic, weak) id <CRBlueToothManagerDelegate>delegate;
/** The current working mode of SDK  */
@property (nonatomic, assign,readonly) CRBLESDKWorkMode modeState;
/** The working state of Bluetooth  */
@property (nonatomic, assign,readonly) CBManagerState state;
/** Connected device */
@property (nonatomic, strong) NSMutableDictionary *connectedDevices;

+(instancetype)shareInstance;

#pragma mark - --------------------------- Device management
/** Scanning devices */
- (void)startSearchDevicesForSeconds:(NSUInteger)seconds;
/** Stop searching */
- (void)stopSearch;
/** Connect the device */
- (void)connectDevice:(CRBleDevice *)device;

/** Disonnect and reconnect the device */
- (void)reconnectDevice:(CRBleDevice *)device;

/** Disconnect */
- (void)disconnectDevice:(CRBleDevice *)device;

/** Set the working mode of the SDK */
- (void)setWorkMode:(CRBLESDKWorkMode)mode;

//TODO
/** Scan a specified device --> 95 seconds disconnect and reconnect test */
//Fed in information about previously connected devices.
//-(void)scanForPeripheralsWithSerivesPeripheral:(CBPeripheral *)connectedPeripheral;


@end
