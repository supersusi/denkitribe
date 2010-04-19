#import "EAGLView.h"

@implementation EAGLView

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder {
  self = [super initWithCoder:coder];
  if (self) {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = TRUE;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:FALSE],
                                     kEAGLDrawablePropertyRetainedBacking,
                                     kEAGLColorFormatRGBA8,
                                     kEAGLDrawablePropertyColorFormat, nil];
    
    gameState = [[GameState alloc] init];
    if (!gameState) {
      [self release];
      return nil;
    }
    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0];
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];
    
    animating = FALSE;
    displayLink = nil;
    frameStartTime = CFAbsoluteTimeGetCurrent();
    accelX = accelY = 0;
  }
  return self;
}

- (void)drawView:(id)sender {
  [gameState render];
  CFTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
  [gameState updateTime:(currentTime - frameStartTime) gravityX:accelX gravityY:accelY];
  frameStartTime = currentTime;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    [gameState beginTouch:[touch locationInView:self]];
  }
}

- (void)accelerometer:(UIAccelerometer *)accelerometer
        didAccelerate:(UIAcceleration *)acceleration {
  accelX = acceleration.x;
  accelY = acceleration.y;
}

- (void)layoutSubviews {
  [gameState resizeFromLayer:(CAEAGLLayer*)self.layer];
  [self drawView:nil];
}

- (void)startAnimation {
  if (!animating) {
    displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
    [displayLink setFrameInterval:1];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    animating = TRUE;
  }
}

- (void)stopAnimation {
  if (animating) {
    [displayLink invalidate];
    displayLink = nil;
    animating = FALSE;
  }
}

- (void)dealloc {
  [gameState release];
  [super dealloc];
}

@end
