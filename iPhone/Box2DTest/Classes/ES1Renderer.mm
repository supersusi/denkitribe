#import "ES1Renderer.h"
#include <Box2D/Box2D.h>

b2World *g_pWorld;

struct EntityInfo {
  float width, height;
};

float GenerateRandom(float min, float max) {
  return (max - min) / RAND_MAX * random() + min;
}

@implementation ES1Renderer

- (void)accelerometer:(UIAccelerometer *)accelerometer
        didAccelerate:(UIAcceleration *)acceleration {
  accX = acceleration.x;
  accY = acceleration.y;
}

- (void)beginTouch:(CGPoint)point {
}

// Create an OpenGL ES 1.1 context
- (id)init {
  if ((self = [super init])) {
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];

    if (!context || ![EAGLContext setCurrentContext:context]) {
      [self release];
      return nil;
    }

    // Create default framebuffer object. The backing will be allocated for the current layer in -resizeFromLayer
    glGenFramebuffersOES(1, &defaultFramebuffer);
    glGenRenderbuffersOES(1, &colorRenderbuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, defaultFramebuffer);
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, colorRenderbuffer);
  }
  
  [[UIAccelerometer sharedAccelerometer] setUpdateInterval:0];
  [[UIAccelerometer sharedAccelerometer] setDelegate:self];
  return self;
}

- (void)render {
  float aspect = (float)backingHeight / backingWidth;

  if (g_pWorld == nil) {
    g_pWorld = new b2World(b2Vec2(0, -10), false);
    
    b2BodyDef groundBodyDef;
    groundBodyDef.position.Set(0, 0);
    b2Body* pGroundBody = g_pWorld->CreateBody(&groundBodyDef);
    
    b2PolygonShape groundBox;
    groundBox.SetAsBox(10, 1, b2Vec2(0, aspect * -10 - 1), 0);
    pGroundBody->CreateFixture(&groundBox, 0.0f);
    groundBox.SetAsBox(10, 1, b2Vec2(0, aspect * 10 + 1), 0);
    pGroundBody->CreateFixture(&groundBox, 0.0f);
    groundBox.SetAsBox(1, aspect * 10, b2Vec2(-11, 0), 0);
    pGroundBody->CreateFixture(&groundBox, 0.0f);
    groundBox.SetAsBox(1, aspect * 10, b2Vec2(11, 0), 0);
    pGroundBody->CreateFixture(&groundBox, 0.0f);
    
    for (int i = 0; i < 32; ++i) {
      b2BodyDef bodyDef;
      bodyDef.type = b2_dynamicBody;
      bodyDef.position.Set(GenerateRandom(-8, 8), GenerateRandom(-8, 8));
      bodyDef.angle = GenerateRandom(0, 3.14159f);
      b2Body *pBody = g_pWorld->CreateBody(&bodyDef);
      
      b2PolygonShape dynamicBox;
      dynamicBox.SetAsBox(1.0f, 1.0f);
      
      b2FixtureDef fixtureDef;
      fixtureDef.shape = &dynamicBox;
      fixtureDef.density = 1.0f;
      fixtureDef.friction = 0.3f;
      fixtureDef.restitution = 0.6f;
      pBody->CreateFixture(&fixtureDef);
      
      pBody->SetUserData(new EntityInfo);
    }
  }
  
  g_pWorld->SetGravity(b2Vec2(accX * 10, accY * 10));
  
  g_pWorld->Step(1.0f / 30, 6, 2);
  g_pWorld->ClearForces();
  
  glViewport(0, 0, backingWidth, backingHeight);
  
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrthof(-1, 1, -aspect, aspect, 0, 100);
  
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glScalef(0.1f, 0.1f, 0.1f);
  
  glClearColor(0.95f, 0.95f, 0.95f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT);
  
  glColor4f(0, 0, 0, 1);
  glLineWidth(5.0f);
  
  {
    static const GLfloat squareVertices[] = { -1, -1, +1, -1, +1, +1, -1, +1 };
    glVertexPointer(2, GL_FLOAT, 0, squareVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
  }
  
  b2Body *pBody = g_pWorld->GetBodyList();
  while (pBody != nil) {
    if (pBody->GetUserData() != nil) {
      b2Vec2 position = pBody->GetPosition();
      float32 angle = pBody->GetAngle();
      glPushMatrix();
      glTranslatef(position.x, position.y, 0.0f);
      glRotatef(angle * 180 / 3.14159f, 0, 0, 1);
      glDrawArrays(GL_LINE_LOOP, 0, 4);
      glPopMatrix();
    }
    pBody = pBody->GetNext();
  }
  
  [context presentRenderbuffer:GL_RENDERBUFFER_OES];
}

- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer
{	
    // Allocate color buffer backing based on the current layer size
    glBindRenderbufferOES(GL_RENDERBUFFER_OES, colorRenderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:layer];
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);

    if (glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES)
    {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
        return NO;
    }

    return YES;
}

- (void)dealloc
{
    // Tear down GL
    if (defaultFramebuffer)
    {
        glDeleteFramebuffersOES(1, &defaultFramebuffer);
        defaultFramebuffer = 0;
    }

    if (colorRenderbuffer)
    {
        glDeleteRenderbuffersOES(1, &colorRenderbuffer);
        colorRenderbuffer = 0;
    }

    // Tear down context
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];

    [context release];
    context = nil;

    [super dealloc];
}

@end
