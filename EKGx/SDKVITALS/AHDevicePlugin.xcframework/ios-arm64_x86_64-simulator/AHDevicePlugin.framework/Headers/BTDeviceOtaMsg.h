//
//  BTDeviceOtaMsg.h
//  BluetoothPlugin-Demo
//
//  Created by sky on 2020/5/19.
//  Copyright © 2020 sky. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AHDevicePluginProfiles.h"

@interface BTDeviceOtaMsg : NSObject

//@property(nonatomic,assign)BTUpgradeState status;           //升级状态
@property(nonatomic,assign)BTErrorCode errorCode;           //错误码
@property(nullable,nonatomic,strong)NSData *srcData;                 //原数据包
@property(nonatomic,assign)NSUInteger upgradeProgress;      //升级进度
@end

