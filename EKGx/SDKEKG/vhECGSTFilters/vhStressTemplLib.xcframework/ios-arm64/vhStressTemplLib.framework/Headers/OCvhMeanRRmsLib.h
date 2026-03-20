//
//  OCvhMeanRRmsLib.h
//  vhStressTemplLib
//
//  Created by hspecg on 2024/4/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCvhMeanRRmsLib : NSObject

- (id)init;
- (id)init:(short)fs chn:(short)chn freqNotch:(short)freqNotch uVpb:(double)uVpb;
- (void)dealloc;
- (void)create:(short)fs chn:(short)chn freqNotch:(short)freqNotch uVpb:(double)uVpb;
- (short)meanRRms:(NSArray *)data;
- (short)meanHR:(NSArray *)data;

@end

NS_ASSUME_NONNULL_END
