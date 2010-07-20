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
  }
  return self;
}

- (void)drawView:(id)sender {
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

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
  for (UITouch *touch in touches) {
    NSString* path = [NSString stringWithFormat:@"/1/touch/%d", touchCount];
    Jamadhar::OscClient::SendMessage([path UTF8String], 1.0f);
    touchCount++;
  }
  GLfloat color = touchCount * 0.3f;
  [renderer setClearColorRed:color green:color blue:color];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  for (UITouch *touch in touches) {
    touchCount--;
    NSString* path = [NSString stringWithFormat:@"/1/touch/%d", touchCount];
    Jamadhar::OscClient::SendMessage([path UTF8String], 0.0f);
  }
  GLfloat color = touchCount * 0.3f;
  [renderer setClearColorRed:color green:color blue:color];
}

- (void)accelerometer:(UIAccelerometer*)accelerometer
        didAccelerate:(UIAcceleration*)acceleration {
  Jamadhar::OscClient::SendMessage("/1/accel/x", acceleration.x);
  Jamadhar::OscClient::SendMessage("/1/accel/y", acceleration.y);
  Jamadhar::OscClient::SendMessage("/1/accel/z", acceleration.z);
}

- (void)dealloc {
  [renderer release];
  [super dealloc];
}

@end
