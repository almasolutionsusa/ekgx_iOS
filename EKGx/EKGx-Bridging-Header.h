//
//  EKGx-Bridging-Header.h
//  EKGx
//
//  Exposes Objective-C SDK headers to Swift.
//

#import <iCV200BLE/iCV200BLE.h>
#import <iCV200BLE/vhiCVBleManager.h>
#import <iCV200BLE/NSAVHCVTestData.h>
#import <iCV200BLE/NSAVHCVDataUtil.h>
#import <iCV200BLE/NSAVHCVTools.h>
#import <iCV200BLE/NSCheckChannel.h>

#import <vhMedicalServices/vhECGAnalysisObject.h>
#import <vhECGCodes/vhECGCodes.h>
#import <vhECGCodes/CodeGroup.h>
#import <vhECGCodes/CodeItem.h>

// BPSDK + OximeterSDK — device only (no simulator slice)
#if !TARGET_OS_SIMULATOR
#import "VTBLEUtils.h"
#import <VTMProductLib/VTMProductLib.h>
#import "VTMProductURATUtils.h"
#import "CCRBlueToothManager.h"
#import "CRAP20SDK.h"
#import "CRBleDevice.h"
#endif
