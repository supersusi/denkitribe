#import "EAGLView.h"
#import "OscClient.h"

@implementation EAGLView

@synthesize animating;
@dynamic animationFrameInterval;

// You must implement this method
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

//The EAGL view is stored in the nib file. When it's unarchived it's sent -initWithCoder:
- (id)initWithCoder:(NSCoder*)coder
{    
    if ((self = [super initWithCoder:coder]))
    {
        // Get the layer
        CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;

        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

        renderer = [[Renderer alloc] init];

        if (!renderer)
        {
            [self release];
            return nil;
        }

        animating = FALSE;
        animationFrameInterval = 1;
        displayLink = nil;
    }

    return self;
}

- (void)drawView:(id)sender
{
    [renderer render];
}

- (void)layoutSubviews
{
    [renderer resizeFromLayer:(CAEAGLLayer*)self.layer];
    [self drawView:nil];
}

- (NSInteger)animationFrameInterval
{
    return animationFrameInterval;
}

- (void)setAnimationFrameInterval:(NSInteger)frameInterval
{
    // Frame interval defines how many display frames must pass between each time the
    // display link fires. The display link will only fire 30 times a second when the
    // frame internal is two on a display that refreshes 60 times a second. The default
    // frame interval setting of one will fire 60 times a second when the display refreshes
    // at 60 times a second. A frame interval setting of less than one results in undefined
    // behavior.
    if (frameInterval >= 1)
    {
        animationFrameInterval = frameInterval;

        if (animating)
        {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}

- (void)startAnimation
{
    if (!animating)
    {
        displayLink = [NSClassFromString(@"CADisplayLink") displayLinkWithTarget:self selector:@selector(drawView:)];
        [displayLink setFrameInterval:animationFrameInterval];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:(1.0 / 15)];
        [[UIAccelerometer sharedAccelerometer] setDelegate:self];

        animating = TRUE;
    }
}

- (void)stopAnimation
{
    if (animating)
    {
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
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    for (UITouch *touch in touches) {
        touchCount--;
        NSString* path = [NSString stringWithFormat:@"/1/touch/%d", touchCount];
        Jamadhar::OscClient::SendMessage([path UTF8String], 0.0f);
    }
}

- (void)accelerometer:(UIAccelerometer*)accelerometer
        didAccelerate:(UIAcceleration*)acceleration {
    Jamadhar::OscClient::SendMessage("/1/accel/x", acceleration.x);
    Jamadhar::OscClient::SendMessage("/1/accel/y", acceleration.y);
    Jamadhar::OscClient::SendMessage("/1/accel/z", acceleration.z);
}

- (void)dealloc
{
    [renderer release];

    [super dealloc];
}

@end
