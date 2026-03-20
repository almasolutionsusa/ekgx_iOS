//
//  NSAVHCVConnect.h
//
//  Created by moon_zm on 2024/1/24.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef NS_ENUM(NSInteger, NSAVHCVConnecting_Status) {
    NSAVHCVConnecting_Status_Connecting = 0,
    NSAVHCVConnecting_Status_DiscoverCharacteristics = 1,
    NSAVHCVConnecting_Status_DiscoverDescriptorsForCharacteristic = 2,
    NSAVHCVConnecting_Status_BuildCredits = 3,
    NSAVHCVConnecting_Status_InitDevice = 4,
    NSAVHCVConnecting_Status_InitDeviceAgain = 5
};

typedef void (^NSAVHCV_Connected_Handler)(void);
typedef void (^NSAVHCV_DisConnect_Handler)(NSError * _Nullable error);
typedef void (^NSAVHCV_Connecting_Status_Handler)(NSAVHCVConnecting_Status status);


NS_ASSUME_NONNULL_BEGIN
@protocol vhECGiCV200BleDelegate;
@class NSAVHCVDevice;
@interface NSAVHCVConnect : NSObject
@property (nonatomic) dispatch_queue_t currentQueue;
@property (nonatomic) CBCentralManager *manager;
@property (nonatomic) id <vhECGiCV200BleDelegate> delegate;
@property (nonatomic) NSAVHCVDevice *targetDevice;
@property (nonatomic,readonly) NSAVHCVDevice *current_device;
@property (nonatomic, readonly) BOOL collecting;
@property (nonatomic) NSTimeInterval skipBufferTimeInterval;    //default is 1.5;

+(NSAVHCVConnect *)shareACHCVConnect;

// Connect device, and init it.
-(BOOL)connect:(NSAVHCVDevice *)avhcv_device
   withHandler:(NSAVHCV_Connected_Handler)completed
withProgressHandler:(NSAVHCV_Connecting_Status_Handler)progressHandler
withDisConnectHandler:(NSAVHCV_DisConnect_Handler)disConnectHandler;

//error is nil when disconnect from user.
-(void)disConnectWith:(NSAVHCV_DisConnect_Handler)completed;

// let device re start collect ECGs.
-(void)collect_restart;

// let device start collect ECGs.
-(void)collect_start;

// stop collect ECGs, and iCV200BLE will be power off after 15 minutes.
-(void)collect_stop;

@end

@protocol vhECGiCV200BleDelegate <NSObject>
@required
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
- (void)dataReceivedWithData:(NSArray <NSArray <NSNumber *>*>* _Null_unspecified)ECGs;

@optional
// This function will be called when there is any error occurred like data loss detected and alike
- (void)dataErrorDetectedWithError:(NSError * _Null_unspecified)error;

// This function is called to notify 12 lead connectivity status
- (void)leadsConnectivityStatusUpdatedWithI:(BOOL)linked_I II:(BOOL)linked_II III:(BOOL)linked_III
                                        aVR:(BOOL)linked_aVR aVL:(BOOL)linked_aVL aVF:(BOOL)linked_aVF
                                         V1:(BOOL)linked_V1 V2:(BOOL)linked_V2 V3:(BOOL)linked_V3
                                         V4:(BOOL)linked_V4 V5:(BOOL)linked_V5 V6:(BOOL)linked_V6;

//iCV200BLE device battery value
- (void)deviceBattery:(int)value;
@end

NS_ASSUME_NONNULL_END
