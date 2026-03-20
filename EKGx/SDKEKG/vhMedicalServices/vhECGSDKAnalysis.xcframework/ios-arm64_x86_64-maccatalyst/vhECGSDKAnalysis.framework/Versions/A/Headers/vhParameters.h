//
//  vhMeasures.h
//
//  Created by Han Mingjie on 2021/3/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class vhLeadParameter;
@interface vhParameters : NSObject
@property (nonatomic) vhLeadParameter *I;
@property (nonatomic) vhLeadParameter *II;
@property (nonatomic) vhLeadParameter *III;
@property (nonatomic) vhLeadParameter *aVR;
@property (nonatomic) vhLeadParameter *aVL;
@property (nonatomic) vhLeadParameter *aVF;
@property (nonatomic) vhLeadParameter *V1;
@property (nonatomic) vhLeadParameter *V2;
@property (nonatomic) vhLeadParameter *V3;
@property (nonatomic) vhLeadParameter *V4;
@property (nonatomic) vhLeadParameter *V5;
@property (nonatomic) vhLeadParameter *V6;

//return array for every lead's parameter.
-(NSArray <vhLeadParameter *>*)leadsParameterArray;
@end
NS_ASSUME_NONNULL_END
