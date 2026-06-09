//
//  BTPairCommand.h
//  BTBluetoothPlugin-Demo
//
//  Created by sky on 2019/11/14.
//  Copyright © 2019 sky. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger,BTPairCmd)
{
    BTPairCmdUnknown=0x00,              //未知状态
    BTPairCmdPairState=0x01,            //设备绑定状态
    BTPairCmdPairConfirm=0x03,          //绑定确认
};

@interface BTDevicePairMsg : NSObject

/**
 * 绑定指令
 */
@property(nonatomic,assign)BTPairCmd cmd;

/**
 * 绑定状态
 */
@property(nonatomic,assign)BOOL state;

/**
 * 绑定的消息内容
 */
@property(nullable,nonatomic,strong)id data;

/**
 * 绑定方式
 * 0x03 = 随机码绑定
 * 0x04 = 二维码绑定
 * 0x05 = 手动绑定
 */
@property(nonatomic,assign)NSUInteger pairMode;
@end

