//
//  BTDeviceInfo.h
//  skyBle
//
//  Created by sky on 14-8-1.
//  Copyright (c) 2014年 sky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHDevicePluginProfiles.h"
#import "IBGattDevice.h"
#import "BTUserInfo.h"

@interface BTDeviceInfo : IBGattDevice


@property(nullable,nonatomic, strong) NSString *password;            //密码
@property(nullable,nonatomic, strong) NSString *broadcastId;         //广播ID
@property(nullable,nonatomic, strong) NSString *protocolType;        //协议类型
@property(nullable,nonatomic, strong) NSString *timezone;            //设备时区
@property(nullable,nonatomic, strong) NSString *peripheralIdentifier;//系统蓝牙设备的id,可以唯一表示一个设备
@property(nullable,nonatomic, strong) NSString *macAddress;          //设备mac地址
@property(nullable,nonatomic, strong) NSNumber *rssi;                //信号强度
@property(nullable,nonatomic, strong) NSArray  *services;            //设备gatt服务列表
@property(nullable,nonatomic, strong) NSString *reverseMac;          //反序的设备mac地址
@property(nullable,nonatomic, strong) BTUserInfo *userInfo;          //用户信息
@property(nullable,nonatomic, strong) NSString *deviceUnit;         //设备测量单位

@property(nonatomic, assign) BTDeviceType deviceType;                //设备类型
@property(nonatomic, assign) NSInteger maxUserQuantity;              //最大用户数
@property(nonatomic, assign) NSUInteger deviceUserNumber;            //设备当前的用户编号
@property(nonatomic, assign) int battery;                            //设备电量
@property(nonatomic, assign) int heartRate;                          //广播数据包里的当前心率

@property(nonatomic, assign) BOOL isUpgrading;                       //是否正在升级
@property(nonatomic, assign) BOOL isInSystem;                        //是否在系统列表中
@property(nonatomic, assign) BOOL preparePair;                       //是否处于配对状态
@property(nonatomic, assign) BOOL isRegistered;                      //是否已注册,互联秤的广播内容
@property(nonatomic, assign) BOOL delayDisconnect;                   //延时断开
@property(nonatomic, assign) BOOL loginReset;                        //登录重置
@property(nonatomic, assign) BOOL syncAllData;                       //是否同步所有数据,不区分用户，默认为YES
@property(nonatomic,assign)NSUInteger fileType;                      //文件类型

/**
 * 设备关键信息概述
 */
-(NSString *_Nonnull)keyWords;

/**
 * 设备版本信息
 */
-(NSString *_Nonnull)versionInfo;

/**
 * 广播服务信息
 */
-(NSString *_Nonnull)serviceStringValue;

/**
 * 对象信息
 */
-(NSString *_Nonnull)toString;

@end




