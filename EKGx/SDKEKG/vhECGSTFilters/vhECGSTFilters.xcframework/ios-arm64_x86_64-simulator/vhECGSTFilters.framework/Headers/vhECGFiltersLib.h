//
//  vhECGFiltersLib.h
//  CPETvhECGService
//
//  Created by moon_zm on 2024/9/12.
//

///ecg filter manager
#import <Foundation/Foundation.h>

///(滤波器)（业务使用此类的接口）
NS_ASSUME_NONNULL_BEGIN
///low 低通(Off, 40Hz,70Hz,100Hz)
typedef NS_ENUM(NSInteger, kFreqLowType) {
    kLowType_OFF = 0,
    kLowType_40 = 40,
    kLowType_70 = 70,
    kLowType_100 = 100,
};

//AC 工频( Off, 50Hz,60Hz)
typedef NS_ENUM(NSInteger, kFreqNotchType) {
    kNotchType_OFF = 0,
    kNotchType_50 = 50,
    kNotchType_60 = 60,
};

//Smooth 肌电
typedef NS_ENUM(NSInteger, kSmoothType) {
    kSmoothType_OFF = 0,
    kSmoothType_weak = 1,
    kSmoothType_strong = 2,
};

@interface vhECGFiltersLib : NSObject
@property (nonatomic, assign, readonly) int ecgRate;//default is 500
@property (nonatomic, assign, readonly) int freq_low;//default is 0, OFF
@property (nonatomic, assign, readonly) int freq_notch;//default is 0, OFF
@property (nonatomic, assign, readonly) int smoothStrength; //default is 2, strong
@property (nonatomic, assign, readonly) BOOL isOpen; //default is YES (this filter switch)
+ (instancetype)shared;
#pragma mark - set filter -
///set rate
- (void)setFilterWithRate:(int)rate uVpb:(double)uVpb;
/// set low
- (void)setFilterFreqLow:(kFreqLowType)freqLow;
/// set ac
- (void)setFilterFreqNotch:(kFreqNotchType)freqNotch;
/// set mooth
- (void)setFilterFreqMooth:(kSmoothType)freqMooth;
/// set filter switch
- (void)setFilterSwitch:(BOOL)isOpen;

///dispatch asyc original ecgs to filter ecgs
- (void)filtersECGsData:(NSArray <NSArray <NSNumber *>*>* _Null_unspecified)ECGs dataHandler:(void(^)(NSArray <NSArray <NSNumber *>*>* _Nullable ecgData))handler hbrHandler:(void(^)(int hbr))hbrHandler;

- (void)clearBuffer;
@end

NS_ASSUME_NONNULL_END
