//
//  AHDevicePlugin+Pair.h
//  BTBluetoothPlugin-Demo
//
//  Created by sky on 2019/11/8.
//  Copyright © 2019 sky. All rights reserved.
//

#import "AHDevicePlugin.h"



@interface AHDevicePlugin (Pair)

@property(nonatomic,strong)NSMutableDictionary * _Nullable pairingDelegateMap;

/**
 * Added in version 2.0.0
 * 绑定设备
 */
-(BOOL)pairDevice:(BTDeviceInfo *_Nonnull)lsDevice
         delegate:(id<AHDevicePairingDelegate> _Nonnull)pairedDelegate;

/**
 * Added in version 2.0.0
 * 取消设备的配对操作
 */
-(void)cancelDevicePairing:(BTDeviceInfo *_Nonnull)lsDevice;

@end

