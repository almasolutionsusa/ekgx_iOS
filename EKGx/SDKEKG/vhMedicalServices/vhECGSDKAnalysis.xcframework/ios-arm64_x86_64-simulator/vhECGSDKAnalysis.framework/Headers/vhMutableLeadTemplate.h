//
//  vhMutableLeadTemplate.h
//  vhECGSDKAnalysis
//
//  Created by Han Mingjie on 2021/3/7.
//

#import "vhLeadTemplate.h"

NS_ASSUME_NONNULL_BEGIN
@interface vhMutableLeadTemplate : vhLeadTemplate
-(id)initWithArray:(NSArray *)positionArray index:(NSInteger)index name:(NSString *)name;
@end
NS_ASSUME_NONNULL_END
