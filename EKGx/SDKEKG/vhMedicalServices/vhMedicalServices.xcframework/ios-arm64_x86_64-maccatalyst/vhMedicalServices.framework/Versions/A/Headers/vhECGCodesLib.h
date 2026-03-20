//
//  vhECGCodesLib.h
//  vhMedicalServices
//
//  Created by moon_zm on 2025/6/17.
//

#import <Foundation/Foundation.h>
#import <vhECGCodes/vhECGCodes.h>

NS_ASSUME_NONNULL_BEGIN

@interface vhECGCodesLib : NSObject
@property (nonatomic) NSString *currentLanguageCode;
@property (nonatomic,readonly) NSArray <CodeGroup *>* interpretationCodesGroupsArray;

+ (instancetype)shared;
///available languagage codes list
+(NSArray <NSString *>*)availableLanguageCodes;
///codes list interpretation string eg:[a, b, c] -> "a.b.c."
-(NSString *)withInterpretationCodes:(NSArray *)codesArray;
///codes list interpretation string eg:[a, b, c] -> "a.b.c."
-(NSString *)withInterpretationCodes:(NSArray *)codesArray withMinnesotaCodes:(NSArray *)monnesotaCodes;
///codes number interpretation string eg: 100 -> 无心电信号
-(NSString * _Nullable )stringForCode:(NSInteger)interpretationCode;
/// target lauguage is available
-(BOOL)isAvailableLangCode:(NSString *)targetLanguageCode;
@end

NS_ASSUME_NONNULL_END
