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

#import "vhECGFiltersLib.h"
#import "vhECGSTFilters.h"
#import "vhECGStressTempLib.h"

FOUNDATION_EXPORT double vhECGSTFiltersVersionNumber;
FOUNDATION_EXPORT const unsigned char vhECGSTFiltersVersionString[];

