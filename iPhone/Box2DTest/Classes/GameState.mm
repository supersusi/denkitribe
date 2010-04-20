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

@synthesize innerWidth;
@synthesize innerHeight;

- (id)initWithWidth:(float)width andHeight:(float)height {
  if (self = [super init]) {
    innerWidth = width;
    innerHeight = height;
    
    NSAssert(!g_pWorld, @"ワールドが既に存在する");
    g_pWorld = new b2World(b2Vec2(0, 0), false);
    
    // 画面を囲む四辺の箱
    b2BodyDef bodyDef;
    bodyDef.position.Set(0, 0);
    b2Body* pBody = g_pWorld->CreateBody(&bodyDef);
    b2PolygonShape shapes[4];
    shapes[0].SetAsBox(innerWidth, 1, b2Vec2(0, -1), 0);
    shapes[1].SetAsBox(innerWidth, 1, b2Vec2(0, innerHeight + 1), 0);
    shapes[2].SetAsBox(1, innerHeight, b2Vec2(-1, 0), 0);
    shapes[3].SetAsBox(1, innerHeight, b2Vec2(innerWidth + 1, 0), 0);
    for (int i = 0; i < 4; ++i) {
      pBody->CreateFixture(&shapes[i], 0);
    }
  }
  return self;
}

- (void)dealloc {
  // Bodyに関連付けたユーザーデータの削除
  b2Body *pBody = g_pWorld->GetBodyList();
  while (pBody != nil) {
    if (pBody->GetUserData()) {
      delete static_cast<EntityInfo*>(pBody->GetUserData());
    }
    pBody = pBody->GetNext();
  }
  
  delete g_pWorld;
  
  [super dealloc];
}

- (void)addBodyX:(float)ox andY:(float)oy {
  b2BodyDef bodyDef;
  bodyDef.type = b2_dynamicBody;
  bodyDef.position.Set(ox, oy);
  b2Body *pBody = g_pWorld->CreateBody(&bodyDef);
  
  b2PolygonShape dynamicBox;
  dynamicBox.SetAsBox(0.5f, 0.5f);
  
  b2FixtureDef fixtureDef;
  fixtureDef.shape = &dynamicBox;
  fixtureDef.density = 1.0f;
  fixtureDef.friction = 0.3f;
  fixtureDef.restitution = 0.6f;
  pBody->CreateFixture(&fixtureDef);
  
  pBody->SetUserData(new EntityInfo);
}

- (void)stepTime:(float)time gravityX:(float)gravx gravityY:(float)gravy {
  const float gravity = 40;
  g_pWorld->SetGravity(b2Vec2(gravx * gravity, gravy * gravity));
  g_pWorld->Step(time, 6, 2);
  g_pWorld->ClearForces();
}

- (void)render {
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrthof(0, innerWidth, innerHeight, 0, 0, 1);
  
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  
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
      glScalef(0.5f, 0.5f, 1);
      glDrawArrays(GL_LINE_LOOP, 0, 4);
      glPopMatrix();
    }
    pBody = pBody->GetNext();
  }
}

@end
