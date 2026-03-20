//
//  NSCenterBleVersion.h
//  iCV200BLE
//
//  Created by moon_zm on 2025/7/10.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface NSCenterBleVersion : NSObject
//搜索设备蓝牙是否 > 4.0
@property (nonatomic, assign, readonly) BOOL isValidBLE;
+ (instancetype)shard;
@end

NS_ASSUME_NONNULL_END
