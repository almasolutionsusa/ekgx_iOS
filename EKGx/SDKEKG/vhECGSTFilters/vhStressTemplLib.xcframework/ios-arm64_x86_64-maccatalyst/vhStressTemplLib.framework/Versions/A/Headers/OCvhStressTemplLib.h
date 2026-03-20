//
//  OCvhStressTemplLib.h
//  vhStressTemplLib
//
//  Created by hspecg on 2021/9/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCvhStressTemplLib : NSObject

- (id)init;
- (bool)create:(const char *)me fs:(short)fs chn:(short)chn uVpb:(double)uVpb mutex_lock:(bool)mutex_lock;
- (void)destroy;
- (NSArray *)restTempl:(NSArray *)templ posQ:(short) posQ posJ:(short)posJ postJms:(short)postJms;
- (NSArray *)getPos;
- (NSArray *)match:(NSArray *)data;
- (NSArray *)getTempl;
- (void)setPos:(short)posZ Jpoint:(short)posJ;
- (void)setPostJms:(short)postJms;
- (NSArray *)getSTslope;
- (NSArray *)getSTuv;
- (short)getMeanHR:(short)data1 data2:(short)data2 data3:(short)data3;
+ (short)getDuke:(short)stressSeconds deepestSTwithmV:(float)mV anginaPectoris:(short)index;
+ (NSArray *)getPWC:(NSArray *)power hr:(NSArray*)hr;

@end

NS_ASSUME_NONNULL_END
