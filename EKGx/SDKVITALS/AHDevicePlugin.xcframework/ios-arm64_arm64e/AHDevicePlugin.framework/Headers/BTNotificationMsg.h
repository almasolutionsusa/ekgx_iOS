//
//  BTNotificationMsg.h
//  BTBluetoothPlugin-Demo
//
//  Created by sky on 2019/11/13.
//  Copyright © 2019 sky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BTDeviceInfo.h"
#import "AHDevicePluginProfiles.h"

FOUNDATION_EXPORT NSString *const PairDidStateUpdateNotification;
FOUNDATION_EXPORT NSString *const PairDidDataUpdateNotification;

FOUNDATION_EXPORT NSString *const SyncDidStateUpdateNotification;
FOUNDATION_EXPORT NSString *const SyncDidDataUpdateNotification;

FOUNDATION_EXPORT NSString *const OtaDidStateUpdateNotification;
FOUNDATION_EXPORT NSString *const OtaDidDataUpdateNotification;


@interface BTNotificationMsg : NSObject

@property(nonatomic,strong,readonly)NSString *notificationName;

@property(nonatomic,strong)id obj;
@property(nonatomic,strong)BTDeviceInfo *device;
@property(nonatomic,strong)CBPeripheral *peripheral;
@property(nonatomic,assign)BTConnectState state;
@property(nonatomic,assign)NSUInteger mode;
@property(nonatomic,assign)NSUInteger errorCode;
@property(nonatomic,assign)BOOL pushStatus;

/**
 * 根据通知名称，创建通知消息对象
 */
-(instancetype)initWithName:(NSString *)name;


@end

