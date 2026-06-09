//
//  BTDeviceData.h
//  BTBluetoothPlugin
//
//  Created by sky on 2020/12/28.
//  Copyright © 2020 sky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHDevicePluginProfiles.h"

/**
 * 体温计测量模式
 */
typedef NS_ENUM(NSUInteger,AHTempMode) {
    AHTempModeUnknown=0x00,
    AHTempModeAdult=0x01,
    AHTempModeChildren=0x02,
    AHTempModeEar=0x03,
    AHTempModeMaterial=0x04,
};

/**
 * 体温计命令字
 */
typedef NS_ENUM(NSUInteger,AHTempCmd) {
    AHTempCmdUnknown=0x00,
    AHTempCmdSyncLatestData=0xD1,
    AHTempCmdSyncTime=0xD2,
    AHTempCmdSyncData=0xD3,
    AHTempCmdClearData=0xD4,
    AHTempCmdQueryStatus=0xD5,
    AHTempCmdConfigMode=0xD6,
    AHTempCmdNewSyncTime=0xD8,
    AHTempCmdNewSyncData=0xD9,
    AHTempCmdStartMeasuring=0xDA,

    
    AHTempCmdStartMeasuringResp=0xC1,
    AHTempCmdSyncTimeResp=0xC2,
    AHTempCmdSyncDataResp=0xC3,
    AHTempCmdClearDataResp=0xC4,
    AHTempCmdQueryStatusResp=0xC5,
    AHTempCmdConfigModeResp=0xC6,
    AHTempCmdErrorDataResp=0xCE,
    AHTempCmdNewSyncTimeResp=0xC8,
    AHTempCmdNewSyncDataResp=0xC9,
    AHTempCmdNewStartMeasuringResp=0xCA,

};

/**
 * 血压计命令字
 */
typedef NS_ENUM(NSUInteger,AHBpmCmd) {
    AHBpmCmdUnknown=0x00,
    AHBpmCmdLogin=0xB0,
    AHBpmCmdSyncTime=0xB1,
    AHBpmCmdStartMeasuring=0xC0,
    AHBpmCmdStopMeasuring=0xC1,
    AHBpmCmdStopVoiceBroadcast=0xC2,
    AHBpmCmdRealTimeData=0xC3,
    AHBpmCmdMeasurementResults=0xCC,
    AHBpmCmdPowerOff=0xD0,
    AHBpmCmdBluetoothStatus=0xD1,
    AHBpmCmdDataProcess=0xD7,
    AHBpmCmdDeviceConfig=0xD9,
};


/**
 * 血压计设备设置功能命令
 */
typedef NS_ENUM(NSUInteger,AHBpmConfig) {
    AHBpmConfigUnknown=0x00,
    AHBpmConfigSwitchUser=0x01,
    AHBpmConfigTimeSync=0x02,
    AHBpmConfigVoiceControl=0x03,
    AHBpmConfigStatusSync=0x04,
    AHBpmConfigStartMeasuring=0x05,
    AHBpmConfigStopMeasuring=0x06,
    AHBpmConfigCancelVoicePrompt=0x07,
    AHBpmConfigOnlineCheck=0x08,
    AHBpmConfigResponse=0x09,
    AHBpmConfigGetSn=0x0A,
    AHBpmConfigSystemTime=0x0B,
    AHBpmConfigPowerOff=0xD0,
};


/**
 * 血压计响应状态码
 */
typedef NS_ENUM(NSUInteger,AHBpmResp) {
    AHBpmRespSuccess=0x0000,        //成功
    AHBpmRespUndefined=0x00EE,      //命令未定义，无法响应
    AHBpmRespInvalid=0x00FF,        //指令无效
    AHBpmRespTaskBusy=0xFFFF,       //从机忙，无空处理命令
};

/**
 * 血糖仪命令字
 */
typedef NS_ENUM(NSUInteger,AHCGMCmd) {
    AHCGMCmdUnknown=0x00,
    AHCGMCmdSyncLatestData=0xD1,            //查询最后一次的测量数据
    AHCGMCmdSyncTime=0xD2,                  //同步时间
    AHCGMCmdSyncData=0xD3,                  //同步历史数据
    AHCGMCmdClearData=0xD4,                 //清空历史数据
    AHCGMCmdQueryStatus=0xD5,               //获取系统信息
    AHCGMCmdConfigMode=0xD6,                //设置测量间隔
    AHCGMCmdDisconnect=0xD7,                //断开连接

    
    AHCGMCmdLatestDataResp=0xC1,            //最新一笔测量响应
    AHCGMCmdSyncTimeResp=0xC2,              //同步时间响应
    AHCGMCmdSyncDataResp=0xC3,              //历史数据响应
    AHCGMCmdClearDataResp=0xC4,             //清空历史数据响应
    AHCGMCmdQueryStatusResp=0xC5,           //系统信息响应
    AHCGMCmdConfigModeResp=0xC6,            //测量间隔响应
    AHCGMCmdDisconnectResp=0xC7,            //连接断开响应
};


/**
 * 标准协议，时间格式
 */
@interface BTCurrentTime : NSObject

@property (nonatomic,assign)int year;
@property (nonatomic,assign)int month;
@property (nonatomic,assign)int day;
@property (nonatomic,assign)int hours;
@property (nonatomic,assign)int minutes;
@property (nonatomic,assign)int seconds;
@property (nonatomic,assign)long utc;
@property (nonatomic,strong)NSString * _Nullable time;
@property (nonatomic,strong)NSData * _Nullable srcData;

-(instancetype _Nonnull )initWithData:(NSData *_Nullable)data;

/**
 * 获取当前时间
 */
+(NSData *_Nonnull)getCurrentTime;
@end


/**
 * 设备数据基类
 */
@interface BTDeviceData : NSObject

@property(nonatomic,assign)NSUInteger cmd;                      //数据包命令字
@property(nonatomic,assign)NSUInteger utc;                      //测量时间，UTC
@property(nullable,nonatomic,strong)NSString *broadcastId;      //广播ID
@property(nullable,nonatomic,strong)NSString *deviceId;         //设备ID
@property(nullable,nonatomic,strong)NSString *deviceSN;         //设备SN
@property(nullable,nonatomic,strong)NSString *measureTime;      //测量时间，格式 yyyy-MM-dd HH:mm:ss
@property(nonatomic,strong)NSData * _Nullable srcData;          //原始数据包
@property(nonatomic,assign)NSUInteger deviceType;               //设备类型

-(instancetype _Nonnull)initWithData:(NSData *_Nullable)data;


-(instancetype _Nonnull)initWithData:(NSData *_Nullable)data ofCmd:(NSUInteger)cmd;

/**
 * 数据包解码，由子类重写
 */
-(void)decoding;

/**
 * 对象信息
 */
-(NSDictionary *_Nonnull)toString;
@end

#pragma mark - AHPulseOximeterData
/**
 * 血氧仪体积描点数据
 */
@interface AHPlethysmogram : BTDeviceData

/**
 * 描点数据
 */
@property(nonatomic,strong)  NSArray<NSNumber *>*items;

/**
 *  电量
 */
@property(nonatomic,assign)  int battery;
@end


/**
 * 血氧仪数据
 */
@interface AHSpO2 : BTDeviceData

/**
 * 血氧(SpO2，单位%),35-100，127 为无效值。无效值可显示成`---';
 */
@property(nonatomic,assign) int value;

/**
 * 脉率(pulse rate，单位 bpm),25-250，255 为无效值;
 */
@property(nonatomic,assign) int pulseRate;

/**
 * PI 指数 0-200,0 为无效值。
 */
@property(nonatomic,assign) float pi;
@end


/**
 * 血氧仪警报信息
 */
@interface AHSpO2Alarm : BTDeviceData

/**
 * 血氧报警限上限
 */
@property(nonatomic,assign) int maxSpo2;

/**
 * 血氧报警限下限
 */
@property(nonatomic,assign) int minSpo2;

/**
 * 脉率报警限上限
 */
@property(nonatomic,assign) int maxPulseRate;

/**
 * 脉率报警限下限
 */
@property(nonatomic,assign) int minPulseRate;
@end


#pragma mark - AHTemperatureData

/**
 * 温度计、电子体温计测量数据
 */
@interface AHTempData : BTDeviceData

/**
  *  <p>温度</p>
  *  <p>Temperature</p>
  */
@property(nonatomic,assign) float temp;

 /**
  *  <p>测温模式</p>
  *  <p>Temperature measurement mode</>
  *
  *  <p>0x01: Adult forehead temperature mode</>
  *  <p>0x02: Children's forehead temperature mode</>
  *  <p>0x03: Ear temperature mode</>
  *  <p>0x04: Material temperature mode</>
  */
@property(nonatomic,assign) AHTempMode mode;

 /**
  *  <p>测量次数</p>
  *  <p>Number of measurements</p>
  */
@property(nonatomic,assign) int num;

 /**
  * <p>历史数据标签</p>
  * <p>History Data Marker</p>
  */
@property(nonatomic,assign) BOOL historyMarker;

/**
 * <p>指令查询结果响应</p>
 * <p>Command query result response</p>
 */
@property(nonatomic,assign) BOOL endResp;

/**
 * 体温原始数据，用于转换华氏温度
 */
@property(nonatomic,assign) int srcValue;
@end

/**
 * 温度计、电子体温计测量错误数据
 */
@interface AHTempErrorData : BTDeviceData

/**
 * 0xe1：环境温度 > 40℃或 < 0℃（Er1）
 * 0xe2：物温模式 < 0℃（Lo）
 * 0xe3：物温模式 > 100℃（Hi）
 * 0xe4：人体测温模式 < 32℃（Lo）
 * 0xe5：人体测温模式 > 42.9℃（Hi）
 */
@property(nonatomic,assign)  int code;

/**
 * 测量次数
 */
@property(nonatomic,assign)  int num;
@end

/**
 * 温度计、电子体温计测量模式
 */
@interface AHTempModeData : BTDeviceData

/**
 * 当前测量模式
 */
@property(nonatomic,assign)  AHTempMode mode;

/**
 * 当前测量单位
 */
@property(nonatomic,assign)  int unit;

@end

/**
 * 温度计、电子体温计状态数据
 */
@interface AHTempStatus : BTDeviceData

/**
 * 当前测量模式
 * <p>Current measurement mode</p>
 */
@property(nonatomic,assign)  AHTempMode mode;

/**
 * <p>电量</p>
 * <p>Device Battery Information</p>
 *
 * <p>0xA0, battery = 100%</p>
 * <p>0x80, battery >=80% </p>
 * <p>0x50, battery >=50% </p>
 * <p>0x10, battery <=10% </p>
 */
@property(nonatomic,assign)  int battery;

/**
 * 主机版本号
 * <p>Device Version</p>
 */
@property(nonatomic,strong)  NSString *version;
@end


/**
 * 温度计、电子体温计离线测量数据概述，历史数据
 */
@interface AHTempDataSummary : BTDeviceData

/**
  * 总数
  */
@property(nonatomic,assign) int count;

@end

#pragma mark - AHBloodPressureData

/**
 * 血压测量数据
 */
@interface AHBpmData : BTDeviceData

/**
 * 收缩压
 */
@property(nonatomic,assign)int systolic;

/**
 * 舒张压
 */
@property(nonatomic,assign)int diastolic;

/**
 * 脉率值，次/每分钟
 */
@property(nonatomic,assign)int pulse;


/**
 * 不规则脉搏标志位
 */
@property(nonatomic,assign) BOOL irregularPulse;

/**
 * 用户编号
 */
@property(nonatomic,assign) int userNumber;
@end


/**
 * 血压计配置状态数据
 */
@interface AHBpmConfigData : BTDeviceData

/**
 * 响应码
 * <p>Response code</p>
 */
@property(nonatomic,assign) AHBpmResp resp;

/**
 * 配置类型
 * <p>Device config type</p>
 */
@property(nonatomic,assign) AHBpmConfig config;

/**
 * 当前用户
 * <p>Current User</p>
 */
@property(nonatomic,assign) int currentUser;

/**
 * 时间状态
 * <p>0x01 血压计历史时间为错误时间</>
 * <p>0x00 血压计历史时间为正确时间</>
 */
@property(nonatomic,assign) int timeState;

/**
 * 语音控制开关
 * <p>Voice control state</>
 */
@property(nonatomic,assign) BOOL voiceState;
@end

/**
 * 血压测量错误状态数据
 */
@interface AHBpmErrorData : BTDeviceData

/**
 * 错误码
 * ERR1:传感器震荡异常
 * ERR2:检测不到足够的心跳或算不出血压
 * ERR3:测量结果异常
 * ERR4:袖带过松或漏气(10秒内加压不到30mmHg)
 * ERR5:气管被堵住
 * ERR6:测量时压力波动大 ERR7:压力超过上限
 */
@property(nonatomic,assign) int code;
@end

/**
 * 血压计充气过程数据
 */
@interface AHBpmProcessData : BTDeviceData

/**
 * 过程中的计时压力, 单位mmHg
 * <p>In-process inflation pressure data, mmHg</p>
 */
@property(nonatomic,assign) int pressure;

/**
 * 脉率状态
 * <p>1,Pulse rate detected</p>，
 * <p>0,Pulse rate not detected</p>
 */
@property(nonatomic,assign) int pulseState;
@end


/**
 * 血压计设备状态数据
 */
@interface AHBpmStatus : BTDeviceData

/**
  * 用户2未同步的历史数据
  * <p>User 2 unsynchronized historical data</p>
  */
@property(nonatomic,assign) int historyData2;

 /**
  * 用户1未同步的历史数据
  * <p>User 1 unsynchronized historical data</p>
  */
@property(nonatomic,assign) int historyData1;

 /**
  * 软件版本
  */
@property(nonatomic,strong) NSString *softwareVersion;

 /**
  * 硬件版本
  */
@property(nonatomic,strong) NSString *hardwareVersion;

 /**
  * 当前用户
  */
@property(nonatomic,assign)  int currentUser;

 /**
  * 语音开关
  */
@property(nonatomic,assign) BOOL voiceControl;

 /**
  * 当前电量 格数
  */
@property(nonatomic,assign) int battery;
@end


@interface AHBpmSyncResp : BTDeviceData

/**
 * 用户编号
 */
@property(nonatomic,assign)  int userNumber;

/**
 * 历史数据记录
 */
@property(nonatomic,assign)  int countOfData;
@end


@interface AHBpmDeviceSn : BTDeviceData

@property(nonatomic,strong) NSString *deviceSn;
@end


#pragma mark - AHBloodSugarData

/**
 * 血糖测量数据
 */
@interface AHBloodSugarData : BTDeviceData

/**
 * 电流值，原始数据，根据计算公式转换血糖浓度
 */
@property(nonatomic,assign)  int srcValue;

/**
 * 温度
 */
@property(nonatomic,assign)  double temperature;


/**
 * 血糖值，单位 mmol/L
 */
@property(nonatomic,assign)  double value;

/**
 * 历史数据标签
 */
@property(nonatomic,assign) BOOL historyMarker;

/**
 *  数据索引
 */
@property(nonatomic,assign) NSUInteger index;


/**
 * 历史数据是否已同步完成
 */
-(BOOL)isHistorySyncEnd;
@end


#pragma mark - AHCGMStatus

/**
 * 血糖仪设备状态信息
 */
@interface AHCGMStatus : BTDeviceData

/**
 * 电量等级
 */
@property(nonatomic,assign) NSUInteger battery;

/**
 * 磁开关状态
 */
@property(nonatomic,assign) NSUInteger interval;

/**
 * 磁开关状态
 */
@property(nonatomic,assign) NSUInteger magneticState;

/**
 * 主机版本号
 */
@property(nonatomic,strong) NSString * _Nonnull version;

@end


/**
 * 血糖仪历史测量数据概述
 */
@interface AHCGMDataSummary : BTDeviceData

/**
  * 总数
  */
@property(nonatomic,assign) int count;

@end
