//
//  vhLeadTemplate.h
//  vhECGSDKAnalysis
//
//  Created by Han Mingjie on 2021/3/7.
//

#import <vhECGSDKAnalysis/vhECGSDKAnalysis.h>

NS_ASSUME_NONNULL_BEGIN
@interface vhLeadTemplate : vhTemplate
@property (nonatomic) NSString *leadName;
@property (nonatomic) NSInteger leadIndex;

// These instance properties give a instance method templateData to get a 1D array of ECG template data of each lead and some instance properties(Pb, Pe, QRSb, QRSe, Tb, Te) to get the onsets and offsets of P, QRS, T of  each lead.
-(NSArray <NSNumber *>*)templateData;
@end
NS_ASSUME_NONNULL_END


