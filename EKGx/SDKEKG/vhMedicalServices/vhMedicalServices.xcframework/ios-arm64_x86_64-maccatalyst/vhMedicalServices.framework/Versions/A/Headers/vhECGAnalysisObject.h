//
//  vhECGAnalysisObject.h
//  vhECGSDKAnalysis
//
//  Created by Han Mingjie on 2021/3/6.
//
/*
 The object is used to perform ECG measurements and give some possible interpretations that must be confirmed by the physician.
 */

#import <Foundation/Foundation.h>
#import <vhECGSDKAnalysis/vhECGSDKAnalysis.h>

typedef NS_ENUM(NSInteger, vhECGPatientGender) {
    vhECGPatientGender_Male = 0,
    vhECGPatientGender_Female = 1,
    vhECGPatientGender_Unknow = 2
};


NS_ASSUME_NONNULL_BEGIN
@interface vhECGAnalysisObject : NSObject
// ECG templates are calculated by the average of dominant heart beats.
// The instance property includes merged onsets and offsets of P,QRS,T of 12-lead.
@property (nonatomic,readonly) vhTemplateAnalysis *templateAnalysisResult;


@property (nonatomic,readonly) NSArray <NSArray <NSNumber *>*> * ECGsArray;
@property (nonatomic,readonly) NSInteger ecgRate;
@property (nonatomic,readonly) NSInteger patientAge;
@property (nonatomic,readonly) vhECGPatientGender patientGender;

//the result is parameters for analysised ECG.
//The instance property includes 12 structures, each structure gives the parameters of each lead of I, II, III, aVR, aVL, aVF, V1, V2, V3, V4, V5, V6.
@property (nonatomic,readonly) vhParameters *parametersResult;

//the result is measurement for analysised ECG.
@property (nonatomic,readonly) vhMeasurements *measurementsResult;

//the result is minnesota codes for the ECG.
@property (nonatomic,readonly) NSArray<NSString *> * _Nullable minnesotaCodes;

//The text language of the interpretations depends on the operating system language. The SDK provides several local languages, The default language is English.
@property (nonatomic,readonly) NSArray<NSString *> * _Nullable interpretation;


//Beat positions in samples
@property (nonatomic,readonly) NSArray<NSNumber *> * _Nullable beatPositions;
//RR durations in ms between two beats.
@property (nonatomic,readonly) NSArray<NSNumber *> * _Nullable RRs;


// initail the analysis object.
// return nil when this SDK has expired.
-(id)init;

// analysis ECG include 12 leads with rate, and patient's age and gender.
// The Analysis results can be obtained from the instance properties of vhECGAnalysisObject
// YES if success or NO if fail(maybe abnormal ecg_array_array)
// ECGsArray: 12 x length 2D Array ECG data, length is the number of data per lead which is no less than 10 seconds.
// ecgRate: sampling rate coming from ECG device connecting
// age: patient’s age in years
// gender: patient’s gender which is one of enumerations, vhECGPatientGender_Male or vhECGPatientGender_Female or vhECGPatientGender_Unknow.
-(BOOL)analysisECG:(NSArray <NSArray <NSNumber *>*>*)ECGsArray withRate:(NSInteger)ecgRate withPatientAge:(NSInteger)age withPatientGender:(vhECGPatientGender)gender;


// After analisysECG function, the ECG one lead's P or QRS or T seek want to changed by doctor.
// let self.templateAnalysisResult.I.Pb  with target index.
// I is target lead
// Pb is new position of P wave begin, also Pe or QRSb or QRSe or Tb or Te can be.
// manualAnalisysLead function for re-analisys with new position,
// after that self.parametersResult.I.Pd and self.parametersResult.I.PR etc about P wave changed.
-(BOOL)manualAnalisysLead:(vhLeadTemplate *)targetLead;

// After analisysECG functon, Doctor want to changed position for all leads.
// let templateAnalysisResult.Pb with new index position.
// Pb is P wave begin index.
// manualAnalysisAllLeadWithECGs function for re-analisys with new position.
// after that, self.measurementsResult.merge.Pd and self.measurementsResult.merge.PR etc about P wave chengd.
-(BOOL)manualAnalysisAllLead;

@end

NS_ASSUME_NONNULL_END
