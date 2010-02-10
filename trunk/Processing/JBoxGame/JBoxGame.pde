// Processing + JBox2D ゲーム作例

// キー入力
boolean keyInLeft;
boolean keyInRight;
boolean keyInUp;
// キー押下コールバック
void keyPressed() {
  if (key == CODED) {
    if (keyCode == UP) {
      keyInUp = true;
    } else if (keyCode == LEFT) {
      keyInLeft = true;
    } else if (keyCode == RIGHT) {
      keyInRight = true;
    }
  }
}
// キー解除コールバック
void keyReleased() {
  if (key == CODED) {
    if (keyCode == UP) {
      keyInUp = false;
    } else if (keyCode == LEFT) {
      keyInLeft = false;
    } else if (keyCode == RIGHT) {
      keyInRight = false;
    }
  }
}

// インターフェース定義
// step 更新メソッドを持つインターフェース
interface Steppable {
  void step(Body body);
}
// draw 描画メソッドを持つインターフェース
interface Drawable {
  void draw(Body body);
}

// 現時刻に削除する Body の予約セット
Set killSet;

// プレイヤークラス
class PlayerData implements Steppable, Drawable {
  public float radius;        // 半径（見た目と剛体）
  public boolean isGrounded;  // 地面接触フラグ
  public float time;
  // デフォルトコンストラクタ
  public PlayerData() {
    radius = 0.3f;      // ★ プレイヤーの大きさ
    isGrounded = false;
  }
  // step 更新メソッドの実装
  public void step(Body body) {
    Vec2 pos = body.getPosition();
    // プレイヤー固有の擬似重力
    body.applyForce(new Vec2(0, -9), pos);  // ★ 擬似重力
    // ジャンプ
    if (isGrounded && keyInUp) {
      body.applyForce(new Vec2(0, 70), pos);  // ★ ジャンプ力
    }
    // 歩行
    float vx = keyInLeft ? -5 : (keyInRight ? 5 : 0); // ★ 移動速度
    float acc = isGrounded ? 10 : 2;                  // ★ 加速度（接地：滞空）
    float thresh = 0.8f;                              // ★ 速度閾値
    Vec2 vel = body.getLinearVelocity();
    if (vel.x < vx - thresh) {
      body.applyForce(new Vec2(acc, 0), body.getPosition());
    } else if (vel.x > vx + thresh) {
      body.applyForce(new Vec2(-acc, 0), body.getPosition());
    }
    // 状態のクリア
    isGrounded = false;
  }
  // draw 描画メソッドの実装
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    fill(color(0, 100, 0));
    ellipse(0, 0, radius * 2, radius * 2);
  }
}
// プレイヤー生成関数
Body spawnPlayer(World world) {
  PlayerData data = new PlayerData();

  CircleDef sd = new CircleDef();
  sd.radius = data.radius;
  sd.density = 1.5f;        // ★ 体重（密度）

  BodyDef bd = new BodyDef();
  bd.position.set(0, 1);    // ★ 初期座標
  bd.linearDamping = 0.8f;  // ★ 空気抵抗
  bd.userData = data;

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

// ブロッククラス
class BlockData implements Drawable {
  public float width;     // 幅
  public float height;    // 高さ
  // コンストラクタ
  public BlockData(float width, float height) {
    this.width = width;
    this.height = height;
  }
  // draw 描画メソッドの実装
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    rotate(body.getAngle());
    fill(color(60, 60, 60));
    rect(-width, -height, width * 2, height * 2);
  }
}
// 可動ブロック生成関数
Body spawnMovableBlock(World world) {
  float width = random(0.4f, 1.0f);     // ★ 幅（ランダム）
  float height = random(0.2f, 0.6f);    // ★ 高さ（ランダム）
  BlockData data = new BlockData(width, height);

  PolygonDef sd = new PolygonDef();
  sd.setAsBox(width, height);
  sd.density = 1.0f;                    // ★ 質量（密度）
  sd.friction = 0.3f;                   // ★ 摩擦

  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10);   // ★ 初期座標
  bd.userData = data;

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}
// 固定ブロック生成関数
Body spawnFixedBlock(World world, Vec2 pos) {
  BlockData data = new BlockData(0.25f, 0.25f); // ★ 大きさ

  PolygonDef sd = new PolygonDef();
  sd.setAsBox(data.width, data.height);
  sd.density = 100.0f;                  // ★ 質量（極端に重い！）

  BodyDef bd = new BodyDef();
  bd.position = pos;
  bd.userData = data;

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

// 爆風クラス
class BlastData implements Steppable, Drawable {
  public float radius;          // 爆風半径
  public boolean isFatal;       // 有効ダメージフラグ
  public Set overlapSet;        // 爆風を受ける剛体のセット
  // コンストラクタ
  public BlastData(float radius, boolean isFatal) {
    this.radius = radius;
    this.isFatal = isFatal;
    overlapSet = new HashSet();
  }
  // step メソッドの実装
  public void step(Body body) {
    for (Iterator i = overlapSet.iterator(); i.hasNext();) {
      Body victim = (Body)i.next();
      if (isFatal) {
        // 対象がブロックなら破壊
        if (victim.getUserData() instanceof BlockData) killSet.add(victim);
      } else {
        // 吹き飛ばし
        Vec2 dest = victim.getPosition();
        Vec2 vec = dest.sub(body.getPosition());
        victim.applyForce(vec.mul(75.0f / vec.length()), dest);  // ★ 爆風の強さ
      }
    }
    // １回の更新で自滅
    killSet.add(body);
  }
  // draw メソッドの実装
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    fill(color(200, 0, 0, 32));
    ellipse(0, 0, radius * 2, radius * 2);
  }
}
Body spawnBlast(World world, Vec2 pos, float radius, boolean isFatal) {
  BlastData data = new BlastData(radius, isFatal);

  CircleDef sd = new CircleDef();
  sd.radius = data.radius;
  sd.isSensor = true;

  BodyDef bd = new BodyDef();
  bd.position = pos;
  bd.userData = data;

  Body body = world.createBody(bd);
  body.createShape(sd);
  return body;
}

// 爆弾クラス
class BombData implements Steppable, Drawable {
  public float radius;    // 半径
  public float timer;     // 爆発までの残り時間
  // コンストラクタ
  public BombData() {
    radius = 0.3f;        // ★ 半径
    timer = 3.2f;         // ★ 爆発までの時間
  }
  // step メソッドの実装
  public void step(Body body) {
    timer -= 1.0f / frameRate;
    if (timer <= 0) {
      // 爆風を生成して自滅
      Vec2 pos = body.getPosition();
      spawnBlast(body.getWorld(), pos, 1.0f, true);   // ★ ダメージ半径
      spawnBlast(body.getWorld(), pos, 2.7f, false);  // ★ 吹き飛ばし半径
      killSet.add(body);
    }
  }
  // draw メソッドの実装
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    fill(color(sin(timer * 20) * 100 + 100, 0, 0));
    ellipse(0, 0, radius * 2, radius * 2);
  }
}
// 爆弾クラスの生成
Body spawnBomb(World world) {
  BombData data = new BombData();

  CircleDef sd = new CircleDef();
  sd.radius = data.radius;
  sd.density = 0.3f;          // ★ 質量（密度）
  sd.restitution = 0.3f;      // ★ 反射係数

  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10); // ★ 初期座標
  bd.userData = data;

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

// カスタマイズされたコンタクトリスナー
class GlobalContactListener implements ContactListener {
  public void add(ContactPoint point) {
    Body body1 = point.shape1.getBody();
    Body body2 = point.shape2.getBody();
    Object ud1 = body1.getUserData();
    Object ud2 = body2.getUserData();
    // 爆風の当たり判定
    if (ud1 instanceof BlastData) {
      ((BlastData)ud1).overlapSet.add(body2);
    } else if (ud2 instanceof BlastData) {
      ((BlastData)ud2).overlapSet.add(body1);
    }
  }
  public void persist(ContactPoint point) {
  }
  public void remove(ContactPoint point) {
  }
  public void result(ContactResult point) {
    Object ud1 = point.shape1.getBody().getUserData();
    Object ud2 = point.shape2.getBody().getUserData();
    // プレイヤーの接地判定
    float thresh = sin(radians(45));    // ★ 最大登攀角
    if (ud1 instanceof PlayerData) {
      ((PlayerData)ud1).isGrounded |= (point.normal.y < thresh);
    } else if (ud2 instanceof PlayerData) {
      ((PlayerData)ud2).isGrounded |= (point.normal.y > thresh);
    }
  }
}

// グローバルオブジェクト
World world;
Body player;
float bombInterval;

void setup() {
  size(512, 512);   // ★ 画面の大きさ
  frameRate(30);    // ★ 目標フレームレート
  { // ワールドの初期化
    AABB worldAABB = new AABB();
    worldAABB.lowerBound.set(-20.0f, -10.0f);
    worldAABB.upperBound.set(+20.0f, +20.0f);
    Vec2 gravity = new Vec2(0.0f, -2.8f);     // ★ 重力加速度
    world = new World(worldAABB, gravity, true);
    world.setContactListener(new GlobalContactListener());
  }
  { // 壁の初期化
    BodyDef bd = new BodyDef();
    bd.position.set(0.0f, 0.0f);
    Body ground = world.createBody(bd);
    // 床
    PolygonDef sd = new PolygonDef();
    sd.setAsBox(20.0f, 1.0f, new Vec2(0, -1), 0);
    ground.createShape(sd);
    // 左壁
    sd.setAsBox(1.0f, 20.0f, new Vec2(-6, 0), 0);
    ground.createShape(sd);
    // 右壁
    sd.setAsBox(1.0f, 20.0f, new Vec2(6, 0), 0);
    ground.createShape(sd);
  }
  // 床の固定ブロック
  for (float x = -4.75f; x < 5.0f; x += 0.5f) {   // ★ 固定ブロックの大きさ等
    spawnFixedBlock(world, new Vec2(x, 0.25f));
  }
  // プレイヤーの初期化
  player = spawnPlayer(world);
  // 最初の爆弾生成までの時間
  bombInterval = 1.5f;    // ★ 最初の爆弾生成
}

void draw() {
  // 描画基本設定
  smooth();
  noStroke();
  fill(50);
  background(255);
  // 物理ワールドの座標系とスクリーン座標系の対応付け
  translate(width / 2, height);
  scale(width / 10, height / -10);
  // ステップ前初期化
  killSet = new HashSet();
  // ブロックをランダムに生成
  if (random(1.8f * frameRate) < 1) {   // ★ ブロックの平均生成間隔
    spawnMovableBlock(world);
  }
  // 爆弾を一定期間毎に生成
  bombInterval -= 1.0f / frameRate;
  if (bombInterval <= 0) {
    spawnBomb(world);
    bombInterval = random(2.5f, 4.0f);
  }
  // step メソッドの呼び出し
  for (Body body = world.getBodyList(); body != null; body = body.getNext()) {
    Object ud = body.getUserData();
    if (ud instanceof Steppable) ((Steppable)ud).step(body);
  }
  // 物理挙動の時間を進める
  world.step(1.0f / frameRate, 4);
  // draw メソッドの呼び出し
  for (Body body = world.getBodyList(); body != null; body = body.getNext()) {
    Object ud = body.getUserData();
    if (ud instanceof Drawable) {
      pushMatrix();
      ((Drawable)ud).draw(body);
      popMatrix();
    }
  }
  // 破棄予約の処理  
  for (Iterator i = killSet.iterator(); i.hasNext();) {
    world.destroyBody((Body)i.next());
  }
}
