//
//
//  Created by Han Mingjie on 2021/3/5.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
@interface vhTemplate:NSObject
//All above values are in samples.
@property (nonatomic) NSUInteger Pb;            //P onset in template
@property (nonatomic) NSUInteger Pe;            //P offset in template
@property (nonatomic) NSUInteger QRSb;          //QRS onset in template
@property (nonatomic) NSUInteger QRSe;          //QRS offset in template
@property (nonatomic) NSUInteger Tb;            //T onset in template, it is NOT exist when 0.
@property (nonatomic) NSUInteger Te;            //T offset in template, it is NOT exist when 0.
@end
NS_ASSUME_NONNULL_END
