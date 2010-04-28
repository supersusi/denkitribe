#import "EAGLView.h"
#import "Wrangler.h"

@implementation EAGLView

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (id)initWithCoder:(NSCoder*)coder {
    if (self = [super initWithCoder:coder]) {
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*)self.layer;
        eaglLayer.opaque = TRUE;
        eaglLayer.drawableProperties = [NSDictionary
            dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:FALSE],
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
        glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES,
                                     GL_COLOR_ATTACHMENT0_OES,
                                     GL_RENDERBUFFER_OES,
                                     colorRenderbuffer);

        [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0];
        [[UIAccelerometer sharedAccelerometer] setDelegate:self];

        frameStartTime = CFAbsoluteTimeGetCurrent();

        animating = FALSE;
        displayLink = nil;
        wrangler = nil;
        accelX = accelY = 0;
    }
    return self;
}

- (void)drawView:(id)sender {
    glViewport(0, 0, backingWidth, backingHeight);
    if (wrangler) [wrangler render];
    [context presentRenderbuffer:GL_RENDERBUFFER_OES];
    
    CFTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    if (wrangler) [wrangler stepTime:(currentTime - frameStartTime)
                             gravity:b2Vec2(accelX, -accelY)];
    frameStartTime = currentTime;
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
    for (UITouch *touch in touches) {
        CGPoint point = [touch locationInView:self];
        float scale = 10.0f / backingWidth;
        [wrangler touchAt:CGPointMake(point.x * scale, point.y * scale)];
    }
}

- (void)accelerometer:(UIAccelerometer*)accelerometer
        didAccelerate:(UIAcceleration*)acceleration {
    accelX = acceleration.x;
    accelY = acceleration.y;
}

- (void)layoutSubviews {
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES
                    fromDrawable:(CAEAGLLayer*)self.layer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES,
                                    GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES,
                                    GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
        NSLog(@"Failed to make complete framebuffer object %x",
              glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
    } else {
        if (!wrangler) {
            float aspect = (float)backingWidth / backingHeight;
            wrangler = [[Wrangler alloc] initWithSize:CGSizeMake(10, 10.0f / aspect)];
        }
        [self drawView:nil];
    }
}

- (void)startAnimation {
    if (!animating) {
        displayLink = [NSClassFromString(@"CADisplayLink")
                       displayLinkWithTarget:self selector:@selector(drawView:)];
        [displayLink setFrameInterval:1];
        [displayLink addToRunLoop:[NSRunLoop currentRunLoop]
                          forMode:NSDefaultRunLoopMode];
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

    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }

    [context release];
    context = nil;

    [wrangler release];
    wrangler = nil;
    
    [super dealloc];
}

@end
