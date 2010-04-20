#import "GameState.h"
#import <OpenGLES/ES1/gl.h>
#import <Box2D/Box2D.h>

@interface Entity : NSObject {
  float width, height;
}

- (id)initWithWidth:(float)w andHeight:(float)h;
- (void)drawWithBody:(b2Body*)body;
@end

@implementation Entity

- (id)initWithWidth:(float)w andHeight:(float)h {
  if (self = [super init]) {
    width = w;
    height = h;
  }
  return self;
}

- (void)drawWithBody:(b2Body*)body {
  b2Vec2 position = body->GetPosition();
  glPushMatrix();
  glTranslatef(position.x, position.y, 0.0f);
  glRotatef(body->GetAngle() * 180 / 3.14159f, 0, 0, 1);
  glScalef(width, height, 1);
  glDrawArrays(GL_LINE_LOOP, 0, 4);
  glPopMatrix();
}  

@end

@implementation GameState

@synthesize innerWidth;
@synthesize innerHeight;

- (id)initWithWidth:(float)width andHeight:(float)height {
  if (self = [super init]) {
    innerWidth = width;
    innerHeight = height;
    
    world = new b2World(b2Vec2(0, 0), false);
    
    // 画面を囲む四辺の箱
    b2BodyDef bodyDef;
    bodyDef.position.Set(0, 0);
    b2Body* body = world->CreateBody(&bodyDef);
    b2PolygonShape shapes[4];
    shapes[0].SetAsBox(innerWidth, 1, b2Vec2(0, -1), 0);
    shapes[1].SetAsBox(innerWidth, 1, b2Vec2(0, innerHeight + 1), 0);
    shapes[2].SetAsBox(1, innerHeight, b2Vec2(-1, 0), 0);
    shapes[3].SetAsBox(1, innerHeight, b2Vec2(innerWidth + 1, 0), 0);
    for (int i = 0; i < 4; ++i) {
      body->CreateFixture(&shapes[i], 0);
    }
  }
  return self;
}

- (void)dealloc {
  // Bodyに関連付けたユーザーデータの削除
  b2Body *body = world->GetBodyList();
  while (body != nil) {
    Entity* entity = (Entity*)body->GetUserData();
    if (entity) [entity dealloc];
    body = body->GetNext();
  }
  
  delete world;
  
  [super dealloc];
}

class TouchQueryCallback : public b2QueryCallback {
public:
  b2Body* overlappedBody;
  TouchQueryCallback() {
    overlappedBody = NULL;
  }
  bool ReportFixture(b2Fixture* fixture) {
    overlappedBody = fixture->GetBody();
    return false;
  }
};

- (void)touchX:(float)ox andY:(float)oy {
  TouchQueryCallback callback;
  b2AABB aabb;
  aabb.lowerBound.Set(ox - 0.02f, oy - 0.02f);
  aabb.upperBound.Set(ox + 0.02f, oy + 0.02f);
  world->QueryAABB(&callback, aabb);
  
  if (callback.overlappedBody) {
    Entity* entity = static_cast<Entity*>(callback.overlappedBody->GetUserData());
    if (entity) {
      [entity dealloc];
      world->DestroyBody(callback.overlappedBody);
      return;
    }
  }

  b2BodyDef bodyDef;
  bodyDef.type = b2_dynamicBody;
  bodyDef.position.Set(ox, oy);
  b2Body *body = world->CreateBody(&bodyDef);
  
  b2PolygonShape dynamicBox;
  dynamicBox.SetAsBox(0.5f, 0.5f);
  
  b2FixtureDef fixtureDef;
  fixtureDef.shape = &dynamicBox;
  fixtureDef.density = 1.0f;
  fixtureDef.friction = 0.3f;
  fixtureDef.restitution = 0.6f;
  body->CreateFixture(&fixtureDef);
  
  body->SetUserData([[Entity alloc] initWithWidth:0.5f andHeight:0.5f]);
}

- (void)stepTime:(float)time gravityX:(float)gravx gravityY:(float)gravy {
  const float gravity = 40;
  world->SetGravity(b2Vec2(gravx * gravity, gravy * gravity));
  world->Step(time, 6, 2);
  world->ClearForces();
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
  
  b2Body *body = world->GetBodyList();
  while (body != nil) {
    Entity *entity = (Entity*)body->GetUserData();
    if (entity) [entity drawWithBody:body];
    body = body->GetNext();
  }
}

@end
