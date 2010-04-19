#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "GameState.h"

@interface EAGLView : UIView <UIAccelerometerDelegate>
{    
@private
  GameState *gameState;
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
