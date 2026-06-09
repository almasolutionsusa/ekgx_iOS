//
//  IDeviceSetting.h
//  ByteTest
//
//  Created by sky on 2020/3/20.
//  Copyright © 2020 sky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BTUserInfo.h"
#import "BTDeviceData.h"


@interface BTDeviceSetting : NSObject

@property(nonatomic,assign)NSUInteger cmd;               //CMD
@property(nonatomic,strong)NSString *broadcastId;        //设备广播ID
@property(nonatomic,strong)NSString *msgKey;             //消息Key
@property(nonatomic,strong)NSString *deviceModel;        //设备型号，用于区分指令下发所定义的CMD
@property(nonatomic,strong)NSData *cmdBytes;             //当前指令数据包

-(NSData *)encodeCmdBytes;

-(NSData *)formatBytes:(NSData *)cmdBytes;

-(NSData *)formatBpmPacket:(NSData *)cmdBytes;
@end


#pragma mark - AHSpO2SyncSetting

@interface AHSpO2SyncSetting : BTDeviceSetting

/**
 * 是否打开数据同步
 */
@property(nonatomic,assign)  BOOL enable;
@end

#pragma mark - AHSpO2AlarmSetting

@interface AHSpO2AlarmSetting : BTDeviceSetting

/**
 * 设置选项
 * 0 读取警报信息
 * 1 设置警报信息
 */
@property(nonatomic,assign)  int option;

/**
 * 警报信息
 */
@property(nonatomic,strong)  AHSpO2Alarm *alarm;
@end


#pragma mark - AHTemperatureSetting

@interface AHTempSetting : BTDeviceSetting

/**
 * 测温模式
 */
@property(nonatomic,assign) AHTempMode mode;

/**
 * 测量单位
 * 0x00 摄氏度°C
 * 0x01 华氏度°F
 */
@property(nonatomic,assign) int unit;

/**
 *  根据指令初始化实例对象
 */
-(instancetype)initWithCmd:(AHTempCmd)opCmd;
@end

#pragma mark - AHBloodPressureSetting

/**
 * 血压计数据同步设置
 */
@interface AHBpmSyncSetting  : BTDeviceSetting
/**
 * 用户编号
 */
@property(nonatomic,assign) int userNum;

/**
 * 是否同步所有用户的数据
 */
@property(nonatomic,assign) BOOL syncAll;
@end


/**
 * 血压计数据删除设置
 */
@interface AHBpmRemoveSetting  : BTDeviceSetting
/**
 * 用户编号
 */
@property(nonatomic,assign) int userNum;

/**
 * 是否删除所有用户的数据
 */
@property(nonatomic,assign) BOOL removeAll;
@end


/**
 * 血压计功能设置
 */
@interface AHBpmConfigSetting : BTDeviceSetting

/**
 * 配置类型
 */
@property(nonatomic,assign)  AHBpmConfig config;

/**
 * 设置时间
 */
@property(nonatomic,strong)  NSData *utcBytes;

/**
 * 用户编号
 * 0x01 切换到用户 1
 * 0x02 切换到用户 2
 */
@property(nonatomic,assign)  int user;

/**
 * 语音 开关控制
 * 0x01 允许语音播报
 * 0x00 关闭语音播报
 */
@property(nonatomic,assign)  BOOL voiceState;
@end


#pragma mark - AHCGMSetting

/**
 * 血糖仪功能设置指令
 */
@interface AHCGMSetting : BTDeviceSetting


/**
 * 测量间隔
 * 示例：
 * 0x01：1分钟；
 * 0x05: 5分钟
 * 0x3C: 最大为60分钟
 */
@property(nonatomic,assign) int interval;

/**
 *  根据指令初始化实例对象
 */
-(instancetype)initWithCmd:(AHCGMCmd)cmd;
@end
