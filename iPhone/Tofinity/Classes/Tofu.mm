#import "Tofu.h"
#import <OpenGLES/ES1/gl.h>

@implementation Tofu

- (id)initWithWorld:(b2World*)world
               size:(CGSize)aSize
           position:(b2Vec2)aPosition {
    if (self = [super init]) {
        size = aSize;
        
        b2BodyDef bodyDef;
        bodyDef.type = b2_dynamicBody;
        bodyDef.position = aPosition;
        body = world->CreateBody(&bodyDef);
        
        b2PolygonShape shape;
        shape.SetAsBox(aSize.width, aSize.height);
        
        b2FixtureDef fixtureDef;
        fixtureDef.shape = &shape;
        fixtureDef.density = 1.0f;
        fixtureDef.friction = 0.3f;
        fixtureDef.restitution = 0.6f;
        body->CreateFixture(&fixtureDef);
        
        body->SetUserData(self);
    }
    return self;
}

- (void)draw {
    static const GLfloat boxVertices[] = {-1, -1, 1, -1, 1, 1, -1, 1};
    glVertexPointer(2, GL_FLOAT, 0, boxVertices);
    glEnableClientState(GL_VERTEX_ARRAY);
    glColor4f(0, 0, 0, 1);
    
    glPushMatrix();
    b2Vec2 position = body->GetPosition();
    glTranslatef(position.x, position.y, 0.0f);
    glRotatef(body->GetAngle() * 180 / 3.14159f, 0, 0, 1);
    glScalef(size.width, size.height, 1);
    glDrawArrays(GL_LINE_LOOP, 0, 4);
    glPopMatrix();
}  

@end
