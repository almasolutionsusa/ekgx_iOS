//
//  vhMutableTemplateAnalysis.h
//  vhECGSDKAnalysis
//
//  Created by Han Mingjie on 2021/3/8.
//

#import <vhECGSDKAnalysis/vhECGSDKAnalysis.h>

NS_ASSUME_NONNULL_BEGIN
@interface vhMutableTemplateAnalysis : vhTemplateAnalysis
-(id)initWithManualArray:(NSArray <NSArray <NSNumber *>*>*)onoffsArray;

-(id)initWithArray:(NSArray <NSArray <NSNumber *>*>*)onoffsArray curveTemplate:(NSArray <NSArray <NSNumber *>*>*)templatesArray;
@end
NS_ASSUME_NONNULL_END
