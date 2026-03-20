//
//  OCvhFiltersLib.h
//  vhStressTemplLib
//
//  Created by hspecg on 2024/5/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCvhFiltersLib : NSObject

- (id)init;
- (id)init:(const char *)me fs:(short)fs chn:(short)chn freqLpass:(short)freqLpass freqNotch:(short)freqNotch smooth:(short)strenth;
//- (void)dealloc;
- (void)destroy;
- (bool)create:(const char *)me fs:(short)fs chn:(short)chn freqLpass:(short)freqLpass freqNotch:(short)freqNotch smooth:(short)strenth;
- (bool)update:(short)fs freqLpass:(short)freqLpass freqNotch:(short)freqNotch smooth:(short)strenth;
- (void)switchFilters:(bool)onOffLpass onOffNotch:(bool)onOffNotch onOffSmooth:(bool)onOffSmooth;
- (NSArray *)filters:(NSArray *)data;

@end

NS_ASSUME_NONNULL_END
