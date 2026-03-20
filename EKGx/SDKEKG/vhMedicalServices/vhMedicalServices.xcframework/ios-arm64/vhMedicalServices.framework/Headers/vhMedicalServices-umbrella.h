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

#import "vhECGAnalysisObject.h"
#import "vhECGCodesLib.h"
#import "vhECGServiceRestLib.h"
#import "vhMedicalServices.h"

FOUNDATION_EXPORT double vhMedicalServicesVersionNumber;
FOUNDATION_EXPORT const unsigned char vhMedicalServicesVersionString[];

