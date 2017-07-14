/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <QuartzCore/QuartzCore.h>

#import <ReactABI19_0_0/ABI19_0_0RCTConvert.h>

#import "ABI19_0_0ARTBrush.h"
#import "ABI19_0_0ARTCGFloatArray.h"
#import "ABI19_0_0ARTTextFrame.h"

@interface ABI19_0_0RCTConvert (ABI19_0_0ART)

+ (CGPathRef)CGPath:(id)json;
+ (CTTextAlignment)CTTextAlignment:(id)json;
+ (ABI19_0_0ARTTextFrame)ABI19_0_0ARTTextFrame:(id)json;
+ (ABI19_0_0ARTCGFloatArray)ABI19_0_0ARTCGFloatArray:(id)json;
+ (ABI19_0_0ARTBrush *)ABI19_0_0ARTBrush:(id)json;

+ (CGPoint)CGPoint:(id)json offset:(NSUInteger)offset;
+ (CGRect)CGRect:(id)json offset:(NSUInteger)offset;
+ (CGColorRef)CGColor:(id)json offset:(NSUInteger)offset;
+ (CGGradientRef)CGGradient:(id)json offset:(NSUInteger)offset;

@end
