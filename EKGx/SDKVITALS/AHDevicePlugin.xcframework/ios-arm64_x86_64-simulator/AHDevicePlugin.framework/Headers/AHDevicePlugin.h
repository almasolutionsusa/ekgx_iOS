//
//  AHDevicePlugin.h
//  AOJDevicePlugin-Library
//
//  Created by sky on 2017/3/1.
//  Copyright © 2017年 sky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHDevicePluginProfiles.h"
#import "BTDeviceInfo.h"
#import "AHDevicePairingDelegate.h"
#import "AHDeviceDataDelegate.h"
#import "AHBluetoothStatusDelegate.h"
#import "BTScanFilter.h"

@class IBObject;
@class ICacheControler;
@class IDataControler;

FOUNDATION_EXPORT NSString * _Nonnull const  AHDevicePluginFrameworkVersion;

@interface AHDevicePlugin : NSObject

@property(nonatomic,assign)CBManagerState currentBluetoothState;
@property(nonatomic,strong)id<AHDeviceDataDelegate> dataDelegate;
@property(nonatomic,strong)dispatch_queue_t syncDispatchQueue;

@property(nonatomic,assign,readonly)BOOL isBluetoothPowerOn;
@property(nonatomic,strong,readonly)NSString *versionName;
@property(nonatomic,assign,readonly)NSInteger currentTimeZone;

@property(nonatomic,strong,readonly)IBObject *logger;
@property(nonatomic,assign,readonly)BTManagerState      managerStatus;
@property(nonatomic,strong,readonly)ICacheControler    *cacheControler;
@property(nonatomic,strong,readonly)IDataControler     *dataControler;
@property(nonatomic,strong,readonly)NSMutableDictionary *deviceMap;
@property(nonatomic,strong,readonly)NSMutableDictionary *pushRequestMap;

@property(nonatomic,strong,readonly)NSMutableDictionary *gattClientMap;
@property(nonatomic,strong,readonly)NSMutableArray      *scanType;
@property(nonatomic,strong)id<AHBluetoothStatusDelegate> bleStateDelegate;
@property(nonatomic,assign)BOOL clearScanCache;          //是否清空扫描缓存
@property(nonatomic,strong)NSString *logPath;            //log日志路径

#pragma mark - public methods

/**
 * Added in version 2.0.0
 * 获取实例对象
 */
+(instancetype)defaultPlugin;

/**
 * Added in version 2.0.0
 * 采用系统默认配置的蓝牙初始化
 */
-(void)initPlugin:(dispatch_queue_t)dispatchQueue;

/**
 * Added in version 2.0.0
 * 带可选项的系统蓝牙初始化
 */
-(void)initPluginWithDispatch:(dispatch_queue_t)queue
                       options:(nullable NSDictionary<NSString *, id> *)options;

/**
 * Added in version 2.0.0
 * 将调试信息保存到相应的文件目录中
 */
-(void)saveDebugMessage:(BOOL)enable forFileDirectory:(NSString *_Nonnull)filePath;

/**
 * Added in version 2.0.0
 * 打开调试模式
 */
-(void)openDebugMode:(NSString *_Nonnull)permissionKey;

/**
 * Added in version 2.0.0
 * 在文件中记录调试信息
 */
-(void)appendlog:(NSString *_Nonnull)msg;

/**
 * Added in version 2.0.0
 * 检查手机蓝牙状态
 */
-(void)checkingBluetoothStatus:(id<AHBluetoothStatusDelegate>_Nonnull)bleStatusDelegate;

/**
 * Added in version 2.0.0
 * 根据指定条件搜索设备
 */
-(BOOL)searchDevice:(BTScanFilter *)filter  results:(SearchResultsBlock _Nonnull )block;

/**
 * Added in version 2.0.0
 * 停止搜索
 */
-(BOOL)stopSearch;

/**
 * Added in version 2.0.0
 * 根据广播ID,检查设备当前的连接状态
 */
-(BTConnectState)checkConnectState:(NSString *_Nonnull)broadcastId;

/**
 * Added in version 2.0.0
 * 清空CBPeripheral对象缓存
 */
-(void)clearPeripheralCache;


/**
 * 导出日志文件
 */
-(NSArray *_Nullable)exportLogFiles:(NSString *_Nullable)broadcastId;


@end
