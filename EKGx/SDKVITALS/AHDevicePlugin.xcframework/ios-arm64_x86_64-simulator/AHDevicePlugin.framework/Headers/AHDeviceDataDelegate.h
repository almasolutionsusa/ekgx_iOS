//
//  BTDeviceDataDelegate.h
//  AOJDevicePlugin-Library
//
//  Created by sky on 2017/2/28.
//  Copyright © 2017年 sky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTDeviceInfo.h"
#import "BTDeviceData.h"

@protocol AHDeviceDataDelegate <NSObject>

/**
 * 连接状态改变
 */
@required
-(void)bleDevice:(BTDeviceInfo *)device didConnectStateChanged:(BTConnectState)state;

/**
 * 设备版本信息更新
 */
@optional
-(void)bleDeviceDidInformationUpdate:(BTDeviceInfo *)device;


/**
 * 设备在测量过程或出现错误时，上报的消息通知数据
 */
@optional
-(void)bleDevice:(BTDeviceInfo *)device didDataUpdateNotification:(BTDeviceData *)obj;

@end
