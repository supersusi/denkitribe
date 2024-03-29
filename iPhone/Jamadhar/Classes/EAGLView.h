#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "Renderer.h"

@interface EAGLView : UIView {    
@private
    Renderer *renderer;
    BOOL animating;
    NSInteger animationFrameInterval;
    id displayLink;
}

@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;

- (void)startAnimation;
- (void)stopAnimation;
- (void)drawView:(id)sender;

@end
