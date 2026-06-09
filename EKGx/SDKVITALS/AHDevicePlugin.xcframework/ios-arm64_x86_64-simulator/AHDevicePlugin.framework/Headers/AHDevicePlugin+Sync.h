//
//  AHDevicePlugin+Sync.h
//  BTBluetoothPlugin-Demo
//
//  Created by sky on 2019/11/8.
//  Copyright © 2019 sky. All rights reserved.
//

#import "AHDevicePlugin.h"

@class IBGattClient;

@interface AHDevicePlugin (Sync)


@property(nonatomic,assign)NSUInteger syncStatus;

/**
 * 获取设备列表
 */
-(NSArray *)getDevices;

/**
 * Added in version 2.0.0
 * 设置测量设备列表
 */
-(BOOL)setDevices:(NSArray *)list;

/**
 * Added in version 2.0.0
 * 添加单个测量设备
 */
-(BOOL)addDevice:(BTDeviceInfo *)lsDevice;


/**
 * Added in version 2.0.0
 * 根据广播ID删除单个测量设备
 */
-(BOOL)removeDevice:(NSString *)broadcastId;

/**
 * Added in version 2.0.0
 * 启动测量数据接收服务
 */
-(BOOL)startAutoConnect:(id<AHDeviceDataDelegate>)delegate;

/**
 * Added in version 2.0.0
 * 停止测量数据接收服务
 */
-(BOOL)stopAutoConnect;

/**
 * Added in version 2.0.0
 * 根据设备广播ID查询GattClient
 */
-(IBGattClient *)getDeviceSyncWorker:(NSString *)broadcastId;

@end
