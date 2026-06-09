//
//  BTDevicePairingDelegate.h
//  BTBluetooth-Test
//
//  Created by sky on 14-8-13.
//  Copyright (c) 2014年 com.sky.ble. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTDeviceInfo.h"
#import "BTDevicePairMsg.h"


@protocol AHDevicePairingDelegate <NSObject>

/**
 * 设备配对结果
 */
@required
-(void)bleDevice:(BTDeviceInfo *)device didPairStateChanged:(BTPairState)state;

/**
 * 在设备绑定或配对过程中，操作指令更新结果回调
 */
@optional
-(void)bleDevice:(BTDeviceInfo *)lsDevice didPairMessageUpdate:(BTDevicePairMsg *)pairMsg;
@end
