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

#import "YKZipManager.h"
#import "SSZipArchive.h"
#import "SSZipCommon.h"

FOUNDATION_EXPORT double YKZipKitVersionNumber;
FOUNDATION_EXPORT const unsigned char YKZipKitVersionString[];

