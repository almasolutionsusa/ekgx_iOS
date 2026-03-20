//
//  NSAVHCVDevice.h
//
//  Created by moon_zm on 2024/1/24.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN
@interface NSAVHCVDevice : NSObject{
    int32_t rate;                   //iCV200BLE rate that howmany ECG points per second every lead.
    NSString * _Nullable deviceId;  //iCV200BLE device identifier
    int32_t batVol;                 // reserved for future use
    NSDate *last_found_date;
    CBPeripheral *peripheral;
    float uVpb;
    BOOL isReady;                   //internal used
    float version; //iCV200BLE device version
}
@property (nonatomic) int32_t rate;
@property (nonatomic) NSString * _Nullable deviceId;
@property (nonatomic) int32_t batVol;
@property (nonatomic) NSDate *last_found_date;
@property (nonatomic) CBPeripheral *peripheral;
@property (nonatomic) float uVpb;
@property (nonatomic) BOOL isReady;
@property (nonatomic) float version;

//save iCV200BLE name
+(BOOL)saveLastConnectDeviceName:(NSString *)name;

//got "saveLastConnectDeviceName" saved device name.
+(NSString * _Nullable )lastConnectedDevice;
@end
NS_ASSUME_NONNULL_END
