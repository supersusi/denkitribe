#import <Box2D/Box2D.h>

@interface Tofu : NSObject {
@private
    b2Body *body;
    CGSize size;
}

- (id)initWithWorld:(b2World*)world
               size:(CGSize)aSize
           position:(b2Vec2)aPosition;
- (void)draw;

@end
