#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Renderer.h"

@interface EAGLView : UIView <UIAccelerometerDelegate> {    
@private
  Renderer *renderer;
  BOOL animating;
  id displayLink;
  float touchIntensity[2];
  float accelIntensity[3];
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView:(id)sender;
- (void)processTouch:(UITouch *)touch press:(BOOL)press;

@end
