#import "EAGLView.h"
#import "OscClient.h"

@implementation EAGLView

@synthesize animating;

+ (Class)layerClass {
  return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder {
  if ((self = [super initWithCoder:coder])) {
    CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
    eaglLayer.opaque = TRUE;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:FALSE],
                                    kEAGLDrawablePropertyRetainedBacking,
                                    kEAGLColorFormatRGBA8,
                                    kEAGLDrawablePropertyColorFormat,
                                    nil];

    if (!(renderer = [[Renderer alloc] init])) {
      [self release];
      return nil;
    }

    animating = FALSE;
    displayLink = nil;
    touchIntensity[0] = touchIntensity[1] = 0;
    accelIntensity[0] = accelIntensity[2] = accelIntensity[2] = 0;
  }
  return self;
}

- (void)drawView:(id)sender {
  // クリアカラーの設定
  GLfloat level = (touchIntensity[0] + touchIntensity[1]) * 0.5f;
  GLfloat r = ABS(accelIntensity[0]) * 0.15f + level;
  GLfloat g = ABS(accelIntensity[1]) * 0.15f + level;
  GLfloat b = ABS(accelIntensity[2]) * 0.15f + level;
  [renderer setClearColorRed:r green:g blue:b];
  // レンダリング
  [renderer render];
}

- (void)layoutSubviews {
  [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
  [self drawView:nil];
}

- (void)startAnimation {
  if (!animating) {
    displayLink = [NSClassFromString(@"CADisplayLink")
                   displayLinkWithTarget:self
                   selector:@selector(drawView:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                      forMode:NSDefaultRunLoopMode];

    [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 15)];
    [[UIAccelerometer sharedAccelerometer] setDelegate:self];

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

// タッチ処理
- (void)processTouch:(UITouch *)touch press:(BOOL)press {
  CGPoint pt = [touch locationInView:self];
  NSInteger slot = (pt.x < self.center.x) ? 0 : 1;
  float pitch = MIN(MAX(1.05f - 1.1f * pt.y / self.center.y, 0.0f), 1.0f);
  OscClient::SendTouchMessage(slot, pitch, press);
  touchIntensity[slot] = press ? pitch : 0;
}

// タッチ開始
- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  for (UITouch *touch in touches) {
    [self processTouch:touch press:YES];
  }
}

// タッチ移動
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    [self processTouch:touch press:YES];
  }
}

// タッチ終了
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    [self processTouch:touch press:NO];
  }
}

- (void)accelerometer:(UIAccelerometer*)accelerometer
        didAccelerate:(UIAcceleration*)acceleration {
  OscClient::SendAccelMessage(acceleration.x, acceleration.y, acceleration.z);
  accelIntensity[0] = acceleration.x;
  accelIntensity[1] = acceleration.y;
  accelIntensity[2] = acceleration.z;
}

- (void)dealloc {
  [renderer release];
  [super dealloc];
}

@end
