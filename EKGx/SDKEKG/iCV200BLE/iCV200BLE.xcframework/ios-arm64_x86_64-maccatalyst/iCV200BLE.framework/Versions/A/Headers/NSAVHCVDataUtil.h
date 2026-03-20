//
//  NSAVHCVDataUtil.h
//  hvECG
//
//  Created by Will on 7/31/11.
//  Created by moon_zm on 2025/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
//
/** @class
 * 低功耗蓝牙心电数据解析逻辑（压缩传输）- v3及之前蓝牙
 */
#import <Foundation/Foundation.h>

typedef void(^SamplingRateReceived)(int rate);
typedef void(^DeviceIdReceived)(NSString* deviceId);
typedef void(^DeviceIsReadyToRecord)(void);
typedef void(^DataReceived)(NSArray <NSArray <NSNumber *>*>*);
typedef void(^DataErrorDetected)(NSError* error);
typedef void(^LeadsConnectivityStatusUpdated)(short cr, short cl, short c1, short c2, short c3, short c4, short c5, short c6);
typedef void(^BatteryVolumnReceived)(int batvol);
typedef void(^DeviceAdditionalInfoReceived)(BOOL sampleDoubled, short adBits, short adRange, float amplifier, short deviceVersion, BOOL isNewDevice, double uVpb);

@interface NSAVHCVDataUtil: NSObject

@property (nonatomic) SamplingRateReceived samplingRateReceived;
@property (nonatomic) DeviceIdReceived deviceIdReceived;
@property (nonatomic) DataReceived dataReceived;
@property (nonatomic) DeviceIsReadyToRecord deviceIsReadyToRecord;
@property (nonatomic) DataErrorDetected dataErrorDetected;
@property (nonatomic) LeadsConnectivityStatusUpdated leadsConnectivityStatusUpdated;
@property (nonatomic) BatteryVolumnReceived batteryVolumnReceived;
@property (nonatomic) DeviceAdditionalInfoReceived deviceAdditionalInfoReceived;

- (void)reset;
- (void)receivedData:(NSData *)data;
- (void)cleanCacheData;

/*
- (void)wilsonConverter:(short *)data;
- (void)convertDataToBinbytesAndPushInQueue:(Byte*)bytes ToQueue:(NSMutableArray*)queue bytesCount:(long)length;
- (short**)popAndProcessDataFromQueue:(NSMutableArray*)queue numberOfSet:(int)numberOfSet;
- (short**)popAndProcessDataFromQueue_new:(NSMutableArray*)queue numberOfSet:(int)numberOfSet;
- (void)doTest;
- (void)popoutData;

- (void)setParameters:(int)sample sampleDoubled:(BOOL)sampleDoubled adBits:(int)adBits adRange:(int)adRange amp:(int)ampifier deviceVersion:(int)deviceMainVersion isNewDevice:(BOOL)NewDevice;
*/
@end
