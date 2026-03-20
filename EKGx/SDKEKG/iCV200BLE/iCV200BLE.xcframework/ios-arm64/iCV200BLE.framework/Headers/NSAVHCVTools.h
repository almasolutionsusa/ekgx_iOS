//
//  NSAVHCVTools.h
//  iCV200BLE
//
//  Created by MOON on 2026/3/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
#define MORE_DATA_COUNT 80

@interface NSAVHCVTools : NSObject
/** device more point data assemble A single point data
 * ECGs: filter end data
 * handler: a single point data
 */
+ (void)deviceECGsToSingle:(NSArray<NSArray<NSNumber *> *> *)ECGs handler:(void (^)(NSArray<NSNumber *> * _Nullable))handler;

/** A single point data assemble more point data
 * singleECGs:  single data
 * handler: more point data
 */
+ (void)singleToDeviceECGs:(NSArray <NSNumber *> *)singleECGs handler:(void (^)(NSArray<NSArray<NSNumber *> *> * _Nullable))handler;

/** clear more point cache data
 */
+ (void)clearBuffer;
@end

NS_ASSUME_NONNULL_END
