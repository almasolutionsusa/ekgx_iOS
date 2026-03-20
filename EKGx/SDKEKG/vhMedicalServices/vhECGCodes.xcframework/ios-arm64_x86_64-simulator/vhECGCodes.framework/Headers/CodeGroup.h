//
//  CodeGroup.h
//  ECGDiagnosisCodeExchanger
//
//  Created by jia yu on 2021/11/12.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class CodeItem;
@interface CodeGroup : NSObject
@property (nonatomic) NSString *key;
@property (nonatomic) NSString *name;
@property (nonatomic) NSMutableArray <CodeItem *>*items;
-(id)initWithName:(NSString *)name items:(NSArray *)itemsArray;
@end
NS_ASSUME_NONNULL_END
