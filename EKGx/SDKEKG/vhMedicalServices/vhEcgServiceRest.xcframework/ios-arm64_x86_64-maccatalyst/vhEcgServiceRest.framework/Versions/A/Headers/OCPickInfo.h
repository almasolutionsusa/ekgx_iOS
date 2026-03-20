//
//  NSObject+PickInfo.h
//  EcgService
//
//  Created by hspecg on 2020/5/29.
//  Copyright © 2020 vhMedical. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OCPickInfo: NSObject // (PickInfo)

/// Set Data for Gesture
/// - Parameters:
///   - I: Array of Lead I, short
///   - II: Array of Lead II, short
///   - pos: The positions of all beats, long
///   - fs: Sampling Rate of data
+ (bool)setData: (NSArray *)Iint16 II:(NSArray *)IIint16 pos:(NSArray *)posInt32 fs:(int)fs;

// Release data buffer
+ (void)destroy;

/// Get QRS Axis between two fingers.
/// - Parameters:
///   - pos1: the position of left finger
///   - pos2: the positions of right finger
/// - Returns:
///   QRS axis in degree
+ (float)qrSaxis: (long)pos1 pos2:(long)pos2;

/// Get Average HR duration between two fingers.
/// - Parameters:
///   - pos1: the position of left finger
///   - pos2: the positions of right finger
/// - Returns:
///   HR in bpm, if HR<0 don't draw auxiliary lines
+ (int)hr: (long)pos1 pos2:(long)pos2;

@end

NS_ASSUME_NONNULL_END
