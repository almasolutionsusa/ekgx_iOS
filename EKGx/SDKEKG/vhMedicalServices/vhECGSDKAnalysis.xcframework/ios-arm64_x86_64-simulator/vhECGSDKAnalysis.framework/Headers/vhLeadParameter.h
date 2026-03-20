//
//  vhLeadMeasure.h
//
//  Created by Han Mingjie on 2021/3/5.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

@interface vhLeadParameter : NSObject
@property (nonatomic) NSString *Morpho;     //Morphology of QRS complex, NSString
@property (nonatomic) float Pa1;            //P or 1st P amplitude, mV, float
@property (nonatomic) float Pa2;            //2nd P amplitude if there is two P wave, mV, float
@property (nonatomic) NSInteger Pd;         //P duration, ms, NSInterger
@property (nonatomic) float Qa;             //Q amplitude, mV, float
@property (nonatomic) NSInteger Qd;         //Q duration, ms, NSInterger
@property (nonatomic) float Ra1;            //R or 1st R amplitude, mV
@property (nonatomic) float Ra2;            //2nd R amplitude if there is two R wave, mV, float
@property (nonatomic) NSInteger Rd1;        //R duration, ms, NSInterger
@property (nonatomic) NSInteger Rd2;        //R or 2nd R duration, ms, NSInterger
@property (nonatomic) float Sa1;            //S or 1st S amplitude, mV, float
@property (nonatomic) float Sa2;            //2nd S amplitude if there is two S wave, mV, float
@property (nonatomic) NSInteger Sd1;        //S duration, ms, NSInterger
@property (nonatomic) NSInteger Sd2;        //S or 2nd S duration, ms, NSInterger
@property (nonatomic) float Ta1;            //T or 1st S amplitude, mV, float
@property (nonatomic) float Ta2;            //2nd T amplitude if there is two T wave, mV, float
@property (nonatomic) NSInteger Td;         //T duration, ms, NSInterger
@property (nonatomic) float QRSa;           //QRS duration, ms, NSInterger
@property (nonatomic) NSInteger QRS;        //QRS amplitude of peak to peak, mV, float
@property (nonatomic) NSInteger PR;         //PR interval, ms, NSInterger
@property (nonatomic) NSInteger QT;         //QT interval, ms, NSInterger
@property (nonatomic) float STj;            //Amplitude of J point or QRS offset, mV, float
@property (nonatomic) float ST20;           //Amplitude in J + 20ms, mV, float
@property (nonatomic) float ST40;           //Amplitude in J + 40ms, mV, float
@property (nonatomic) float ST60;           //Amplitude in J + 60ms, mV, float
@property (nonatomic) float ST80;           //Amplitude in J + 80ms, mV, float
-(NSString *)description;

@end

NS_ASSUME_NONNULL_END
