//
//  ESRenderer.h
//  Box2DTest
//
//  Created by 高橋 啓治郎 on 10/04/19.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

@protocol ESRenderer <NSObject>

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
- (void)beginTouch:(CGPoint)point;

@end
