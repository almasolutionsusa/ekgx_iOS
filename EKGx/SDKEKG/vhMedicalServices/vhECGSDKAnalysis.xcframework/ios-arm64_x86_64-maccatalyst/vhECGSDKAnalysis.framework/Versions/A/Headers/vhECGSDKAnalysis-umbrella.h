#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "vhCommonParameter.h"
#import "vhMeasurements.h"
#import "vhMutableCommonParameter.h"
#import "vhMutableMeasurements.h"
#import "vhLeadParameter.h"
#import "vhMutableParameters.h"
#import "vhParameters.h"
#import "vhLeadTemplate.h"
#import "vhMutableLeadTemplate.h"
#import "vhMutableTemplateAnalysis.h"
#import "vhTemplate.h"
#import "vhTemplateAnalysis.h"
#import "vhECGSDKAnalysis.h"

FOUNDATION_EXPORT double vhECGSDKAnalysisVersionNumber;
FOUNDATION_EXPORT const unsigned char vhECGSDKAnalysisVersionString[];

