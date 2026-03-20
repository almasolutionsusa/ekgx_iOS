//
//  vhECGCodes.h
//  vhECGCodes
//
//  Created by jia yu on 2021/11/12.
//

#import <Foundation/Foundation.h>

//! Project version number for vhECGCodes.
FOUNDATION_EXPORT double vhECGCodesVersionNumber;

//! Project version string for ECGDiagnosisCodeExchanger.
FOUNDATION_EXPORT const unsigned char vhECGCodesVersionString[];

#import <vhECGCodes/vhECGCodes.h>
#import <vhECGCodes/CodeGroup.h>
#import <vhECGCodes/CodeItem.h>

NS_ASSUME_NONNULL_BEGIN
@interface vhECGCodes : NSObject
+(NSArray <NSString *>*)availableLanguageCodes;
+(vhECGCodes *)shareCodeExchange;

@property (nonatomic) NSString *currentLanguageCode;
@property (nonatomic,readonly) NSArray <CodeGroup *>* interpretationCodesGroupsArray;
-(NSString *)withInterpretationCodes:(NSArray *)codesArray;
-(NSString *)withInterpretationCodes:(NSArray *)codesArray withMinnesotaCodes:(NSArray *)monnesotaCodes;

-(NSString * _Nullable )stringForCode:(NSInteger)interpretationCode;

-(BOOL)isAvailableLangCode:(NSString *)targetLanguageCode;
@end
NS_ASSUME_NONNULL_END
