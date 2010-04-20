#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

@class GameState;

@interface EAGLView : UIView <UIAccelerometerDelegate>
{    
@private
  GameState *gameState;
  BOOL animating;
  id displayLink;
  CFTimeInterval frameStartTime;
  float accelX;
  float accelY;
  EAGLContext *context;
  GLint backingWidth;
  GLint backingHeight;
  GLuint defaultFramebuffer, colorRenderbuffer;
}

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView:(id)sender;

@end
