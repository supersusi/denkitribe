World world;
Body player;
Body ground;
Set killList; // 削除するBodyの予約リスト

boolean keyLeft;  // 左キー入力
boolean keyRight; // 右キー入力
boolean keyUp;    // 上キー入力
// キー押下コールバック
void keyPressed() {
  if (key != CODED) return;
  if (keyCode == UP) {
    keyUp = true;
  } else if (keyCode == LEFT) {
    keyLeft = true;
  } else if (keyCode == RIGHT) {
    keyRight = true;
  }
}
// キー解除コールバック
void keyReleased() {
  if (key != CODED) return;
  if (keyCode == UP) {
    keyUp = false;
  } else if (keyCode == LEFT) {
    keyLeft = false;
  } else if (keyCode == RIGHT) {
    keyRight = false;
  }
}

interface Drawable { void draw(Body body); }

// プレイヤークラス
class Player implements Drawable {
  public static final float RADIUS = 0.35; // 大きさ（半径）
  public boolean isGrounded; // 地面接触フラグ
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    fill(color(0.2, 0.8, 0.7));
    ellipse(0, 0, RADIUS * 2, RADIUS * 2);
    // プレイヤー固有の擬似重力
    float mass = body.getMass();
    body.applyForce(new Vec2(0, mass * -30), pos);
    // ジャンプ
    if (isGrounded && keyUp) {
      body.applyImpulse(new Vec2(0, mass * 6), pos);
    }
    // 歩行
    float vx1 = body.getLinearVelocity().x;
    float vx2 = keyLeft ? -5.4 : (keyRight ? 5.4 : 0); // 目標速度
    float acc = isGrounded ? 15.0 : 5.0; // 加速係数（接地時／滞空時）
    body.applyForce(new Vec2((vx2 - vx1) * mass * acc, 0), pos);
    // フラグのクリア
    isGrounded = false;
  }
}
// プレイヤーの生成
Body spawnPlayer(World world) {
  CircleDef sd = new CircleDef();
  sd.radius = Player.RADIUS;
  sd.density = 1.0; // 質量（密度）

  BodyDef bd = new BodyDef();
  bd.position.set(0, 4); // 初期座標
  bd.userData = new Player();

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

// 箱クラス
class Box implements Drawable {
  public float hx;  // 幅
  public float hy;  // 高さ
  public color col; // 色
  public Box(float hx, float hy, color col) {
    this.hx = hx;
    this.hy = hy;
    this.col = col;
  }
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    rotate(body.getAngle());
    fill(col);
    rect(-hx, -hy, hx * 2, hy * 2);
  }
}
// 可動箱の生成
Body spawnMovableBox(World world) {
  float hx = random(0.4, 0.8); // 幅
  float hy = random(0.4, 0.6); // 高さ

  PolygonDef sd = new PolygonDef();
  sd.setAsBox(hx, hy);
  sd.density = 1.0;  // 質量（密度）
  sd.friction = 0.3; // 摩擦係数

  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10); // 初期座標
  bd.angle = random(0, PI);           // 初期角度
  bd.userData = new Box(hx, hy, color(0.3));

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}
// 固定箱の生成
Body spawnFixedBox(World world, Vec2 pos,
                   float hx, float hy, color col) {
  PolygonDef sd = new PolygonDef();
  sd.setAsBox(hx, hy);
  sd.density = 100; // 質量（極端に重く！）

  BodyDef bd = new BodyDef();
  bd.position = pos;
  bd.userData = new Box(hx, hy, col);

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

// 爆弾クラス
class Bomb implements Drawable {
  public static final float RADIUS = 0.3; // 大きさ（半径）
  public float timer; // 爆発までの残り時間
  public Bomb() {
    timer = 3.2; // 爆発までの時間
  }
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    fill(color(0, 1, abs(sin(timer * 10)))); // 点滅
    ellipse(0, 0, RADIUS * 2, RADIUS * 2);
    // 経過時間の計測
    timer -= 1.0 / frameRate;
    if (timer <= 0) {
      // 爆風を生成して自滅
      World world = body.getWorld();
      spawnBlast(world, pos, 1.2, true);  // 破壊
      spawnBlast(world, pos, 3.0, false); // 吹き飛ばし
      killList.add(body);
    }
  }
}
// 爆弾の生成
Body spawnBomb(World world) {
  CircleDef sd = new CircleDef();
  sd.radius = Bomb.RADIUS;
  sd.density = 0.6;     // 質量（密度）
  sd.restitution = 0.3; // 反射係数

  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10); // 初期座標
  bd.userData = new Bomb();

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

// 爆風クラス
class Blast implements Drawable {
  public float radius;    // 爆風半径
  public boolean isFatal; // 有効ダメージフラグ
  public Set overlapSet;  // 爆風を受ける剛体のリスト
  public float time;      // 時間経過
  public Blast(float radius, boolean isFatal) {
    this.radius = radius;
    this.isFatal = isFatal;
    overlapSet = new HashSet();
    time = 0;
  }
  public void draw(Body body) {
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    fill(color(0, 1, 1, 0.5 - time * 5));
    ellipse(0, 0, radius * 2, radius * 2);
    // 爆風を与える処理（最初のみ）
    if (time == 0) {
      for (Iterator i = overlapSet.iterator(); i.hasNext();) {
        Body victim = (Body)i.next();
        if (isFatal) {
          // 対象が箱なら破壊
          if (victim.getUserData() instanceof Box) {
            killList.add(victim);
          }
        } else {
          // 吹き飛ばし
          Vec2 dest = victim.getPosition();
          Vec2 vec = dest.sub(body.getPosition());
          Vec2 imp = vec.mul(3.7f / vec.length());
          victim.applyImpulse(imp, dest);
        }
      }
    }
    overlapSet.clear();
    // フェードアウト（0.1秒後に消滅）
    time += 1.0 / frameRate;
    if (time >= 0.1) killList.add(body);
  }
}
// 爆風の生成
Body spawnBlast(World world, Vec2 pos,
                float radius, boolean isFatal) {
  CircleDef sd = new CircleDef();
  sd.radius = radius;
  sd.isSensor = true;

  BodyDef bd = new BodyDef();
  bd.position = pos;
  bd.userData = new Blast(radius, isFatal);

  Body body = world.createBody(bd);
  body.createShape(sd);
  return body;
}

// 各種ゲーム判定を行うコンタクトリスナー
class GameContactListener implements ContactListener {
  public void add(ContactPoint point) {
    Body body1 = point.shape1.getBody();
    Body body2 = point.shape2.getBody();
    Object ud1 = body1.getUserData();
    Object ud2 = body2.getUserData();
    // 爆風の当たり判定
    if (ud1 instanceof Blast) {
      ((Blast)ud1).overlapSet.add(body2);
    } else if (ud2 instanceof Blast) {
      ((Blast)ud2).overlapSet.add(body1);
    }
  }
  public void persist(ContactPoint point) {}
  public void remove(ContactPoint point) {}
  public void result(ContactResult point) {
    Object ud1 = point.shape1.getBody().getUserData();
    Object ud2 = point.shape2.getBody().getUserData();
    // プレイヤーの接地判定
    float thresh = sin(radians(45)); // 最大登攀角
    if (ud1 instanceof Player) {
      ((Player)ud1).isGrounded |= (point.normal.y < thresh);
    } else if (ud2 instanceof Player) {
      ((Player)ud2).isGrounded |= (point.normal.y > thresh);
    }
  }
}

void setup() {
  size(512, 512);
  colorMode(HSB, 1.0);
  // テキスト描画設定
  textFont(loadFont("Optima-Regular-16.vlw"), 16);
  textAlign(CENTER);
  // ワールドの初期化
  AABB worldAABB = new AABB();
  worldAABB.lowerBound.set(-20, -10);
  worldAABB.upperBound.set(20, 20);
  Vec2 gravity = new Vec2(0, -2.8);
  world = new World(worldAABB, gravity, true);
  world.setContactListener(new GameContactListener());
  // 壁の初期化
  BodyDef wallBD = new BodyDef();
  PolygonDef wallSD = new PolygonDef();
  Body wall = world.createBody(wallBD);
  wallSD.setAsBox(20, 1, new Vec2(0, -1), 0); // 床
  wall.createShape(wallSD);
  wallSD.setAsBox(1, 20, new Vec2(-6, 0), 0); // 左壁
  wall.createShape(wallSD);
  wallSD.setAsBox(1, 20, new Vec2(6, 0), 0);  // 右壁
  wall.createShape(wallSD);
  // 床（固定箱）の初期化
  for (float x = -4.5; x < 5; x += 1) {
    spawnFixedBox(world, new Vec2(x, 1), 0.5, 0.5, color(0.3));
  }
  ground = spawnFixedBox(world, new Vec2(0, 0.25),
                         5, 0.25, color(0.15, 0.6, 1));
  // プレイヤーの初期化
  player = spawnPlayer(world);
}

void draw() {
  smooth();
  noStroke();
  background(1);
  // ワールドの座標系とスクリーン座標系の変換
  pushMatrix();
  translate(width / 2, height);
  scale(width / 10, height / -10);
  // 削除予約リストの初期化
  killList = new HashSet();
  // 箱を2.1秒に1個の確率でランダム生成
  if (random(2.1 * frameRate) < 1) spawnMovableBox(world);
  // 爆弾を3.2秒に1個の確率でランダム生成
  if (random(3.2 * frameRate) < 1) spawnBomb(world);
  // 物理挙動の時間を進める
  world.step(1.0 / frameRate, 8);
  // draw描画メソッドの呼び出し
  for (Body body = world.getBodyList();
       body != null; body = body.getNext()) {
    Object ud = body.getUserData();
    if (ud instanceof Drawable) {
      pushMatrix();
      ((Drawable)ud).draw(body);
      popMatrix();
    }
  }
  // 削除予約リストの処理
  for (Iterator i = killList.iterator(); i.hasNext();) {
    Body body = (Body)i.next();
    if (body == ground) ground = null; // 床破壊判定
    world.destroyBody(body);
  }
  // ゲームオーバー表示
  popMatrix();
  if (ground == null) {
    fill(0);
    text("GAME OVER", width / 2, height / 2);
  }
}
