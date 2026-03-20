//
//  vhECGStressTempLib.h
//  CPETEcgModule
//
//  Created by moon_zm on 2024/3/20.
//

#import <Foundation/Foundation.h>

///st calculate
NS_ASSUME_NONNULL_BEGIN

@interface vhECGStressTempLib : NSObject
+(instancetype)shared;

#pragma mark - ST analyse
//if need setting rate and uVpb, after st calculate
- (void)setECGRate:(int)rate chn:(int)chn uVpb:(double)uVpb;
/// Clear buffer, when set rate already clear buffer
//- (void)destroy;
/**return 新的12导联心电模版
 * templ：12导联的，静息心电图分析
 * posQ: 样本中QRS起始点
 * posJ: 样本中QRS偏移量，J点
 * postJms: J点后的ms
 */
- (NSArray<NSArray<NSNumber *> *> * _Nullable)restTemplWithTempl:(NSArray<NSArray<NSNumber *> *> * _Nonnull)templ posQ:(int16_t)posQ posJ:(int16_t)posJ postJms:(int16_t)postJms;
/** return：获取posZ(Zero voltage point), posJ, postJms
 posZ：零电压点
 posJ：偏移量J点
 postJms：J点后ms
 样本中posZ，posJ，postJms 可能为空
 */
- (NSArray<NSNumber *> * _Nullable)getPos;
/**return：为每组抽样数据匹配模版
 * data：a group 12-lead sampling data
 */
- (NSArray<NSArray<NSNumber *> *> * _Nullable)matchWithData:(NSArray<NSNumber *> * _Nonnull)data;
/**获取新的12导联模版
 */
- (NSArray<NSArray<NSNumber *> *> * _Nullable)getTempl;
/** Set new posZ,posJ
 */
- (void)setPosWithPosZ:(int16_t)posZ posJ:(int16_t)posJ;
/**Set new postJms
 */
- (void)setPostJmsWithPostJms:(int16_t)postJms;
/** 获取12导联ST段段斜率slope，单位mV/s
 */
- (NSArray<NSNumber *> * _Nullable)getSTslope;
/** 获取12导联 ST段的值，单位uV
 */
- (NSArray<NSNumber *> * _Nullable)getSTuv;

#pragma mark - optional

/**采样时计算心率，返回一个合适的心率
 *data1：12导联中，1导联的采样数据
 *data2：12导联中，2导联的采样数据
 *data3：12导联中，3导联的采样数据
 */
- (int16_t)getMeanHRWithData1:(int16_t)data1 data2:(int16_t)data2 data3:(int16_t)data3;

/**获取杜克比分（Duke score）
 * seconds：运动持续时间
 * deepestSTwithmV：ST的低压
 * anginaPectoris：心绞痛值（0：无，1：无限制，2：有限制）
 */
+ (int16_t)getDukeWithStressSeconds:(int16_t)seconds deepestSTwithmV:(float)mV anginaPectoris:(int16_t)index;
/** 获取PWC130/150/170，数组中有三个元素，如果无效时元素为-1
 * power：运动阶段，功率值（W）
 * hr：bpm中与功率有关的心率数组
 */
+ (NSArray<NSNumber *> * _Nullable)getPWCWithPower:(NSArray<NSNumber *> * _Nonnull)power andHR:(NSArray<NSNumber *> * _Nonnull)hr;
@end

NS_ASSUME_NONNULL_END
