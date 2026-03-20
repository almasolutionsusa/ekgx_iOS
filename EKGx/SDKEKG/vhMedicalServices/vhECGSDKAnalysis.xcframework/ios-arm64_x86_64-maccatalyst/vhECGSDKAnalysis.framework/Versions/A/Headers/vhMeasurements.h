//
//  vhMeasurements.h
//
//  Created by Han Mingjie on 2021/3/6.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class vhCommonParameter;
@interface vhMeasurements : NSObject
@property (nonatomic) vhCommonParameter *merge;
@property (nonatomic) NSString * _Nullable QTmaxLeadName;   //QT maximum
@property (nonatomic) NSString * _Nullable QTmaxLeadValue;  //The lead of QT maximum
@property (nonatomic) NSString * _Nullable QTminLeadName;   //QT minimum
@property (nonatomic) NSString * _Nullable QTminLeadValue;  //The lead of QT minimum
@end
NS_ASSUME_NONNULL_END
