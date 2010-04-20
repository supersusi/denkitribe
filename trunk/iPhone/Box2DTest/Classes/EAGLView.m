#import "EAGLView.h"
#import "GameState.h"

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
    
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    if (!context || ![EAGLContext setCurrentContext:context]) {
      [self release];
      return nil;
    }

    glGenFramebuffersOES(1, &defaultFramebuffer);
    glGenRenderbuffersOES(1, &colorRenderbuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
    
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
  glViewport(0, 0, backingWidth, backingHeight);
  [gameState render];
  [context presentRenderbuffer:GL_RENDERBUFFER_OES];
  CFTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
  [gameState step:(currentTime - frameStartTime) gravityX:accelX gravityY:accelY];
  frameStartTime = currentTime;
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    CGPoint point = [touch locationInView:self];
    [gameState addBox:(point.x / backingWidth - 0.5f) * 20 yCoord:((backingHeight * 0.5f - point.y) / backingWidth) * 20];
  }
}

- (void)accelerometer:(UIAccelerometer *)accelerometer
        didAccelerate:(UIAcceleration *)acceleration {
  accelX = acceleration.x;
  accelY = acceleration.y;
}

- (void)layoutSubviews {
  glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
  [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
  glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
  glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
  if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
    NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
  } else {
    gameState.screenAspect = (float)backingHeight / backingWidth;
    [self drawView:nil];
  }
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
  if (defaultFramebuffer) {
    glDeleteFramebuffersOES(1, &defaultFramebuffer);
    defaultFramebuffer = 0;
  }
  
  if (colorRenderbuffer) {
    glDeleteRenderbuffersOES(1, &colorRenderbuffer);
    colorRenderbuffer = 0;
  }
  
  // Tear down context
  if ([EAGLContext currentContext] == context) {
    [EAGLContext setCurrentContext:nil];
  }
  
  [context release];
  context = nil;
  
  [gameState release];
  [super dealloc];
}

@end
