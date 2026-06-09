//
//  ICECGData.h
//  ICDeviceManager
//
//  Created by Guobin Zheng on 2026/1/22.
//  Copyright © 2026 Symons. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
/**
 ECG数据
 */
@interface ICECGData : NSObject

//0:没有拿手柄 1:正常数据
@property (nonatomic, assign) NSUInteger state;

@property (nonatomic, assign) NSUInteger hr;

@property (nonatomic, strong) NSArray<NSNumber *> *ecgs;

@end

NS_ASSUME_NONNULL_END
