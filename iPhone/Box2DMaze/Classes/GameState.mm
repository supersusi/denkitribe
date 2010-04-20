#import "GameState.h"
#import <OpenGLES/ES1/gl.h>
#import <Box2D/Box2D.h>

float randf(float min, float max) {
  return (max - min) * random() / RAND_MAX + min;
}

@interface Entity : NSObject {
  b2Body *body;
  float width, height;
}
- (void)step;
- (void)draw;
@end

@interface MovingBox : Entity {
}
- (id)initWithWorld:(b2World*)world
           andWidth:(float)w
          andHeight:(float)h
        andPosition:(b2Vec2)pos
           andAngle:(float)angle;
@end

@interface FixedBox : Entity {
}
- (id)initWithWorld:(b2World*)world
           andWidth:(float)w
          andHeight:(float)h
        andPosition:(b2Vec2)pos
           andAngle:(float)angle;
@end

@interface ForceField : Entity {
}
- (id)initWithWorld:(b2World*)world
           andWidth:(float)w
          andHeight:(float)h
        andPosition:(b2Vec2)pos
           andAngle:(float)angle;
@end

@implementation Entity
- (void)step {
}  
- (void)draw {
}  
@end

@implementation MovingBox
- (id)initWithWorld:(b2World*)world
           andWidth:(float)w
          andHeight:(float)h
        andPosition:(b2Vec2)pos
           andAngle:(float)angle {
  if (self = [super init]) {
    width = w;
    height = h;

    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position = pos;
    body = world->CreateBody(&bodyDef);
    
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(w, h);
    
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    fixtureDef.density = 1.0f;
    fixtureDef.friction = 0.3f;
    fixtureDef.restitution = 0.6f;
    body->CreateFixture(&fixtureDef);
    
    body->SetUserData(self);
  }
  return self;
}
- (void)draw {
  b2Vec2 position = body->GetPosition();
  glPushMatrix();
  glTranslatef(position.x, position.y, 0.0f);
  glRotatef(body->GetAngle() * 180 / 3.14159f, 0, 0, 1);
  glScalef(width, height, 1);
  glColor4f(0.8f, 0.8f, 0.8f, 1);
  glDrawArrays(GL_LINE_LOOP, 0, 4);
  glPopMatrix();
}  
@end

@implementation FixedBox
- (id)initWithWorld:(b2World*)world
           andWidth:(float)w
          andHeight:(float)h
        andPosition:(b2Vec2)pos
           andAngle:(float)angle {
  if (self = [super init]) {
    width = w;
    height = h;
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_staticBody;
    bodyDef.position = pos;
    body = world->CreateBody(&bodyDef);
    
    b2PolygonShape shape;
    shape.SetAsBox(w, h);
    
    body->CreateFixture(&shape, 0);
    
    body->SetUserData(self);
  }
  return self;
}
- (void)draw {
  b2Vec2 position = body->GetPosition();
  glPushMatrix();
  glTranslatef(position.x, position.y, 0.0f);
  glRotatef(body->GetAngle() * 180 / 3.14159f, 0, 0, 1);
  glScalef(width, height, 1);
  glColor4f(0, 0, 0, 1);
  glDrawArrays(GL_LINE_LOOP, 0, 4);
  glPopMatrix();
}  
@end

@implementation ForceField
- (id)initWithWorld:(b2World*)world
           andWidth:(float)w
          andHeight:(float)h
        andPosition:(b2Vec2)pos
           andAngle:(float)angle {
  if (self = [super init]) {
    width = w;
    height = h;
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_staticBody;
    bodyDef.position = pos;
    body = world->CreateBody(&bodyDef);
    
    b2PolygonShape shape;
    shape.SetAsBox(w, h);
    
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &shape;
    fixtureDef.isSensor = true;
    body->CreateFixture(&fixtureDef);
    
    body->SetUserData(self);
  }
  return self;
}
- (void)draw {
  b2Vec2 position = body->GetPosition();
  glPushMatrix();
  glTranslatef(position.x, position.y, 0.0f);
  glRotatef(body->GetAngle() * 180 / 3.14159f, 0, 0, 1);
  glScalef(width, height, 1);
  glColor4f(1, 0.5f, 0.5f, 1);
  glDrawArrays(GL_LINE_LOOP, 0, 4);
  glPopMatrix();
}  
@end

BOOL IsMovingBox(b2Body *body) {
  id entity = (id)body->GetUserData();
  return (entity && [entity isMemberOfClass:[MovingBox class]]);
}

BOOL IsForceField(b2Body *body) {
  id entity = (id)body->GetUserData();
  return (entity && [entity isMemberOfClass:[ForceField class]]);
}


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
    
    for (int i = 0; i < 8; ++i) {
      if (random() & 1) {
        [[FixedBox alloc] initWithWorld:world andWidth:randf(0.5f, 1.5f) andHeight:randf(0.5f, 1.5f) andPosition:b2Vec2(randf(0, innerWidth), randf(0, innerHeight)) andAngle:randf(-3.14159f, 3.14159f)];
      } else {
        [[ForceField alloc] initWithWorld:world andWidth:randf(0.5f, 1.5f) andHeight:randf(0.5f, 1.5f) andPosition:b2Vec2(randf(0, innerWidth), randf(0, innerHeight)) andAngle:randf(-3.14159f, 3.14159f)];
      }
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
  
  if (random() & 1) {
    [[MovingBox alloc] initWithWorld:world andWidth:0.5f andHeight:0.5f andPosition:b2Vec2(ox, oy) andAngle:0];
  } else if (random() & 1) {
    [[ForceField alloc] initWithWorld:world andWidth:1.0f andHeight:1.0f andPosition:b2Vec2(ox, oy) andAngle:0];
  } else {
    [[FixedBox alloc] initWithWorld:world andWidth:0.5f andHeight:0.5f andPosition:b2Vec2(ox, oy) andAngle:0];
  }
}

- (void)stepTime:(float)time gravityX:(float)gravx gravityY:(float)gravy {
  const float gravity = 40;
  world->SetGravity(b2Vec2(gravx * gravity, gravy * gravity));
  
  for (b2Contact *contact = world->GetContactList(); contact; contact = contact->GetNext()) {
    b2Body* bodyA = contact->GetFixtureA()->GetBody();
    b2Body* bodyB = contact->GetFixtureB()->GetBody();
    if (IsMovingBox(bodyA) && IsForceField(bodyB)) {
      bodyA->ApplyForce(b2Vec2(50, 0), bodyA->GetWorldCenter());
    } else if (IsMovingBox(bodyB) && IsForceField(bodyA)) {
      bodyB->ApplyForce(b2Vec2(50, 0), bodyB->GetWorldCenter());
    }
  }
  
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
    if (entity) [entity draw];
    body = body->GetNext();
  }
}

@end
