//
//  AHDevicePlugin+Push.h
//  AOJDevicePlugin-Library
//
//  Created by sky on 2017/4/6.
//  Copyright © 2017年 sky. All rights reserved.
//

#import "AHDevicePlugin.h"
#import "BTDevicePairMsg.h"
#import "BTDeviceSetting.h"
#import "IBCoreProfiles.h"
//#import "ATF"


@interface AHDevicePlugin (Push)

/**
 * Added in version 2.0.0
 * 推送设备设置消息指令
 */
-(void)pushSetting:(BTDeviceSetting *_Nonnull)setting
          toDevice:(BTDeviceInfo *_Nonnull)device
          response:(IBPushRespBlock _Nonnull)resp;


@end
