//
//  Helper.h
//  EcgService
//
//  Created by Will on 9/22/18.
//  Copyright © 2018 vhMedical. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Helper : NSObject {
}

- (id) init;
- (NSDictionary *)processECG:(NSArray *)pointsArray pps:(int)sampleRate uVpb:(float)uVpb newBorn:(int)newBorn backMode:(BOOL)backMode age:(int)age ageUnit:(NSString *)ageUnit gender:(NSString *)gender;
- (NSDictionary *)processECGManual:(NSArray *)pointsArray sample:(int)sampleRate uVpb:(float)uVpb newBorn:(int)newBorn backMode:(BOOL)backMode age:(int)age ageUnit:(NSString *)ageUnit gender:(NSString *)gender leadIndex:(int)leadIndex OnOff:(short *)OnOff OnOffs:(short **)OnOffs;
- (NSString *)getDiagnosisParameters;
- (NSArray<NSNumber *> *)getBeatPositions;
- (NSArray<NSNumber *> *)getRRs;
- (NSArray<NSString *> *)getBeatLabels;

@end
