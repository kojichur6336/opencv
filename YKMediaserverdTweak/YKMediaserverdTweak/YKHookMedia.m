//
//  YKHookMedia.m
//  Created on 2025/11/5
//  Description <#文件描述#>
//  PD <#产品文档地址#>
//  Design <#设计文档地址#>
//  Copyright © 2025 YKKJ. All rights reserved.
//  @author 刘小彬(liuxiaomike@gmail.com)
//


#import <dlfcn.h>
#import <os/lock.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <CoreMedia/CoreMedia.h>
#import <VideoToolbox/VideoToolbox.h>
#import <AudioToolbox/AudioToolbox.h>


static OSStatus (*AudioUnitRender_Orig_YK)(AudioUnit, AudioUnitRenderActionFlags *, const AudioTimeStamp *, UInt32, UInt32, AudioBufferList *);
#pragma mark - Hook 函数实现
OSStatus AudioUnitRender_Hook_YK(AudioUnit unit,
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp,
                                 UInt32 inOutputBusNumber,
                                 UInt32 inNumberFrames,
                                 AudioBufferList *ioData)
{
    OSStatus result = AudioUnitRender_Orig_YK(unit, ioActionFlags, inTimeStamp, inOutputBusNumber, inNumberFrames, ioData);
    if (result != noErr || ioData == NULL) return result;
    return result;
}

#pragma mark - 初始化构造器
__attribute__((__constructor__)) static void YKMediaserverdInitialize(void)
{
    
}
