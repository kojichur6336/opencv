//
//  YKServiceIOSurface.m
//  YKService
//
//  Created by liuxiaobin on 2025/11/5.
//


#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <IOKit/IOTypes.h>
#import "YKServiceLogger.h"
#import <ImageIO/ImageIO.h>
#import "YKServiceIOSurface.h"
#import <CoreImage/CoreImage.h>
#import <MobileCoreServices/MobileCoreServices.h>


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

#ifdef __cplusplus
extern "C" {
#endif
    CFIndex CARenderServerGetDirtyFrameCount(void *);
#ifdef __cplusplus
}
#endif

// 全局静态变量，用于记录上一帧的 dirty frame 计数。
// CARenderServer 会在屏幕内容发生变化时递增 dirtyFrameCount。
static CFIndex sLastDirtyFrame = 0;


typedef struct __IOSurface *IOSurfaceRef;
UIKIT_EXTERN CGImageRef UICreateCGImageFromIOSurface(IOSurfaceRef);
typedef kern_return_t IOMobileFramebufferReturn;
typedef io_service_t IOMobileFramebufferService;
typedef void * IOMobileFramebufferConnection;
typedef void * CoreSurfaceBufferRef;
typedef void * CoreSurfaceAcceleratorRef;
const mach_port_t kIOMasterPortDefault;
typedef struct __IOSurfaceAccelerator *IOSurfaceAcceleratorRef;
typedef IOReturn IOSurfaceAcceleratorReturn;

// 声明一些 CoreSurface 和 IOSurfaceAccelerator 相关的函数
IOSurfaceAcceleratorReturn IOSurfaceAcceleratorCreate(CFAllocatorRef allocator, uint32_t type, IOSurfaceAcceleratorRef *outAccelerator);
IOSurfaceAcceleratorReturn IOSurfaceAcceleratorTransferSurface(IOSurfaceAcceleratorRef accelerator, IOSurfaceRef sourceSurface, IOSurfaceRef destSurface, CFDictionaryRef dict, void *unknown);


/*
 src 输入数据
 dest 输出数据
 srcW 输入图像的宽
 srcH 输入图像的高
 x0 截取图像左上角的x坐标
 y0 截取图像左上角的y坐标
 x1 截取图像右上角的x坐标
 y1 截取图像右上角的y坐标
 
 函数里面没有边界的判断，请在传入x0 x1 在0 到 srcW - 1 的范围
 函数里面没有边界的判断，请在传入y0 y1 在0 到 srcH - 1 的范围
 */
int cutImageResult(unsigned char * src, unsigned char * desData, int srcW, int srcH, int x0, int y0, int x1, int y1, int channel)
{
    
    int destW = x1 - x0 + 1;
    int i = 0;
    int destIdy = 0;
    
    for (i = y0; i <= y1; i++)
    {
        destIdy = i - y0;
        memcpy(&(desData[destIdy * destW * channel]), &(src[(i * srcW + x0) * channel]),sizeof(char) * channel * destW);
    }
    
    return 0;
}


#pragma mark - 屏幕截图数据流
CVPixelBufferRef YKScreenShotBuffer(int type) {
    
    CVPixelBufferRef pixel_buffer = NULL;
    @autoreleasepool {
        
        CoreSurfaceBufferRef screenSurface = NULL;
        
        // 获取 createScreenIOSurface 方法的函数指针
        void* (*createScreenIOSurface)(id,SEL) = (void*(*)(id,SEL))objc_msgSend;
        
        // 获取 UIWindow 类
        Class UIWindowclass = objc_getClass("UIWindow");
        
        // 调用 UIWindow 的 createScreenIOSurface 方法来获取全屏幕的 IOSurface
        screenSurface = createScreenIOSurface(UIWindowclass, @selector(createScreenIOSurface));
        
        // 如果成功获取到屏幕 Surface
        if (screenSurface)
        {
            if (type == 1)
            {
                uint32_t aseed;
                IOSurfaceLock((IOSurfaceRef)screenSurface, kIOSurfaceLockReadOnly, &aseed);
                // 🚀 直接用原始 IOSurface 创建 PixelBuffer (零拷贝)
                NSDictionary *options = @{ (__bridge NSString*)kCVPixelBufferIOSurfacePropertiesKey: @{} };
                CVReturn ret = CVPixelBufferCreateWithIOSurface(kCFAllocatorDefault,
                                                                (IOSurfaceRef)screenSurface,
                                                                (__bridge CFDictionaryRef)options,
                                                                &pixel_buffer);
                if (ret != kCVReturnSuccess) {
                    LOGI(@"CVPixelBufferCreateWithIOSurface failed: %d", ret);
                }
                
                IOSurfaceUnlock((IOSurfaceRef)screenSurface, kIOSurfaceLockReadOnly, &aseed);
                CFRelease(screenSurface);
                
            } else {
                
                uint32_t aseed;
                // 锁定 IOSurface 以便读取数据
                IOSurfaceLock((IOSurfaceRef)screenSurface, 0x00000001, &aseed);
                
                // 获取屏幕的宽度和高度
                int width = (int)IOSurfaceGetWidth((IOSurfaceRef)screenSurface);
                int height = (int)IOSurfaceGetHeight((IOSurfaceRef)screenSurface);
                
                
                
                // 创建字典以设置 IOSurface 的属性
                CFMutableDictionaryRef dict;
                int bPE = 4; // 每个元素的字节数
                size_t pitch = width*bPE; // 每行的字节数
                size_t size = width*height*bPE; // 总字节数
                char pixelFormat[4] = {'A', 'R', 'G', 'B'};
                dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
                
                // 设置 IOSurface 的属性
                //作用: 这个属性用于标识 IOSurface 是否是全局的。如果设置为 kCFBooleanTrue，表示这个 IOSurface 是全局的，可以被多个进程访问。
                CFDictionarySetValue(dict, kIOSurfaceIsGlobal, kCFBooleanTrue);
                CFDictionarySetValue(dict, kIOSurfaceBytesPerRow, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pitch));
                CFDictionarySetValue(dict, kIOSurfaceBytesPerElement, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bPE));
                CFDictionarySetValue(dict, kIOSurfaceWidth, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &width));
                CFDictionarySetValue(dict, kIOSurfaceHeight, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &height));
                CFDictionarySetValue(dict, kIOSurfacePixelFormat, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, pixelFormat));
                CFDictionarySetValue(dict, kIOSurfaceAllocSize, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &size));
                
                // 创建目标 IOSurface
                IOSurfaceRef destSurf = IOSurfaceCreate(dict);
                
                // ---- 用 Accelerator 拷贝 ----
                IOSurfaceAcceleratorRef outAcc;
                IOSurfaceAcceleratorCreate(NULL, 0, &outAcc);
                IOSurfaceAcceleratorTransferSurface(outAcc,
                                                    (IOSurfaceRef)screenSurface,
                                                    destSurf,
                                                    dict, NULL);
                CFRelease(outAcc);
                
                
                // ---- 直接用 IOSurface 包装成 CVPixelBuffer（零拷贝，不要 memcpy）----
                NSDictionary *options = @{ (__bridge NSString*)kCVPixelBufferIOSurfacePropertiesKey: @{} };
                CVReturn ret = CVPixelBufferCreateWithIOSurface(kCFAllocatorDefault,
                                                                destSurf,
                                                                (__bridge CFDictionaryRef)options,
                                                                &pixel_buffer);
                
                IOSurfaceUnlock((IOSurfaceRef)screenSurface, kIOSurfaceLockReadOnly, &aseed);
                
                // 清理
                CFRelease(destSurf);
                CFRelease(dict);
                CFRelease(screenSurface);
            }
        }
    }
    return pixel_buffer;
}

#pragma mark - 将指定区域的屏幕像素数据拷贝到内存中
void YKSCImageDirectToBuffer(int x, int y, int w, int h,  Byte *buffer, size_t bufferLen)
{
    @autoreleasepool {
        
        static BOOL deviceDetect = NO;
        static BOOL isIpad = NO;
        if (deviceDetect == NO) {
            NSString *deviceType = [UIDevice currentDevice].model;
            if ([deviceType isEqualToString:@"iPad"]) {
                isIpad = YES;
            }
            deviceDetect = YES;
        }
        
        CoreSurfaceBufferRef screenSurface = NULL;
        
        // 获取 createScreenIOSurface 方法的函数指针
        void* (*createScreenIOSurface)(id,SEL) = (void*(*)(id,SEL))objc_msgSend;
        
        // 获取 UIWindow 类
        Class UIWindowclass = objc_getClass("UIWindow");
        
        // 调用 UIWindow 的 createScreenIOSurface 方法来获取全屏幕的 IOSurface
        screenSurface = createScreenIOSurface(UIWindowclass, @selector(createScreenIOSurface));
        
        // 如果成功获取到屏幕 Surface
        if (screenSurface)
        {
            uint32_t aseed;
            // 锁定 IOSurface 以便读取数据
            IOSurfaceLock((IOSurfaceRef)screenSurface, 0x00000001, &aseed);
            
            // 获取屏幕的宽度和高度
            int width = (int)IOSurfaceGetWidth((IOSurfaceRef)screenSurface);
            int height = (int)IOSurfaceGetHeight((IOSurfaceRef)screenSurface);
            
            // 创建字典以设置 IOSurface 的属性
            CFMutableDictionaryRef dict;
            size_t pitch = width*4; // 每行的字节数
            size_t size = width*height*4; // 总字节数
            int bPE = 4; // 每个元素的字节数
            char pixelFormat[4] = {'A', 'R', 'G', 'B'};
            dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
            
            // 设置 IOSurface 的属性
            /*作用: 这个属性用于标识 IOSurface 是否是全局的。如果设置为 kCFBooleanTrue，表示这个 IOSurface 是全局的，可以被多个进程访问。如果不加就有问题。
             CFDictionarySetValue(dict, kIOSurfaceIsGlobal, kCFBooleanTrue);
             */
            CFDictionarySetValue(dict, kIOSurfaceIsGlobal, kCFBooleanTrue);
            CFDictionarySetValue(dict, kIOSurfaceBytesPerRow, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pitch));
            CFDictionarySetValue(dict, kIOSurfaceBytesPerElement, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &bPE));
            CFDictionarySetValue(dict, kIOSurfaceWidth, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &width));
            CFDictionarySetValue(dict, kIOSurfaceHeight, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &height));
            CFDictionarySetValue(dict, kIOSurfacePixelFormat, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, pixelFormat));
            CFDictionarySetValue(dict, kIOSurfaceAllocSize, CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &size));
            
            // 创建目标 IOSurface
            IOSurfaceRef destSurf = IOSurfaceCreate(dict);
            
            // 创建目标 IOSurface
            IOSurfaceAcceleratorRef outAcc;
            IOSurfaceAcceleratorCreate(NULL, 0, &outAcc);
            
            // 转移源 IOSurface 到目标 IOSurface
            IOSurfaceAcceleratorTransferSurface(outAcc, (IOSurfaceRef)screenSurface, destSurf, dict,NULL);
            
            // 释放 IOSurfaceAccelerator 实例
            CFRelease(outAcc);
            
            // 获取目标 IOSurface 的基础地址
            Byte* pix_data = IOSurfaceGetBaseAddress(destSurf);
            if(isIpad)
            {
                for(int i = 0; i < bufferLen; i = i+4){
                    Byte tmp = pix_data[i];
                    pix_data[i] = pix_data[i+2];
                    pix_data[i+2] = tmp;
                }
            }
            // 根据给定的 x, y, w, h 参数决定是否需要复制图像的所有区域
            if((x == 0 && y == 0 && w == 0 && h == 0)  || (x==0 && y == 0 && w == width && h == height)) {
                // 复制整个图像到缓冲区
                memcpy(buffer, pix_data, size);
            } else {
                int x0 = (x < width) ? x : width - 1;
                int y0 = (y < height) ? y : height - 1;
                int x1 = ((x0 + w) < width) ? x0 + w - 1 : width - 1;
                int y1 = ((y0 + h) < height) ? y0 + h - 1 : height - 1;
                cutImageResult(pix_data, buffer,  width, height, x0, y0, x1, y1, bPE);
                
            }
            // 解锁目标 IOSurface
            IOSurfaceUnlock(destSurf, kIOSurfaceLockReadOnly, &aseed);
            
            // 释放目标 IOSurface 和其他资源
            CFRelease(destSurf);
            CFRelease(screenSurface);
            CFRelease(dict);
        }
        else
        {
            LOGI(@"screenSurface = NULL");
        }
    }
}



#pragma mark - 截图屏幕并且输出的是数据流
NSData *YKScreenShotMjpeg(UIInterfaceOrientation orientation, CGFloat compressionQuality, CGSize targetSize)
{
    @autoreleasepool {
        
        CVPixelBufferRef pixelBuffer = YKScreenShotBuffer(2);
                
        if (pixelBuffer != NULL) {
            
            // 使用静态单例来缓存 CIContext
            static CIContext *sharedContext = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sharedContext = [CIContext contextWithOptions:nil];
            });
            
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
            
            // 如果系数默认为-1
            CGFloat scaleFactor = 1;
            // 获取原始图像的宽高
            CGFloat width = (CGFloat)CVPixelBufferGetWidth(pixelBuffer);
            CGSize newSize = targetSize;
            
            if (newSize.width == width) {
                scaleFactor = 1;//代表不需要计算宽高比例直接返回原始的
            } else {
                scaleFactor = newSize.width / width;
            }
            
            
            // 如果系数等于1,并且方向等于竖屏,直接返回
            if (scaleFactor == 1 && orientation == UIInterfaceOrientationPortrait) {
                
                CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
                CGImageRef cgImage = [sharedContext createCGImage:ciImage fromRect:[ciImage extent]];
                UIImage *finalImage = [UIImage imageWithCGImage:cgImage];
                CGImageRelease(cgImage);
                NSData *data = UIImageJPEGRepresentation(finalImage, compressionQuality);
                CVPixelBufferRelease(pixelBuffer);
                return data;
            }
            
            
            // 应用缩放
            CIImage *scaledCIImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeScale(scaleFactor, scaleFactor)];
            
            
            // 旋转图像，计算旋转后的图像大小
            CGAffineTransform rotationTransform = CGAffineTransformIdentity;
            if (orientation == UIInterfaceOrientationLandscapeLeft) {
                rotationTransform = CGAffineTransformRotate(rotationTransform, -M_PI_2);
            } else if (orientation == UIInterfaceOrientationLandscapeRight) {
                rotationTransform = CGAffineTransformRotate(rotationTransform, M_PI_2);
            } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
                rotationTransform = CGAffineTransformRotate(rotationTransform, M_PI);
            }
            

            // 获取旋转后的图像边界
            CGRect rotatedBounds = CGRectApplyAffineTransform(CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer) * scaleFactor, CVPixelBufferGetHeight(pixelBuffer) * scaleFactor), rotationTransform);
            
            // 使用旋转后的边界创建新的 CIImage
            CIImage *rotatedCIImage = [scaledCIImage imageByApplyingTransform:rotationTransform];
            
            // 创建 CGImage
            CGImageRef videoImage = [sharedContext createCGImage:rotatedCIImage fromRect:rotatedBounds];
            
            
            // 转换为 UIImage
            UIImage *finalImage = [UIImage imageWithCGImage:videoImage];
            CGImageRelease(videoImage);
            
            // 压缩为 JPEG 数据
            NSData *compressedData = UIImageJPEGRepresentation(finalImage, MAX(0.9, compressionQuality));
            
            CVPixelBufferRelease(pixelBuffer);

            return compressedData;
        }
        
        return nil;
    }
}



#pragma mark - 屏幕截图Base64
NSString *YKScreenShotBase64(UIInterfaceOrientation orientation)
{
    @autoreleasepool {
        
        CVPixelBufferRef pixelBuffer = YKScreenShotBuffer(2);
        if (pixelBuffer != NULL)
        {
            // 使用静态单例来缓存 CIContext
            static CIContext *sharedContext = nil;
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                sharedContext = [CIContext contextWithOptions:nil];
            });
            
            CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
            
            // 应用缩放
            CGFloat scale = 1.0;
            CIImage *scaledCIImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
            
            // 旋转图像，计算旋转后的图像大小
            CGAffineTransform rotationTransform = CGAffineTransformIdentity;
            if (orientation == UIInterfaceOrientationLandscapeLeft) {
                rotationTransform = CGAffineTransformRotate(rotationTransform, -M_PI_2);
            } else if (orientation == UIInterfaceOrientationLandscapeRight) {
                rotationTransform = CGAffineTransformRotate(rotationTransform, M_PI_2);
            } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
                rotationTransform = CGAffineTransformRotate(rotationTransform, M_PI);
            }
            
            // 获取旋转后的图像边界
            CGRect rotatedBounds = CGRectApplyAffineTransform(CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer) * scale, CVPixelBufferGetHeight(pixelBuffer) * scale), rotationTransform);
            
            // 使用旋转后的边界创建新的 CIImage
            CIImage *rotatedCIImage = [scaledCIImage imageByApplyingTransform:rotationTransform];
            
            // 创建 CGImage
            CGImageRef videoImage = [sharedContext createCGImage:rotatedCIImage fromRect:rotatedBounds];
            
            // 转换为 UIImage
            UIImage *finalImage = [UIImage imageWithCGImage:videoImage];
            CGImageRelease(videoImage);
            
            // 压缩为 JPEG 数据
            NSData *data = UIImageJPEGRepresentation(finalImage, 1.0);
            NSString *base64String = [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
            CVPixelBufferRelease(pixelBuffer);
            
            return base64String;
        }
        
        return nil;
    }
}


#pragma mark - 屏幕截图带方向PixelBuffer
CVPixelBufferRef YKScreenShotRotatedPixelBuffer(UIInterfaceOrientation orientation)
{
    @autoreleasepool {
        
        // 获取屏幕截图的像素缓存
        CVPixelBufferRef pixelBuffer = YKScreenShotBuffer(1);
        if (!pixelBuffer) {
            LOGI(@"获取屏幕截图失败");
            return pixelBuffer;
        }
        
        // 如果方向是竖屏，直接返回原始像素缓存
        if (orientation == UIInterfaceOrientationPortrait) {
            return pixelBuffer;
        }
        
        // 使用静态单例缓存 CIContext（GPU 渲染）
        static CIContext *sharedContext = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedContext = [CIContext contextWithOptions:@{
                kCIContextUseSoftwareRenderer: @NO
            }];
        });
        
        // 原始图像
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        
        // 使用静态变量缓存 pixelFormat
        static OSType cachedPixelFormat = 0;  // 初始值为 0，表示未缓存
        // 如果 pixelFormat 未缓存，获取并缓存一次
        if (cachedPixelFormat == 0) {
            cachedPixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
        }
        
        
        // 旋转矩阵
        CGAffineTransform rotation = CGAffineTransformIdentity;
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            rotation = CGAffineTransformMakeRotation(-M_PI_2);
        } else if (orientation == UIInterfaceOrientationLandscapeRight) {
            rotation = CGAffineTransformMakeRotation(M_PI_2);
        } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            rotation = CGAffineTransformMakeRotation(M_PI);
        }
        
        // 旋转图像
        CIImage *rotated = [ciImage imageByApplyingTransform:rotation];
        
        // 获取旋转后的真实边界
        CGRect extent = rotated.extent;
        CGRect intExtent = CGRectIntegral(extent);
        
        // 如果旋转后坐标不在 (0,0)，则需要平移补偿
        if (intExtent.origin.x != 0.0 || intExtent.origin.y != 0.0) {
            CGAffineTransform translate = CGAffineTransformMakeTranslation(-intExtent.origin.x, -intExtent.origin.y);
            rotated = [rotated imageByApplyingTransform:translate];
            intExtent = CGRectIntegral(rotated.extent);
        }
        
        size_t newWidth = (size_t)llround(CGRectGetWidth(intExtent));
        size_t newHeight = (size_t)llround(CGRectGetHeight(intExtent));
        
        
        // 创建新的 CVPixelBuffer（GPU 可兼容）
        CVPixelBufferRef newPixelBuffer = NULL;
        NSDictionary *options = @{
            (id)kCVPixelBufferCGImageCompatibilityKey: @YES,
            (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
            (id)kCVPixelBufferIOSurfacePropertiesKey: @{}
        };
        
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                              newWidth,
                                              newHeight,
                                              cachedPixelFormat,
                                              (__bridge CFDictionaryRef)options,
                                              &newPixelBuffer);
        
        if (status != kCVReturnSuccess || !newPixelBuffer) {
            LOGI(@"创建新的 PixelBuffer 失败: %d", status);
            CVPixelBufferRelease(pixelBuffer);
            return newPixelBuffer;
        }
        
        // GPU 渲染旋转后的图像到新 buffer
        [sharedContext render:rotated toCVPixelBuffer:newPixelBuffer];
        
        // 清理
        CVPixelBufferRelease(pixelBuffer);
        return newPixelBuffer;
    }
}


#pragma mark - 屏幕截图带方向PixelBuffer
//CVPixelBufferRef YKCreateResizedRotatedPixelBuffer(UIInterfaceOrientation orientation, CGSize targetSize)
//{
//    @autoreleasepool {
//        
//        // 获取屏幕截图的像素缓存
//        CVPixelBufferRef pixelBuffer = YKScreenShotBuffer(1);
//        if (!pixelBuffer) {
//            return pixelBuffer;
//        }
//        
//        // 使用静态变量缓存 pixelFormat
//        static OSType cachedPixelFormat = 0;  // 初始值为 0，表示未缓存
//        
//        // 如果 pixelFormat 未缓存，获取并缓存一次
//        if (cachedPixelFormat == 0) {
//            cachedPixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
//        }
//        
//        // 如果系数默认为-1
//        CGFloat scaleFactor = 1;
//        // 获取原始图像的宽高
//        CGFloat width = (CGFloat)CVPixelBufferGetWidth(pixelBuffer);
//        CGSize newSize = targetSize;
//        
//        if (newSize.width == width) {
//            scaleFactor = 1;//代表不需要计算宽高比例直接返回原始的
//        } else {
//            scaleFactor = newSize.width / width;
//        }
//        
//        
//        // 如果系数等于1,并且方向等于竖屏,直接返回
//        if (scaleFactor == 1 && orientation == UIInterfaceOrientationPortrait) {
//            return pixelBuffer;  // 不做任何处理，直接返回原图
//        }
//        
//        
//        // 使用静态单例缓存 CIContext（GPU 渲染）
//        static CIContext *sharedContext = nil;
//        static dispatch_once_t onceToken;
//        dispatch_once(&onceToken, ^{
//            sharedContext = [CIContext contextWithOptions:@{
//                kCIContextUseSoftwareRenderer: @NO
//            }];
//        });
//        
//        // 获取原始图像
//        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
//        
//        // 创建缩放的变换
//        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
//        
//        // 创建旋转的变换矩阵
//        CGAffineTransform rotation = CGAffineTransformIdentity;
//        switch (orientation) {
//            case UIInterfaceOrientationLandscapeLeft:
//                rotation = CGAffineTransformMakeRotation(-M_PI_2);
//                break;
//            case UIInterfaceOrientationLandscapeRight:
//                rotation = CGAffineTransformMakeRotation(M_PI_2);
//                break;
//            case UIInterfaceOrientationPortraitUpsideDown:
//                rotation = CGAffineTransformMakeRotation(M_PI);
//                break;
//            default:
//                break;
//        }
//        
//        // 合并缩放与旋转变换
//        CGAffineTransform combinedTransform = CGAffineTransformConcat(scaleTransform, rotation);
//        
//        // 应用变换
//        CIImage *transformedImage = [ciImage imageByApplyingTransform:combinedTransform];
//        
//        // 获取变换后图像的边界
//        CGRect extent = transformedImage.extent;
//        CGRect intExtent = CGRectIntegral(extent);
//        
//        // 如果旋转后坐标不在 (0,0)，则需要平移补偿
//        if (intExtent.origin.x != 0.0 || intExtent.origin.y != 0.0) {
//            CGAffineTransform translate = CGAffineTransformMakeTranslation(-intExtent.origin.x, -intExtent.origin.y);
//            transformedImage = [transformedImage imageByApplyingTransform:translate];
//            intExtent = CGRectIntegral(transformedImage.extent);
//        }
//        
//        size_t finalWidth = (size_t)llround(CGRectGetWidth(intExtent));
//        size_t finalHeight = (size_t)llround(CGRectGetHeight(intExtent));
//        
//        
//        // 创建新的 CVPixelBuffer（GPU 可兼容）
//        CVPixelBufferRef newPixelBuffer = NULL;
//        NSDictionary *options = @{
//            (id)kCVPixelBufferCGImageCompatibilityKey: @YES,
//            (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
//            (id)kCVPixelBufferIOSurfacePropertiesKey: @{}
//        };
//        
//        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
//                                              finalWidth,
//                                              finalHeight,
//                                              cachedPixelFormat, // 使用缓存的 pixelFormat
//                                              (__bridge CFDictionaryRef)options,
//                                              &newPixelBuffer);
//        
//        if (status != kCVReturnSuccess || !newPixelBuffer) {
//            CVPixelBufferRelease(pixelBuffer);
//            return newPixelBuffer;
//        }
//        
//        // 使用 GPU 渲染旋转后的图像到新 buffer
//        [sharedContext render:transformedImage toCVPixelBuffer:newPixelBuffer];
//        
//        // 清理原始缓存
//        CVPixelBufferRelease(pixelBuffer);
//        return newPixelBuffer;
//    }
//}


#pragma mark - 屏幕截图带方向PixelBuffer (智能平滑版)
CVPixelBufferRef YKCreateResizedRotatedPixelBuffer(UIInterfaceOrientation orientation, CGSize targetSize)
{
    @autoreleasepool {
        // 1. 获取屏幕截图
        CVPixelBufferRef pixelBuffer = YKScreenShotBuffer(1);
        if (!pixelBuffer) return pixelBuffer;
        
        static OSType cachedPixelFormat = 0;
        if (cachedPixelFormat == 0) {
            cachedPixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
        }
        
        CGFloat width = (CGFloat)CVPixelBufferGetWidth(pixelBuffer);
        CGFloat scaleFactor = targetSize.width / width;
        
        // 快速返回：竖屏且不需要缩放
        if (fabs(scaleFactor - 1.0) < 0.01 && orientation == UIInterfaceOrientationPortrait) {
            return pixelBuffer;
        }
        
        static CIContext *sharedContext = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            sharedContext = [CIContext contextWithOptions:@{
                kCIContextUseSoftwareRenderer: @NO,
                kCIContextWorkingColorSpace: [NSNull null] // 高性能模式
            }];
        });
        
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        CIImage *processedImage = nil;

        // --- 逻辑分支：缩放比例小于 0.7 使用高质量滤镜，否则使用原代码逻辑 ---
        if (scaleFactor < 0.7) {
            // 使用 CILanczosScaleTransform 实现类似 Area Downsampling 的平滑效果
            // 这在缩小到 70% 以下时能有效消除锯齿
            CIFilter *filter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
            [filter setValue:ciImage forKey:kCIInputImageKey];
            [filter setValue:@(scaleFactor) forKey:kCIInputScaleKey];
            [filter setValue:@(1.0) forKey:kCIInputAspectRatioKey];
            processedImage = filter.outputImage;
            
            // 此时已缩放，接下来的变换只处理旋转
            CGAffineTransform rotation = CGAffineTransformIdentity;
            switch (orientation) {
                case UIInterfaceOrientationLandscapeLeft:      rotation = CGAffineTransformMakeRotation(-M_PI_2); break;
                case UIInterfaceOrientationLandscapeRight:     rotation = CGAffineTransformMakeRotation(M_PI_2); break;
                case UIInterfaceOrientationPortraitUpsideDown: rotation = CGAffineTransformMakeRotation(M_PI); break;
                default: break;
            }
            if (!CGAffineTransformIsIdentity(rotation)) {
                processedImage = [processedImage imageByApplyingTransform:rotation];
            }
        } else {
            // --- 原有高性能代码逻辑 ---
            CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scaleFactor, scaleFactor);
            CGAffineTransform rotation = CGAffineTransformIdentity;
            switch (orientation) {
                case UIInterfaceOrientationLandscapeLeft:      rotation = CGAffineTransformMakeRotation(-M_PI_2); break;
                case UIInterfaceOrientationLandscapeRight:     rotation = CGAffineTransformMakeRotation(M_PI_2); break;
                case UIInterfaceOrientationPortraitUpsideDown: rotation = CGAffineTransformMakeRotation(M_PI); break;
                default: break;
            }
            CGAffineTransform combinedTransform = CGAffineTransformConcat(scaleTransform, rotation);
            processedImage = [ciImage imageByApplyingTransform:combinedTransform];
        }
        
        // 2. 修正坐标偏移
        CGRect extent = processedImage.extent;
        if (extent.origin.x != 0.0 || extent.origin.y != 0.0) {
            processedImage = [processedImage imageByApplyingTransform:CGAffineTransformMakeTranslation(-extent.origin.x, -extent.origin.y)];
            extent = processedImage.extent;
        }
        
        size_t finalWidth = (size_t)llround(CGRectGetWidth(extent));
        size_t finalHeight = (size_t)llround(CGRectGetHeight(extent));
        
        // 3. 创建 PixelBuffer
        CVPixelBufferRef newPixelBuffer = NULL;
        NSDictionary *options = @{
            (id)kCVPixelBufferCGImageCompatibilityKey: @YES,
            (id)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES,
            (id)kCVPixelBufferIOSurfacePropertiesKey: @{}
        };
        
        CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                              finalWidth,
                                              finalHeight,
                                              cachedPixelFormat,
                                              (__bridge CFDictionaryRef)options,
                                              &newPixelBuffer);
        
        if (status != kCVReturnSuccess || !newPixelBuffer) {
            CVPixelBufferRelease(pixelBuffer);
            return newPixelBuffer;
        }
        
        // 4. 渲染
        [sharedContext render:processedImage toCVPixelBuffer:newPixelBuffer bounds:processedImage.extent colorSpace:nil];
        
        CVPixelBufferRelease(pixelBuffer);
        return newPixelBuffer;
    }
}

#pragma mark - 计算缩放后的大小
CGSize YKCalculateScaledSizeForWidth(CGSize targetSize)
{
    CGFloat maxWidth = 1080.0;  // 最大宽度
    CGFloat maxHeight = 1920.0; // 最大高度
    
    // 计算宽高比
    CGFloat aspectRatio = targetSize.width / targetSize.height;
    
    // 如果宽度超过最大宽度
    if (targetSize.width > maxWidth) {
        // 根据最大宽度缩放
        CGFloat scaledWidth = maxWidth;
        CGFloat scaledHeight = scaledWidth / aspectRatio;
        
        // 如果缩放后的高度超过最大高度
        if (scaledHeight > maxHeight) {
            // 使用最大高度来缩放
            scaledHeight = maxHeight;
            scaledWidth = scaledHeight * aspectRatio;
        }
        
        return CGSizeMake(scaledWidth, scaledHeight);
    }
    // 如果高度超过最大高度
    else if (targetSize.height > maxHeight) {
        
        // 根据最大高度缩放
        CGFloat scaledHeight = maxHeight;
        CGFloat scaledWidth = scaledHeight * aspectRatio;
        
        return CGSizeMake(scaledWidth, scaledHeight);
    }
    
    // 如果都没有超过最大宽度和最大高度，返回原始尺寸
    return targetSize;
}


#pragma mark - 强制跳过
void YKForceNextFrameUpdate(void) {
    sLastDirtyFrame = 0;
}

@implementation YKServiceIOSurface

@end
#pragma clang diagnostic pop
