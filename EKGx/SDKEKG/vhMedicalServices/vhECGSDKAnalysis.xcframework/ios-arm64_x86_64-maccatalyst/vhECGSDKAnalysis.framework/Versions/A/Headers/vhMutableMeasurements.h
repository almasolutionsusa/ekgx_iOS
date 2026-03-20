//
//  vhMutableMeasurements.h
//  vhECGSDKAnalysis
//
//  Created by Han Mingjie on 2021/3/8.
//

#import <vhECGSDKAnalysis/vhECGSDKAnalysis.h>


extern NSString * _Nullable QTmaxName;
extern NSString * _Nullable QTmaxValue;
extern NSString * _Nullable QTminName;
extern NSString * _Nullable QTminValue;

NS_ASSUME_NONNULL_BEGIN
@interface vhMutableMeasurements : vhMeasurements
@property (nonatomic) vhCommonParameter *I;
@property (nonatomic) vhCommonParameter *II;
@property (nonatomic) vhCommonParameter *III;
@property (nonatomic) vhCommonParameter *aVR;
@property (nonatomic) vhCommonParameter *aVL;
@property (nonatomic) vhCommonParameter *aVF;
@property (nonatomic) vhCommonParameter *V1;
@property (nonatomic) vhCommonParameter *V2;
@property (nonatomic) vhCommonParameter *V3;
@property (nonatomic) vhCommonParameter *V4;
@property (nonatomic) vhCommonParameter *V5;
@property (nonatomic) vhCommonParameter *V6;

-(id)initWithArray:(NSArray<NSDictionary<NSString *, NSString *> *> * _Nullable)measurement;
@end
NS_ASSUME_NONNULL_END
