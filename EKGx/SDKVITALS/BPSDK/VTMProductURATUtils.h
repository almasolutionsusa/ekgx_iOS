//
//  VTMProductURATUtils.h
//  VTMProductSDKDemo
//
//  Created by Viatom3 on 2021/2/20.
//  Copyright © 2021 viatom. All rights reserved.
//

//#import "VTMURATUtils.h"

#import <Foundation/Foundation.h>
#import <VTMProductLib/VTMProductLib.h>


NS_ASSUME_NONNULL_BEGIN


@interface VTMProductURATUtils : VTMURATUtils
+ (instancetype)sharedInstance;

-(NSData *)obbj:(VTMBPRealTimeWaveform *)wave;

@end

NS_ASSUME_NONNULL_END
