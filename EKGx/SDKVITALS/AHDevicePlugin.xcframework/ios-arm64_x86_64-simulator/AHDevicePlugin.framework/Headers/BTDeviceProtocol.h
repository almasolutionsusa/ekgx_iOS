//
//  BTDeviceProtocol.h
//  GSDeviceBluetooth
//
//  Created by sky on 2018/8/29.
//  Copyright © 2018年 sky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BTDeviceProtocol : NSObject

@property(nullable,nonatomic,strong) NSString *protocol;
@property(nonatomic,assign) NSUInteger service;
@property(nonatomic,assign) NSUInteger deviceType;
@property(nullable,nonatomic,strong) NSString *serviceName;
@property(nullable,nonatomic,strong) NSString *classOfPair;
@property(nullable,nonatomic,strong) NSString *classOfSync;
@property(nullable,nonatomic,strong) NSString *classOfOta;
@property(nullable,nonatomic,strong) NSString *classOfScan;
@end
