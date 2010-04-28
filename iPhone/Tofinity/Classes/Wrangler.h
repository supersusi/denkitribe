#import <Box2D/Box2D.h>

@interface Wrangler : NSObject {
@private
    CGSize size;
    b2World *world;
}

- (id)initWithSize:(CGSize)aSize;
- (void)touchAt:(CGPoint)point;
- (void)stepTime:(float)time gravity:(b2Vec2)accelVector;
- (void)render;

@end
