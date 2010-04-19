#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "ES1Renderer.h"

@interface EAGLView : UIView <UIAccelerometerDelegate>
{    
@private
  ES1Renderer *renderer;
  BOOL animating;
  id displayLink;
  CFTimeInterval frameStartTime;
  float accelX;
  float accelY;
}

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView:(id)sender;

@end
