//
//  NSAVHCVScan.h
//
//  Created by moon_zm on 2024/1/24.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

typedef void (^Error_System_Bluetooth_Off_Handler)(void);
typedef void (^Error_System_Unsupport_Handler)(void);
typedef void (^Error_UnAuthorized_Handler)(void);

NS_ASSUME_NONNULL_BEGIN
@protocol NSAVHCVScanDelegate;
@class NSAVHCVDevice;
@interface NSAVHCVScan : NSObject{
    id <NSAVHCVScanDelegate> delegate;
    BOOL scaning;
    dispatch_queue_t currentQueue;
    CBCentralManager *manager;
    Error_System_Bluetooth_Off_Handler bluetooth_off_handler;
    Error_System_Unsupport_Handler unsupport_handler;
    Error_UnAuthorized_Handler unauthorized_handler;
    NSTimeInterval timeout;
}

@property (nonatomic) id <NSAVHCVScanDelegate> delegate;
@property (nonatomic,readonly) BOOL scaning;
@property (nonatomic,readonly) dispatch_queue_t currentQueue;
@property (nonatomic,readonly) CBCentralManager *manager;

//the iOS system bluetooth off.
@property (nonatomic) Error_System_Bluetooth_Off_Handler bluetooth_off_handler;

//some older iOS device can NOT suppert
@property (nonatomic) Error_System_Unsupport_Handler unsupport_handler;

//No permission for request bluetooth.
@property (nonatomic) Error_UnAuthorized_Handler unauthorized_handler;

//call back lostDeviceName with iCV200BLE'name after not receive update, default is 10 seconds.
@property (nonatomic) NSTimeInterval timeout;

//Start scan iCV200BLE devices.
-(void)start_scan;

//Stop scaning.
-(void)stop_scan;

//return NSAVHCVDevice object with peripheral detail.
-(nullable NSAVHCVDevice *)getAVHCVDeviceWithName:(NSString *)name;
@end

@protocol NSAVHCVScanDelegate <NSObject>
@required
// This function will be called when the iCV200BLE device is found.
-(void)foundDeviceName:(NSString *)name;

// This function will be called when the iCV200BLE device is lost.
// Battary is low or distance so far will be lost.
// Notice: The iCV200BLE will be lost after connected.
-(void)lostDeviceName:(NSString *)name;
@end

NS_ASSUME_NONNULL_END
