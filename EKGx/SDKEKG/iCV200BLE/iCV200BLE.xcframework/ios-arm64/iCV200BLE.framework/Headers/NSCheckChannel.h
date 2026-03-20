//
//  NSCheckChannel.h
//  iCV200BLE
//
//  Created by moon_zm on 2025/4/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSCheckChannel : NSObject
+(instancetype)shared;
//MARK: - 解析通道数据，心电16字节的原始数据，转换成8通道数据
/** channelData:8通道原始数据 16 byte
 * factor:解析系数
 * isDecode:是否需要解密，解密密钥固定为 0x8B
 */
- (NSArray<NSNumber *> *)analysis_originalChannelData:(NSArray<NSNumber *> *)channelData
                                               factor:(float)factor
                                             isDecode:(BOOL)isDecode;
/**
 * 8通道数据计算12导联数据
 * [channelStatus] 通道状态
 * [fnChannelStatus] f n通道状态
 * [channelData] 通道数据[R C6 C5 C4 C3 C2 C1 L]
 *  //苹果端：L: Short, C1: Short, C2: Short, C3: Short, C4: Short, C5: Short, C6: Short, R: Short,
 * [zeroWithLeadFall] true 如果导联脱落, 强制该导联值为0
 * [leadData] 计算后导联数据[V6 V5 V4 V3 V2 V1 avF avL avR III II I]
 * 返回 12导联
 */
- (NSArray<NSNumber *> *)channel8ToLead12:(int)channelStatus
                          fnChannelStatus:(int)fnChannelStatus
                              channelData:(NSArray<NSNumber *> *)channelData
                         zeroWithLeadFall:(BOOL)zeroWithLeadFall;
@end

NS_ASSUME_NONNULL_END
