#import "GameState.h"
#import <OpenGLES/ES1/gl.h>

#include <Box2D/Box2D.h>

namespace {
  b2World *g_pWorld;
  
  struct EntityInfo {
    float width;
    float height;
  };
  
  float randf(float min, float max) {
    return (max - min) / RAND_MAX * random() + min;
  }
}

@implementation GameState

@synthesize screenAspect;

- (void)setup {
  NSAssert(!g_pWorld, @"g_pWorld is already instantiated.");
  g_pWorld = new b2World(b2Vec2(0, 0), false);
  
  { // 画面を囲む箱の構築
    b2BodyDef bodyDef;
    bodyDef.position.Set(0, 0);
    b2Body* pBody = g_pWorld->CreateBody(&bodyDef);
    
    float width = 10;
    float height = screenAspect * width;
    b2PolygonShape shapes[4];
    shapes[0].SetAsBox(width, 1, b2Vec2(0, -height - 1), 0);
    shapes[1].SetAsBox(width, 1, b2Vec2(0, +height + 1), 0);
    shapes[2].SetAsBox(1, height, b2Vec2(-width - 1, 0), 0);
    shapes[3].SetAsBox(1, height, b2Vec2(+width + 1, 0), 0);
    for (int i = 0; i < 4; ++i) {
      pBody->CreateFixture(&shapes[i], 0);
    }
  }
  /*
  for (int i = 0; i < 32; ++i) {
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(randf(-8, 8), randf(-8, 8));
    bodyDef.angle = randf(0, 3.14159f);
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
   */
}

- (void)addBox:(float)ox yCoord:(float)oy {
  b2BodyDef bodyDef;
  bodyDef.type = b2_dynamicBody;
  bodyDef.position.Set(ox, oy);
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

- (void)step:(float)time gravityX:(float)gravx gravityY:(float)gravy {
  if (!g_pWorld) {
    [self setup];
  } else {
    const float gravity = 40;
    g_pWorld->SetGravity(b2Vec2(gravx * gravity, gravy * gravity));
    g_pWorld->Step(time, 6, 2);
    g_pWorld->ClearForces();
  }
}

- (void)render {
  if (!g_pWorld) return;
  
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrthof(-1, 1, -screenAspect, screenAspect, 0, 100);
  
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
}

@end
