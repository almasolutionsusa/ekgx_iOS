//
//  CRAP20SDK.h
//  CRAP20Demo
//
//  Created by Creative on 2017/7/18.
//  Copyright © 2017年 creative. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CRBleDevice.h"



/** Blood oxygen alarm query type */
typedef NS_ENUM(Byte, CRAP_20Spo2AlertConfigType)
{
    /** Alarm function off/on status */
    CRAP_20Spo2AlertConfigTypeAlertState = 1,
    /** Hypoxic threshold for alarm function */
    CRAP_20Spo2AlertConfigTypeSpo2LowThreshold,
    /** Alarm function pulse rate threshold is too low */
    CRAP_20Spo2AlertConfigTypePrLowThreshold,
    /** The pulse rate of the alarm function is too high */
    CRAP_20Spo2AlertConfigTypePrHighThreshold,
    /** Pulsating sound off/on state */
    CRAP_20Spo2AlertConfigTypePulseBeepState,
    
};
/** Blood oxygenation */
typedef NS_OPTIONS(Byte, CRAP_20Spo2State)
{
    /** normal */
    CRAP_20Spo2StateNormal = 0,
    /**  (Reserved) */
    CRAP_20Spo2StateProbeDisconnected = 1,
    /** Probe off */
    CRAP_20Spo2StateProbeOff = CRAP_20Spo2StateProbeDisconnected << 1,
    /** (Reserved) */
    CRAP_20Spo2StatePulseSearching = CRAP_20Spo2StateProbeDisconnected << 2,
    /** Probe failure or improper use */
    CRAP_20Spo2StateCheckProbe = CRAP_20Spo2StateProbeDisconnected << 3,
    /** (Reserved) */
    CRAP_20Spo2StateMotionDetected = CRAP_20Spo2StateProbeDisconnected << 4,
    /** (Reserved) */
    CRAP_20Spo2StateLowPerfusion = CRAP_20Spo2StateProbeDisconnected << 5
};

/** Blood Oxygen Mode */
typedef NS_ENUM(Byte, CRAP_20Spo2Mode)
{
    /** Adult mode */
    CRAP_20Spo2ModeAdultMode = 0,
    /** Newborn pattern */
    CRAP_20Spo2ModeNewbornMode = 1,
    /** Animal mode (reserved) */
    CRAP_20Spo2ModeAnimalMode = 2
};

/** Nasal flow waveform data */
struct nasalFlowWaveData
{
    int nasalFlowValue;
    int snoreValue;
};
/** Triaxial acceleration waveform data */
struct three_AxesWaveData
{
    int acc_X;
    int acc_Y;
    int acc_Z;
};

/** Body temperature measurement results */
typedef NS_ENUM(Byte, CRAP_20TemparatureResult)
{
    /** normal */
    CRAP_20TemparatureResultNormal = 0,
    /** low */
    CRAP_20TemparatureResultLow = 1,
    /** high */
    CRAP_20TemparatureResultHigh = 2
};

/** Body temperature unit */
typedef NS_ENUM(Byte, CRAP_20TemparatureUnit)
{
    /** Celsius */
    CRAP_20TemparatureUnitCelsius = 0,
    /** Fahrenheit */
    CRAP_20TemparatureUnitFahrenheit = 1,
};

/** PC-60F Working mode */
typedef NS_ENUM(Byte, CRPC_60FWorkStatusMode)
{
    /** Spot check */
    CRPC_60FWorkStatusModeCommon = 1,
    /** Continuous */
    CRPC_60FWorkStatusModeContinious,
    /** Menu */
    CRPC_60FWorkStatusModeMenu,
};

/** PC-60F Spot testing */
typedef NS_ENUM(Byte, CRPC_60FCommanMessureStage)
{
    /** no */
    CRPC_60FCommanMessureStageNone = 0,
    /** Preparation Phase */
    CRPC_60FCommanMessureStagePrepare,
    /** Measuring */
    CRPC_60FCommanMessureStageMessuring,
    /** Broadcasting results*/
    CRPC_60FCommanMessureStageBroadcasting,
    /** Pulse rate analysis results */
    CRPC_60FCommanMessureStageAnalyzing,
    /** Measurement completed */
    CRPC_60FCommanMessureStageComplete,
};


@class CRAP20SDK;

@interface CRAP20RecordModel : NSObject

/** timer */
@property (nonatomic, strong) NSString *time;
/** Serial number */
@property (nonatomic, assign) int recordNum;
/** length  */
@property (nonatomic, assign) int length;
/** Blood Oxygen Array */
@property (nonatomic, strong) NSMutableArray <NSNumber *>*spo2Array;
/** Pulse rate array */
@property (nonatomic, strong) NSMutableArray <NSNumber *>*prArray;

@end

@protocol CRAP20SDKDelegate <NSObject>
#pragma mark -  General callback
/** Blood oxygen waveform data */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSpo2Wave:(struct waveData*)wave FromDevice:(CRBleDevice *)device;
/** Blood oxygen parameters */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSpo2Value:(int)spo2 PulseRate:(int)pr PI:(int)pi State:(CRAP_20Spo2State)state Mode:(CRAP_20Spo2Mode)mode BattaryLevel:(int)battaryLevel FromDevice:(CRBleDevice *)device;
/** Device information (software version number, hardware version number, product name) */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetDeviceInfoForSoftWareVersion:(NSString *)softWareV HardWaveVersion:(NSString *)hardWareV ProductName:(NSString *)productName FromDevice:(CRBleDevice *)device;
#pragma mark -  AP-20,SP-20 General callback (Note: Some customized versions of PC-68B also have the following functions)
/** Get device serial number */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSerialNumber:(NSString *)serialNumber FromDevice:(CRBleDevice *)device;
/** Get device time */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetDeviceTime:(NSString *)deviceTime FromDevice:(CRBleDevice *)device;
/** Get device backlight level */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetDeviceBackLightLevel:(int)lightLevel FromDevice:(CRBleDevice *)device;
/** Get battery level */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetBartteryLevel:(int)batteryLevel FromDevice:(CRBleDevice *)device;
/** Obtain blood oxygen alarm parameter information (Note: Some customized versions of PC-68B also have this function) */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetSpo2AlertInfoWithType:(CRAP_20Spo2AlertConfigType)type Value:(int)value FromDevice:(CRBleDevice *)device;
/** Get user ID */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetUserID:(NSString *)userID FromDevice:(CRBleDevice *)device;
/** Whether the backlight level is set successfully */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK DeviceBackLightLevelSettedSuccess:(BOOL)success FromDevice:(CRBleDevice *)device;
/** Whether the device time is set successfully */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK DeviceTimeSettedSuccess:(BOOL)success FromDevice:(CRBleDevice *)device;
/** Whether setting the blood oxygen alarm parameters is successful (Note: some customized versions of PC-68B also have this function) */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK Spo2AlertParamInfoType:(CRAP_20Spo2AlertConfigType)type SettedSuccess:(BOOL)success FromDevice:(CRBleDevice *)device;
/** Successfully set blood oxygen parameter enable */
- (void)successdToSetSpo2ParamEnableFromDevice:(CRBleDevice *)device;
/** Successfully set the blood oxygen waveform enable */
- (void)successdToSetSpo2WaveEnableFromDevice:(CRBleDevice *)device;
#pragma mark - AP-20 use callback
/** The data frequency is 50Hz, one data at a time */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetNasalFlowWave:(struct nasalFlowWaveData)nasalFlowWave FromDevice:(CRBleDevice *)device;
/** Get respiratory rate */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetNasalFlowRespirationRate:(int)rate FromDevice:(CRBleDevice *)device;
/** Successfully set the nasal flow parameter enable */
- (void)successdToSetNasalFlowParamEnableFromDevice:(CRBleDevice *)device;
/** Successfully set nasal flow waveform enable */
- (void)successdToSetNasalFlowWaveEnableFromDevice:(CRBleDevice *)device;

/** Get three-axis acceleration waveform data */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetThree_AxesWaveData:(struct three_AxesWaveData)waveData FromDevice:(CRBleDevice *)device;
/** Successfully set the three-axis acceleration waveform enable */
- (void)successdToSetThree_AxesWaveEnableFromDevice:(CRBleDevice *)device;

#pragma mark -  SP-20 Use callback
/** Get temperature value */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetTemparatureResult:(CRAP_20TemparatureResult)result Value:(float)tempValue Unit:(CRAP_20TemparatureUnit)unitCode FromDevice:(CRBleDevice *)device;

#pragma mark -  PC-60F Use callback
/** Get MAC address */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetMACAddress:(NSString *)macAddress FromDevice:(CRBleDevice *)device;

- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetWorkStatusDataWithMode:(CRPC_60FWorkStatusMode)mode Stage:(CRPC_60FCommanMessureStage)stage Parameter:(int)para OtherParameter:(int)otherPara FromDevice:(CRBleDevice *)device;

#pragma mark -  PC-60E callback （New menu settings and queries, 07/09/2020）
/**
 * Menu set up successfully
 * @param failOrSuccess  00: fail，01: success。 Setting results: the bitwise AND, 1 is success. (0~4bit：low blood oxygen, high pulse rate, low pulse rate, measurement type, beep switch, rotary switch)
 */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK setMenuSuccess:(BOOL)failOrSuccess FromDevice:(CRBleDevice *)device;

/**
 * Menu query results
 * @param success  Setting results: the bitwise AND, 1 is success. (0~5bit：low blood oxygen, high pulse rate, low pulse rate, measurement type, beep switch, rotary switch)
 */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK
  getMenuLowSpO2:(int)lowSpO2
          highPR:(int)highPr
           lowPR:(int)lowPr
            spot:(int)spot
          beepOn:(int)beepOn
        rotateOn:(int)rotateOn
      FromDevice:(CRBleDevice *)device;


#pragma mark -  PC-68B callback
/** Get list of records */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetRecordsInfoArray:(NSArray *)infoArray FromDevice:(CRBleDevice *)device;
/** Get specified record data */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK GetRecordsData:(CRAP20RecordModel *)model FromDevice:(CRBleDevice *)device;
/** Whether the deletion was successful */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK DidDeleteRecordsSuccess:(BOOL)success FromDevice:(CRBleDevice *)device;
/** Get the latest alarm parameters */
- (void)ap_20SDK:(CRAP20SDK *)ap_20SDK getSpo2AlertState:(BOOL)alertOn Spo2LowValue:(int)spo2Low PrLowValue:(int)prLow PrHighValue:(int)prHigh PulseBeep:(BOOL)beepOn SensorAlert:(BOOL)sensorOn ForDevice:(CRBleDevice *)device;

@end

@interface CRAP20SDK : NSObject

/** delegate  */
@property (nonatomic, weak) id <CRAP20SDKDelegate>delegate;

+ (instancetype)shareInstance;
/** Used to handle connected tasks */
- (void)didConnectDevice:(CRBleDevice *)device;
/** Used to handle disconnected follow-up tasks */
- (void)willDisconnectWithDevice:(CRBleDevice *)device;
/** Get new data */
- (void)appendingNewData:(NSData *)data FromDevice:(CRBleDevice *)device;

#pragma mark - Query Command
/** Query device 4 digit version information */
- (void)queryForDeviceFourBitVersionForDevice:(CRBleDevice *)device;
/** Query device 2 digit version information */
- (void)queryForDeviceTwoBitVersionForDevice:(CRBleDevice *)device;
/** Query device serial number */
- (void)queryForSerialNumberForDevice:(CRBleDevice *)device;
/** Query device time */
- (void)queryForDeviceTimeForDevice:(CRBleDevice *)device;
/** Query device battery level */
- (void)queryForBatteryLevelForDevice:(CRBleDevice *)device;
/** Query device backlight level */
- (void)queryForBackgroundLightLevelForDevice:(CRBleDevice *)device;
/** Query blood oxygen alarm parameter information */
- (void)queryForSpo2AlertParamInfomation:(CRAP_20Spo2AlertConfigType)configType ForDevice:(CRBleDevice *)device;
/** Query user ID */
- (void)queryForUserIDForDevice:(CRBleDevice *)device;


#pragma mark - Enable Command
/** Send blood oxygen waveform enable command */
- (void)sendCommandForSpo2WaveEnable:(BOOL)beEnable ForDevice:(CRBleDevice *)device;
/** Send blood oxygen parameter enable command */
- (void)sendCommandForSpo2ParamEnable:(BOOL)beEnable ForDevice:(CRBleDevice *)device;
/** Send nasal flow waveform enable command */
- (void)sendCommandForNasalFlowWaveEnable:(BOOL)beEnable ForDevice:(CRBleDevice *)device;
/** Send nasal flow parameter enable command */
- (void)sendCommandForNasalFlowParamEnable:(BOOL)beEnable ForDevice:(CRBleDevice *)device;
/** Send three-axis acceleration waveform enable command */
- (void)sendCommandForThree_AxesWaveEnable:(BOOL)beEnable ForDevice:(CRBleDevice *)device;

#pragma mark - Setting Command

#pragma mark - AP-20 Dedicated method
/** Set backlight level (0~5, 0 is the darkest, 5 is the brightest)*/
- (void)setBackgroundLightLevel:(int)lightLevel  ForDevice:(CRBleDevice *)device;
/** Set user ID */
- (void)setUserID:(NSString *)userID ForDevice:(CRBleDevice *)device;

#pragma mark - AP-20 ，SP-20 General method

/** Set device time */
- (void)setDeviceTime:(NSString *)deviceTime ForDevice:(CRBleDevice *)device;
/** Set blood oxygen alarm parameter information */
- (void)setSpo2AlertParamInfomation:(CRAP_20Spo2AlertConfigType)configType Value:(int)value ForDevice:(CRBleDevice *)device;

#pragma mark - PC_60F Dedicated method
/** Query Bluetooth address */
- (void)queryForMACAddressForDevice:(CRBleDevice *)device;

#pragma mark - PC_60E Dedicated method  Sep 2020
/** Query menu */
- (void)queryForMenuOptionsForDevice:(CRBleDevice *)device;
/**
 @description setting menu

 @param lowSpO2   Hypoxia threshold （60~100）  0: means no setting
 @param highPr   High pulse rate threshold       (0~255)     0: means no setting
 @param lowPr   Low pulse rate threshold          (0~255)    0: means no setting
 @param spot   Spot check or Continuous. 1: Spot check 2: Continuous 0: means no setting
 @param beepOn   Beep switch. 1: On, 2: Off         0: means no setting
 @param rotateOn   Rotary switch. 1: On, 2: Off         0: means no setting
 */
- (void)setMenuOptions:(int)lowSpO2
                highPR:(int)highPr
                 lowPR:(int)lowPr
                  spot:(int)spot
                beepOn:(int)beepOn
              rotateOn:(int)rotateOn
             forDevice:(CRBleDevice *)device;

#pragma mark - PC_68B Dedicated method
/** Get list of records */
- (void)queryForRecordsListForDevice:(CRBleDevice *)device;
/** Get records according to the specified serial number */
- (void)getRecordsDataWithModel:(CRAP20RecordModel *)model ForDevice:(CRBleDevice *)device;
/** Delete Record */
- (void)deleteAllRecordsForDevice:(CRBleDevice *)device;

/** Query blood oxygen alarm parameters */
- (void)queryForSpo2AlertParamInfomationForDevice:(CRBleDevice *)device;
/*!
 *  @method
 *  @descrip Set blood oxygen alarm parameter information
 *  @param alertOn   Alarm function on/off YES is on
 *  @param spo2Low    Hypoxemia threshold (85 ~ 100)
 *  @param prLow    Low pulse rate threshold (25 ~ 99)
 *  @param prHigh    High pulse rate threshold (100 ~ 250)
 *  @param beepOn    Pulsating sound on/off YES is on
 *  @param sensorOn    Turn off warning on/off YES is on
 *
 */
- (void)setSpo2AlertState:(BOOL)alertOn Spo2LowValue:(int)spo2Low PrLowValue:(int)prLow PrHighValue:(int)prHigh PulseBeep:(BOOL)beepOn SensorAlert:(BOOL)sensorOn ForDevice:(CRBleDevice *)device;

@end


