//
//  BTScanFilter.h
//  AHDevicePlugin
//
//  Created by sky on 2022/7/28.
//  Copyright © 2022 sky. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BTScanFilter : NSObject

@property(nonatomic,strong) NSArray *scanTypes;
@property(nonatomic,assign) NSUInteger advType;

@end
