//
//  vhiCVBleManager.h
//  vhMedicalServices
//
//  Created by moon_zm on 2025/5/16.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^vhiCVBleDisConnect_Handler)(NSError * _Nullable error);
typedef NS_ENUM(NSInteger, vhiCVBleConnectStatus) {
    vhiCVBleConnectStatus_Connecting = 0,
    vhiCVBleConnectStatus_DiscoverCharacteristics = 1,
    vhiCVBleConnectStatus_DiscoverDescriptorsForCharacteristic = 2,
    vhiCVBleConnectStatus_BuildCredits = 3,
    vhiCVBleConnectStatus_InitDevice = 4,
    vhiCVBleConnectStatus_InitDeviceAgain = 5,
    vhiCVBleConnectStatus_Connected = 6,
    vhiCVBleConnectStatus_Disconnected = 7,
    vhiCVBleConnectStatus_DisconnectedError = 8,
    vhiCVBleConnectStatus_LostDevice = 9
};

typedef NS_ENUM(NSInteger, vhiCVBleStatus) {
    vhiCVBleStatus_PoweredOff,              //system bluetooth closed
    vhiCVBleStatus_Unsupported,             //your device is not support BLE
    vhiCVBleStatus_Unauthorized,            //Prvice closed
    vhiCVBleStatus_OK
};

@protocol vhiCVBleManagerDelegate;
@interface vhiCVBleManager : NSObject
@property (nonatomic, readonly) int rate;
@property (nonatomic, readonly) NSString * _Nullable deviceId;
@property (nonatomic, readonly) int batVol;
@property (nonatomic, readonly) NSDate *last_found_date;
@property (nonatomic, readonly) CBPeripheral *peripheral;
@property (nonatomic, readonly) double uVpb;
@property (nonatomic, readonly) BOOL isReady;
@property (nonatomic, readonly) BOOL collecting;
@property (nonatomic, weak) id <vhiCVBleManagerDelegate> delegate;
//scan before check bletooth
- (void)checkBletooth:(void(^)(vhiCVBleStatus status))Hander;
//start scan bletooth ecg device
- (void)startScan;
//stop scan bletooth ecg device
- (void)stopScan;
// Connect device, and init it.
//isAuto: if is YES, when device connected, auto collect start
- (BOOL)connect:(NSString *)deviceName isAutoCollect:(BOOL)isAuto;

//error is nil when disconnect from user.
- (void)disConnectWith:(vhiCVBleDisConnect_Handler)completed;

// let device re start collect ECGs.
- (void)collectReStart;
// let device start collect ECGs.
- (void)collectStart;
// stop collect ECGs, and iCV200BLE will be power off after 15 minutes.
- (void)collectStop;
// save last connected device name at userdefault
- (void)saveLastConnectedDevice:(NSString *)deviceName;
// get last connected device name at userdefault
- (NSString *)getLastConnectedDevice;

@end

@protocol vhiCVBleManagerDelegate <NSObject>
@required
/*
 found ble ecg device name
 */
- (void)icvBleManager:(vhiCVBleManager*)manager foundDeviceName:(NSString *)name;
/*
 lost ble ecg device name
 */
- (void)icvBleManager:(vhiCVBleManager*)manager lostDeviceName:(NSString *)name;
/*
 status -> it's current ecg device connect status
 */
- (void)icvBleManager:(vhiCVBleManager*)manager connectingStatus:(vhiCVBleConnectStatus)status;

/*
 The ECGs data is NSArray <NSArray <NSNumber *>*>* type, and is not filter.
 ECG's = [["I" "II" "III" "aVR" "aVL" "aVF" "V1" "V2" "V3" "V4" "V5" "V6"]]
 This function will be called when receive ECG signal.
*/
- (void)icvBleManager:(vhiCVBleManager*)manager data:(NSArray <NSArray <NSNumber *>*>* _Null_unspecified)ECGs;
@optional
// This function will be called when there is any error occurred like data loss detected and alike
- (void)icvBleManager:(vhiCVBleManager*)manager dataError:(NSError * _Null_unspecified)error;

// This function is called to notify 12 lead connectivity status
- (void)icvBleManager:(vhiCVBleManager*)manager
      updateLeadWithI:(BOOL)linked_I
                   II:(BOOL)linked_II
                  III:(BOOL)linked_III
                  aVR:(BOOL)linked_aVR
                  aVL:(BOOL)linked_aVL
                  aVF:(BOOL)linked_aVF
                   V1:(BOOL)linked_V1
                   V2:(BOOL)linked_V2
                   V3:(BOOL)linked_V3
                   V4:(BOOL)linked_V4
                   V5:(BOOL)linked_V5
                   V6:(BOOL)linked_V6;

//iCV200BLE device battery value
- (void)icvBleManager:(vhiCVBleManager*)manager battery:(int)value;
@end

NS_ASSUME_NONNULL_END
