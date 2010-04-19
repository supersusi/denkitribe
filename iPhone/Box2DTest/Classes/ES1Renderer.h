#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@interface ES1Renderer : NSObject {
@private
  EAGLContext *context;
  GLint backingWidth;
  GLint backingHeight;
  GLuint defaultFramebuffer, colorRenderbuffer;
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;
- (void)setupPhysics;
- (void)updateTime:(float)time gravityX:(float)gravx gravityY:(float)gravy;
- (void)beginTouch:(CGPoint)point;
- (void)render;

@end
