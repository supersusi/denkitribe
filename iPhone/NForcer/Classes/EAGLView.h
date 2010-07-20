#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Renderer.h"

@interface EAGLView : UIView <UIAccelerometerDelegate> {    
@private
  Renderer *renderer;
  BOOL animating;
  id displayLink;
  NSInteger touchCount;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView:(id)sender;

@end
