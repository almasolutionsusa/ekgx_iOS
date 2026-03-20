//
//  NSCheckDeviceBluetooth.h
//
//  Created by moon_zm on 2024/1/24.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, Device_BluetoothStatus) {
    Device_BluetoothStatus_PoweredOff,              //system bluetooth closed
    Device_BluetoothStatus_Unsupported,             //your device is not support BLE
    Device_BluetoothStatus_Unauthorized,            //Prvice closed
    Device_BluetoothStatus_OK
};
typedef void (^check_BluetoothStatus_Handler)(Device_BluetoothStatus status);

NS_ASSUME_NONNULL_BEGIN
@interface NSCheckDeviceBluetooth : NSObject{
    check_BluetoothStatus_Handler handler;
}
@property (nonatomic) check_BluetoothStatus_Handler handler;
+(BOOL)checkDeviceBluetoothStatus:(check_BluetoothStatus_Handler)handler;
@end
NS_ASSUME_NONNULL_END
