//
//  CodeItem.h
//  ECGDiagnosisCodeExchanger
//
//  Created by jia yu on 2021/11/13.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
@interface CodeItem : NSObject
@property (nonatomic) NSString *itemString;
@property (nonatomic) NSInteger interpretationCode;
@end
NS_ASSUME_NONNULL_END
