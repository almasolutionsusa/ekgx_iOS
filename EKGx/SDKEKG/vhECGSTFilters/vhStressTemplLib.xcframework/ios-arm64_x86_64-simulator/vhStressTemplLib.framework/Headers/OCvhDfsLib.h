//
//  OCvhDfsLib.h
//  vhStressTemplLib
//
//  Created by hspecg on 2025/4/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCvhDfsLib : NSObject

- (id)init;
- (id)init:(const char *)me chn:(short)chn uVpb:(double)uVpb;
- (void)destroy;
- (bool)create:(const char *)me chn:(short)chn uVpb:(double)uVpb;
- (NSArray *)getData:(NSArray *)data;

@end

NS_ASSUME_NONNULL_END
