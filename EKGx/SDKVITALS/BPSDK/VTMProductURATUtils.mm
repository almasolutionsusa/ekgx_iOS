//
//  VTMProductURATUtils.m
//  VTMProductSDKDemo
//
//  Created by Viatom3 on 2021/2/20.
//  Copyright © 2021 viatom. All rights reserved.
//

#import "VTMProductURATUtils.h"


@implementation VTMProductURATUtils

static VTMProductURATUtils *URATUtils = nil;
+ (instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        URATUtils = [[(Class)self alloc] init];
    });
    return URATUtils;
}

- (NSData *)obbj:(VTMBPRealTimeWaveform *)waveform {
    NSData *tempData = [NSData dataWithBytes:waveform->data length:sizeof(waveform->data)];
    return  tempData;
}


@end
