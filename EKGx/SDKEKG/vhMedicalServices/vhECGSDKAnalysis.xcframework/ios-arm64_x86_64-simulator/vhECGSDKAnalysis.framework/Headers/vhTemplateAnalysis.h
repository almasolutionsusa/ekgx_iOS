//
//  ECG Template analysis result.
//
//  Created by Han Mingjie on 2021/3/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class vhLeadTemplate,vhMergeTemplate;
@interface vhTemplateAnalysis : NSObject
// The instance property includes merged onsets and offsets of P,QRS,T of 12-lead.
@property (nonatomic) NSUInteger Pb;            //P onset in template
@property (nonatomic) NSUInteger Pe;            //P offset in template
@property (nonatomic) NSUInteger QRSb;          //QRS onset in template
@property (nonatomic) NSUInteger QRSe;          //QRS offset in template
@property (nonatomic) NSUInteger Tb;            //T onset in template, it is NOT exist when 0.
@property (nonatomic) NSUInteger Te;            //T offset in template, it is NOT exist when 0.

// The instance method is used to obtain a 2D Array of ECG template data of 12-leads.
-(NSArray <NSArray <NSNumber *>*>*)templateData;

//above is template analysis for every lead.
@property (nonatomic) vhLeadTemplate *I;               //I lead analysis result
@property (nonatomic) vhLeadTemplate *II;              //II lead analysis result
@property (nonatomic) vhLeadTemplate *III;             //III lead analysis result
@property (nonatomic) vhLeadTemplate *aVR;             //aVR lead analysis result
@property (nonatomic) vhLeadTemplate *aVL;             //aVL lead analysis result
@property (nonatomic) vhLeadTemplate *aVF;             //aVF lead analysis result
@property (nonatomic) vhLeadTemplate *V1;             //V1 lead analysis result
@property (nonatomic) vhLeadTemplate *V2;             //V2 lead analysis result
@property (nonatomic) vhLeadTemplate *V3;             //V3 lead analysis result
@property (nonatomic) vhLeadTemplate *V4;             //V4 lead analysis result
@property (nonatomic) vhLeadTemplate *V5;             //V5 lead analysis result
@property (nonatomic) vhLeadTemplate *V6;             //V6 lead analysis result

// This instance method gives another way to get the 1D array of ECG template data  and the onsets and offsets of P, QRS, T of  each lead, which is the same as vhECGanalysis.templateAnalysisResult.I, II, … V6
// return nil when No templates.
-(NSArray <vhLeadTemplate *>* _Nullable )leadsTemplateAnalisysArray;

@end
NS_ASSUME_NONNULL_END
