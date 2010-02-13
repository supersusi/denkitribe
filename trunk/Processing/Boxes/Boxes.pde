World world;

void setup() {
  size(512, 512);
  // ワールドの初期化
  AABB worldAABB = new AABB();
  worldAABB.lowerBound.set(-10, -10);
  worldAABB.upperBound.set(+10, +20);
  Vec2 gravity = new Vec2(0, -8); // 重力加速度
  world = new World(worldAABB, gravity, true);
  // 地面の追加
  PolygonDef sd = new PolygonDef();
  sd.setAsBox(20.0f, 1.0f, new Vec2(0, -1), 0);
  BodyDef bd = new BodyDef();
  Body ground = world.createBody(bd);
  ground.createShape(sd);
}

// 箱生成
Body spawnBox(World world) {
  float hx = random(0.2f, 1.4f); // 幅
  float hy = random(0.2f, 1.4f); // 高さ

  PolygonDef sd = new PolygonDef();
  sd.setAsBox(hx, hy);
  sd.density = 1.0f; // 重さ（密度）

  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10); // 初期座標
  bd.angle = random(0, PI);           // 初期角度
  bd.userData = new Box(hx, hy);

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

interface Drawable { void draw(Body body); }

// 箱クラス
class Box implements Drawable {
  public float hx; // 幅
  public float hy; // 高さ
  // コンストラクタ
  public Box(float hx, float hy) {
    this.hx = hx;
    this.hy = hy;
  }
  // draw描画メソッドの実装
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    rotate(body.getAngle());
    rect(-hx, -hy, hx * 2, hy * 2);
  }
}

void draw() {
  smooth();
  noStroke();
  background(255);
  fill(100);
  // ワールドの座標系とスクリーン座標系の変換
  translate(width / 2, height);
  scale(width / 10, height / -10);
  // 箱をランダムに生成
  if (random(0.9f * frameRate) < 1) {
    spawnBox(world);
  }
  // ワールドの時間を進める
  world.step(1.0f / frameRate, 8);
  // drawメソッドの呼び出し
  for (Body body = world.getBodyList();
       body != null; body = body.getNext()) {
    Object ud = body.getUserData();
    if (ud instanceof Drawable) {
      pushMatrix();
      ((Drawable)ud).draw(body);
      popMatrix();
    }
  }
}
