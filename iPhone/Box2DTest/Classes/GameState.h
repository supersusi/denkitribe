@interface GameState : NSObject {
@private
  float screenAspect;
}

@property (nonatomic) float screenAspect;

- (void)setup;
- (void)addBox:(float)ox yCoord:(float)oy;
- (void)step:(float)time gravityX:(float)gravx gravityY:(float)gravy;
- (void)render;

@end
