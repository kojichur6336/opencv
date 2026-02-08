//
//  YKServiceIOSurface.h
//  YKService
//
//  Created by liuxiaobin on 2025/11/5.
//

#import <UIKit/UIKit.h>
#import <VideoToolbox/VideoToolbox.h>

NS_ASSUME_NONNULL_BEGIN


/// 视频流
CVPixelBufferRef YKScreenShotBuffer(int type);


/// 将指定区域的屏幕像素数据拷贝到内存中
/// - Parameters:
///   - x: 截取区域的起始横坐标
///   - y: 截取区域的起始纵坐标
///   - w: 截取区域的宽度
///   - h: 截取区域的高度
///   - buffer: 用于存储像素数据的目标缓冲区指针
///   - bufferLen: 长度（以字节为单位)
void YKSCImageDirectToBuffer(int x, int y, int w, int h,  Byte *buffer, size_t bufferLen);


/// 屏幕截图
/// - Parameters:
///   - orientation: 方向
///   - compressionQuality: 质量
///   - targetSize: 目标大小
NSData * YKScreenShotMjpeg(UIInterfaceOrientation orientation, CGFloat compressionQuality, CGSize targetSize);


/// 截图Base64
/// - Parameter orientation: 方向
NSString *YKScreenShotBase64(UIInterfaceOrientation orientation);


/// 屏幕截图带方向PixelBuffer
/// - Parameter orientation: 方向
CVPixelBufferRef YKScreenShotRotatedPixelBuffer(UIInterfaceOrientation orientation);


/// 创建一个新的像素缓存，带有旋转和缩放功能
/// - Parameter orientation: 方向
/// - Parameter targetSize 目标大小
CVPixelBufferRef YKCreateResizedRotatedPixelBuffer(UIInterfaceOrientation orientation, CGSize targetSize);


/// 设置最大分辨率大小
/// - Parameter targetSize: 目标大小
CGSize YKCalculateScaledSizeForWidth(CGSize targetSize);


/// 强制下一帧一定采集跳过“脏帧计数”判断）
void YKForceNextFrameUpdate(void);




/// MARK - YKServiceIOSurface
@interface YKServiceIOSurface : NSObject

@end

NS_ASSUME_NONNULL_END
