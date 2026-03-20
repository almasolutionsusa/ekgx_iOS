//
//  vhECGServiceRestLib.h
//  CPETEcgModule
//
//  Created by moon_zm on 2024/3/20.
//

#import <Foundation/Foundation.h>
#import <vhEcgServiceRest/vhEcgServiceRest-Swift.h>
///封装vhEcgServiceRest库(诊断库)（业务使用此类的接口）

NS_ASSUME_NONNULL_BEGIN

/** AnalysisResult
 @property (nonatomic, copy) NSArray<NSString *> * _Nullable autoInterpretationCodes;
 @property (nonatomic, copy) NSArray<NSString *> * _Nullable minnesotaCodes;
 @property (nonatomic, copy, getter=template, setter=setTemplate:) NSArray<NSArray<NSNumber *> *> * _Nullable template_;
 @property (nonatomic, copy) NSString * _Nullable heartBeatRate;
 @property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> * _Nullable measurement;
 @property (nonatomic, copy) NSArray<NSArray<NSNumber *> *> * _Nullable onoff;
 @property (nonatomic, copy) NSString * _Nullable error;
 @property (nonatomic, copy) NSString * _Nullable parameters;
 @property (nonatomic, copy) NSArray<NSNumber *> * _Nullable RRs;
 @property (nonatomic, copy) NSArray<NSNumber *> * _Nullable beatPositions;
 @property (nonatomic, copy) NSArray<NSString *> * _Nullable beatTypes;
 - (nonnull instancetype)init;
 */

@interface vhECGServiceRestLib : NSObject
+ (instancetype)shareId;
/**心电分析前先做数据校验，校验数据长度，不能过长，不能过短，否则crash
 * data：buffer存的原始心电数据
 * rate：心电速度
 */

+ (NSArray<NSArray<NSNumber *> *> * _Nonnull)checkECGData:(NSArray<NSArray<NSNumber *> *> * _Nonnull)data rate:(float)rate;
/**心电分析
 * data:心电数据（传入checkECGDataWithDuration校验后的心电数据）
 * sampling:取样,心电速度（rate）
 * age:年龄
 * ageUnit:年龄单位
 * gender:性别
 * newBornMode:新生儿模式
 * backRecording:是否为后记录模式
 */
- (AnalysisResult * _Nonnull)analyzeWithData:(NSArray<NSArray<NSNumber *> *> * _Nonnull)data sampling:(NSInteger)sampling age:(NSInteger)age ageUnit:(NSString * _Nonnull)ageUnit gender:(NSString * _Nonnull)gender newBornMode:(NSInteger)newBornMode backRecording:(BOOL)backRecording;
/**
 * data:心电数据（传入checkECGDataWithDuration校验后的心电数据）
 * sampling:取样,心电速度（rate）
 * age:年龄
 * ageUnit:年龄单位
 * gender:性别
 * newBornMode:新生儿模式
 * backRecording:是否为后记录模式
 * lead:导联
 * onOff:
 * onOffs:
 */
- (AnalysisResult * _Nonnull)analyzeManualWithData:(NSArray<NSArray<NSNumber *> *> * _Nonnull)data sampling:(NSInteger)sampling age:(NSInteger)age ageUnit:(NSString * _Nonnull)ageUnit gender:(NSString * _Nonnull)gender newBornMode:(NSInteger)newBornMode backRecording:(BOOL)backRecording lead:(NSInteger)lead onOff:(int16_t * _Nullable)onOff onOffs:(int16_t * _Nullable * _Nullable)onOffs;
@end

NS_ASSUME_NONNULL_END
