class b2World;

@interface GameState : NSObject {
@private
  float innerWidth;
  float innerHeight;
  b2World *world;
}

@property (nonatomic, readonly) float innerWidth;
@property (nonatomic, readonly) float innerHeight;

- (id)initWithWidth:(float)width andHeight:(float)height;
- (void)addBodyX:(float)ox andY:(float)oy;
- (void)stepTime:(float)time gravityX:(float)gravx gravityY:(float)gravy;
- (void)render;

@end
