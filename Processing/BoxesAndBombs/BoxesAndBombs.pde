// "Boxes and Bombs"
// Processing + JBox2D ゲーム作例

// キー入力フラグ
boolean keyInLeft;    // カーソル左キー
boolean keyInRight;   // カーソル右キー
boolean keyInUp;      // カーソル上キー
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

// 現時刻に削除する Body の予約リスト
Set killList;

// プレイヤークラス
class PlayerData implements Steppable, Drawable {
  public float radius;        // 大きさ（半径）
  public boolean isGrounded;  // 地面接触フラグ
  // デフォルトコンストラクタ
  public PlayerData(float radius) {
    this.radius = radius;
    isGrounded = false;
  }
  // step 更新メソッドの実装
  public void step(Body body) {
    Vec2 pos = body.getPosition();
    float mass = body.getMass();
    // プレイヤー固有の擬似重力
    body.applyForce(new Vec2(0, -30.0f * mass), pos);     // ★ 追加の重力
    // ジャンプ
    if (isGrounded && keyInUp) {
      body.applyForce(new Vec2(0, 200.0f * mass), pos);   // ★ ジャンプ力
    }
    // 歩行
    float vx = 5.4f * (keyInLeft ? -1 : (keyInRight ? 1 : 0));  // ★ 移動速度
    float thrust = isGrounded ? 15.0f : 5.0f; // ★ 加速係数（接地時／滞空時）
    float force = (vx - body.getLinearVelocity().x) * mass * thrust;
    body.applyForce(new Vec2(force, 0), pos);
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
  CircleDef sd = new CircleDef();
  sd.radius = 0.35f;          // ★ 大きさ（半径）
  sd.density = 1.0f;          // ★ 質量（密度）

  BodyDef bd = new BodyDef();
  bd.position.set(0, 2);      // ★ 初期座標
  bd.userData = new PlayerData(sd.radius);

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

// ブロッククラス
class BlockData implements Drawable {
  public float hx;          // 幅
  public float hy;          // 高さ
  public color col;         // 色
  // コンストラクタ
  public BlockData(float hx, float hy, color col) {
    this.hx = hx;
    this.hy = hy;
    this.col = col;
  }
  // draw 描画メソッドの実装
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    rotate(body.getAngle());
    fill(col);
    rect(-hx, -hy, hx * 2, hy * 2);
  }
}
// 可動ブロック生成関数
Body spawnMovableBlock(World world) {
  float hx = random(0.4f, 1.0f);        // ★ 幅（ランダム）
  float hy = random(0.2f, 0.5f);        // ★ 高さ（ランダム）

  PolygonDef sd = new PolygonDef();
  sd.setAsBox(hx, hy);
  sd.density = 1.0f;                    // ★ 質量（密度）
  sd.friction = 0.3f;                   // ★ 摩擦係数

  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10);   // ★ 初期座標
  bd.userData = new BlockData(hx, hy, 0);

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}
// 固定ブロック生成関数
Body spawnFixedBlock(World world, Vec2 pos, float hx, float hy, color col) {
  PolygonDef sd = new PolygonDef();
  sd.setAsBox(hx, hy);
  sd.density = 100.0f;                  // ★ 質量（極端に重く！）

  BodyDef bd = new BodyDef();
  bd.position = pos;
  bd.userData = new BlockData(hx, hy, col);

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
        if (victim.getUserData() instanceof BlockData) killList.add(victim);
      } else {
        // 吹き飛ばし
        Vec2 dest = victim.getPosition();
        Vec2 vec = dest.sub(body.getPosition());
        victim.applyForce(vec.mul(75.0f / vec.length()), dest);  // ★ 爆風の強さ
      }
    }
    // １回の更新で自滅
    killList.add(body);
  }
  // draw メソッドの実装
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    fill(color(200, 0, 0, 32));
    ellipse(0, 0, radius * 2, radius * 2);
  }
}
// 爆風クラスの生成
Body spawnBlast(World world, Vec2 pos, float radius, boolean isFatal) {
  CircleDef sd = new CircleDef();
  sd.radius = radius;
  sd.isSensor = true;

  BodyDef bd = new BodyDef();
  bd.position = pos;
  bd.userData = new BlastData(radius, isFatal);

  Body body = world.createBody(bd);
  body.createShape(sd);
  return body;
}

// 爆弾クラス
class BombData implements Steppable, Drawable {
  public float radius;    // 大きさ（半径）
  public float timer;     // 爆発までの残り時間
  // コンストラクタ
  public BombData(float radius) {
    this.radius = radius;
    timer = 3.2f;         // ★ 爆発までの時間
  }
  // step メソッドの実装
  public void step(Body body) {
    timer -= 1.0f / frameRate;
    if (timer <= 0) {
      // 爆風を生成して自滅
      Vec2 pos = body.getPosition();
      spawnBlast(body.getWorld(), pos, 1.2f, true);   // ★ ダメージ半径
      spawnBlast(body.getWorld(), pos, 3.0f, false);  // ★ 吹き飛ばし半径
      killList.add(body);
    }
  }
  // draw メソッドの実装
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    fill(color(sin(timer * 20) * 100 + 100, 0, 0)); // 赤・黒に点滅
    ellipse(0, 0, radius * 2, radius * 2);
  }
}
// 爆弾クラスの生成
Body spawnBomb(World world) {
  CircleDef sd = new CircleDef();
  sd.radius = 0.3f;           // ★ 大きさ（半径）
  sd.density = 0.6f;          // ★ 質量（密度）
  sd.restitution = 0.3f;      // ★ 反射係数

  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10);   // ★ 初期座標
  bd.userData = new BombData(sd.radius);

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
Body floor;
float bombInterval;

void setup() {
  size(512, 512);   // ★ 画面の大きさ
  frameRate(30);    // ★ 目標フレームレート
  // テキスト描画設定
  textFont(loadFont("Optima-Regular-16.vlw"), 16);
  textAlign(CENTER);
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
    spawnFixedBlock(world, new Vec2(x, 0.75f), 0.25f, 0.25f, 0);
  }
  floor = spawnFixedBlock(world, new Vec2(0, 0.25f),
                          5.0f, 0.25f, color(140, 140, 0));
  // プレイヤーの初期化
  player = spawnPlayer(world);
  // 最初の爆弾生成までの時間
  bombInterval = 1.5f;    // ★ 最初の爆弾生成
}

void draw() {
  // 描画基本設定
  smooth();
  noStroke();
  background(255);
  // 物理ワールドの座標系とスクリーン座標系の対応付け
  pushMatrix();
  translate(width / 2, height);
  scale(width / 10, height / -10);
  // ステップ前初期化
  killList = new HashSet();
  // ブロックをランダムに生成
  if (random(2.1f * frameRate) < 1) {   // ★ ブロックの平均生成間隔
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
  world.step(1.0f / frameRate, 8);
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
  for (Iterator i = killList.iterator(); i.hasNext();) {
    Body body = (Body)i.next();
    if (floor == body) floor = null; // 床破壊判定
    world.destroyBody(body);
  }
  // ゲームオーバー表示
  popMatrix();
  if (floor == null) {
    fill(0);
    text("GAME OVER", width / 2, height / 2);
  }
}
