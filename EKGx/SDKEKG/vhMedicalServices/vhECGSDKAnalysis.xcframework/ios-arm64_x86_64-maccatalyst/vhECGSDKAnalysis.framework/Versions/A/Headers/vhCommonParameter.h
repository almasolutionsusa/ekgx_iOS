//
//  vhLeadMeasurement.h
//
//  Created by Han Mingjie on 2021/3/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface vhCommonParameter : NSObject
@property (nonatomic) NSString *HR;         //Average heart rate
@property (nonatomic) NSString *RR;         //RR interval
@property (nonatomic) NSString *QRS;        //QRS duration
@property (nonatomic) NSString *PR;         //PR interval
@property (nonatomic) NSString *Pd;         //Duration of P wave
@property (nonatomic) NSString *QT;         //QT interval
@property (nonatomic) NSString *QTc;        //QT interval corrected by Bazetts formula
@property (nonatomic) NSString *QTcF;       //QT interval corrected by Fridericia formula
@property (nonatomic) NSString *QTd;        //QT dispersion
@property (nonatomic) NSString *Paxis;      //Axis of P wave
@property (nonatomic) NSString *QRSaxis;    //Axis of QRS complex wave
@property (nonatomic) NSString *Taxis;      //Axis T wave
@property (nonatomic) NSString *RV1;        //R amplitude of V1
@property (nonatomic) NSString *RV5;        //S amplitude of V5
@property (nonatomic) NSString *SV1;        //S amplitude of V1
@property (nonatomic) NSString *SV5;        //R amplitude of V5

@property (nonatomic) NSDictionary *dictionary;

-(NSString *)description;
@end
NS_ASSUME_NONNULL_END
