//
//  NSNewDataDecoder.h
//  iCV200BLE2
//
//  Created by moon_zm on 2025/3/11.
//

#import <Foundation/Foundation.h>
/** @class
 * 蓝牙心电数据解析逻辑-新蓝牙 v4
 */
NS_ASSUME_NONNULL_BEGIN
@protocol NSDataDecoder_V4Delegate;
@interface NSDataDecoder_V4 : NSObject

@property (nonatomic, weak) id <NSDataDecoder_V4Delegate>delegate;
- (void)reset;
// 解码v4设备数据
- (void)receivedData:(NSData *)data;
//
- (void)cleanCacheData;
@end

@protocol NSDataDecoder_V4Delegate <NSObject>
@required
//iCV200BLE rate that howmany ECG points per second every lead.
- (void)device_v4_rate:(int32_t)rate;
- (void)device_v4_infoWithId:(NSString *)deviceId version:(int)version;
- (void)device_v4_infoSampleDoubled:(BOOL)sampleDoubled adBits:(float)adBits adRange:(float)adRange amp:(float)amp uVpb:(double)uVpb;
- (void)device_v4_isReady;

//iCV200BLE device v4 battery value
- (void)device_v4_battery:(int)value;

/*
 The ECGs is NSArray <NSArray <NSNumber *>*>* type, and,
 [ECGs objectAtIndex:0] is ECG's "I"
 [ECGs objectAtIndex:1] is ECG's "II"
 [ECGs objectAtIndex:2] is ECG's "III"
 [ECGs objectAtIndex:3] is ECG's "aVR"
 [ECGs objectAtIndex:4] is ECG's "aVL"
 [ECGs objectAtIndex:5] is ECG's "aVF"
 [ECGs objectAtIndex:6] is ECG's "V1"
 [ECGs objectAtIndex:7] is ECG's "V2"
 [ECGs objectAtIndex:8] is ECG's "V3"
 [ECGs objectAtIndex:9] is ECG's "V4"
 [ECGs objectAtIndex:10] is ECG's "V5"
 [ECGs objectAtIndex:11] is ECG's "V6"
 This function will be called when receive ECG signal.
*/
- (void)device_v4_dataReceivedWithData:(NSArray <NSArray <NSNumber *>*>* _Null_unspecified)ECGs;

@optional
// This function will be called when there is any error occurred like data loss detected and alike
- (void)device_v4_dataErrorDetectedWithError:(NSError * _Null_unspecified)error;

- (void)device_v4_leadsConnectivityStatusUptated:(short)cr cl:(short)cl c1:(short)c1 c2:(short)c2 c3:(short)c3 c4:(short)c4 c5:(short)c5 c6:(short)c6 cf:(short)cf cn:(short)cn;

@end
NS_ASSUME_NONNULL_END
