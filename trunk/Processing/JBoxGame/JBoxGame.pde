// Key inputs
boolean keyInLeft;
boolean keyInRight;
boolean keyInUp;
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

// Interfaces
interface Updatable {
  abstract void update(Body body);
}
interface Drawable {
  abstract void draw(Body body);
}

// Kill list
Set killList;

// Player
class PlayerData implements Updatable, Drawable {
  public float radius;
  public boolean touchGround;
  public PlayerData() {
    radius = 0.3f;
  }
  public void update(Body body) {
    body.applyForce(new Vec2(0, -10), body.getPosition());
  
    PlayerData data = (PlayerData)body.getUserData();
    if (!data.touchGround) return;
    
    float vx = 0;
    
    if (keyInUp) {
      body.applyForce(new Vec2(0, 70), body.getPosition());
    }
    if (keyInLeft) {
      vx = -5.0f;
    } else if (keyInRight) {
      vx = 5.0f;
    }
  
    Vec2 vel = body.getLinearVelocity();
    if (vel.x < vx - 0.8f) {
      body.applyForce(new Vec2(10, 0), body.getPosition());
    } else if (vel.x > vx + 0.8f) {
      body.applyForce(new Vec2(-10, 0), body.getPosition());
    }
    
    data.touchGround = false;
  }
  public void draw(Body body) {
    PlayerData data = (PlayerData)body.getUserData();
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    ellipse(0, 0, data.radius * 2, data.radius * 2);
  }
}
Body spawnPlayer(World world) {
  PlayerData data = new PlayerData();

  CircleDef sd = new CircleDef();
  sd.radius = data.radius;
  sd.density = 1.5f;

  BodyDef bd = new BodyDef();
  bd.position.set(0, 1);
  bd.linearDamping = 0.8f;
  bd.userData = data;

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

// Block
class BlockData implements Drawable {
  public float width;
  public float height;
  public BlockData() {
    width = random(0.3f, 0.6f);
    height = random(0.1f, 0.5f);
  }
  public BlockData(float width_, float height_) {
    width = width_;
    height = height_;
  }
  public void draw(Body body) {
    BlockData data = (BlockData)body.getUserData();
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    rotate(body.getAngle());
    rect(-data.width, -data.height, data.width * 2, data.height * 2);
  }
}
Body spawnBlock(World world) {
  BlockData data = new BlockData();

  PolygonDef sd = new PolygonDef();
  sd.setAsBox(data.width, data.height);
  sd.density = 1.0f;
  sd.friction = 0.3f;

  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10);
  bd.userData = data;

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}
Body spawnFixedBlock(World world, Vec2 pos) {
  BlockData data = new BlockData(0.25f, 0.25f);

  PolygonDef sd = new PolygonDef();
  sd.setAsBox(data.width, data.height);
  sd.density = 100.0f;

  BodyDef bd = new BodyDef();
  bd.position = pos;
  bd.userData = data;

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

// Blast
class BlastData implements Updatable, Drawable {
  public float radius;
  public Set collideeSet;
  public BlastData() {
    radius = 3.0f;
    collideeSet = new HashSet();
  }
  public void update(Body body) {
    for (Iterator i = collideeSet.iterator(); i.hasNext();) {
      Body collidee = (Body)i.next();
      Vec2 vec = collidee.getPosition().sub(body.getPosition());
      float dist = vec.normalize();
      if (dist < 2.0f && collidee.getUserData() instanceof BlockData) {
        killList.add(collidee);
      } else {
        vec.mulLocal(75);
        collidee.applyForce(vec, collidee.getPosition());
      }
    }
    killList.add(body);
  }
  public void draw(Body body) {
    BlastData data = (BlastData)body.getUserData();
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    ellipse(0, 0, data.radius * 2, data.radius * 2);
  }
}
Body spawnBlast(World world, Vec2 pos) {
  BlastData data = new BlastData();

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

// Bomb
class BombData implements Updatable, Drawable {
  public float radius;
  public float life;
  public BombData() {
    radius = 0.3f;
    life = 3.2f;
  }
  public void update(Body body) {
    life -= 1.0f / frameRate;
    if (life <= 0) {
      spawnBlast(body.getWorld(), body.getPosition());
      killList.add(body);
    }
  }
  public void draw(Body body) {
    BombData data = (BombData)body.getUserData();
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    ellipse(0, 0, data.radius * 2, data.radius * 2);
  }
}
Body spawnBomb(World world) {
  BombData data = new BombData();

  CircleDef sd = new CircleDef();
  sd.radius = data.radius;
  sd.density = 1.0f;
  sd.restitution = 0.3f;

  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10);
  bd.userData = data;

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

World world;
Body player;

class GlobalContactListener implements ContactListener {
  public void add(ContactPoint point) {
    Object ud1 = point.shape1.getBody().getUserData();
    Object ud2 = point.shape2.getBody().getUserData();
    if (ud1 instanceof BlastData) {
      ((BlastData)ud1).collideeSet.add(point.shape2.getBody());
    }
    if (ud2 instanceof BlastData) {
      ((BlastData)ud2).collideeSet.add(point.shape1.getBody());
    }
  }
  public void persist(ContactPoint point) {
    Object ud1 = point.shape1.getBody().getUserData();
    Object ud2 = point.shape2.getBody().getUserData();
    if (ud1 instanceof PlayerData) {
      if (ud2 instanceof BombData) {
        point.shape2.getBody().applyForce(new Vec2(0, 50), point.shape2.getBody().getPosition());
      }
    }
    if (ud2 instanceof PlayerData) {
      if (ud1 instanceof BombData) {
        point.shape1.getBody().applyForce(new Vec2(0, 50), point.shape1.getBody().getPosition());
      }
    }
  }
  public void remove(ContactPoint point) {
  }
  public void result(ContactResult point) {
    Object ud1 = point.shape1.getBody().getUserData();
    Object ud2 = point.shape2.getBody().getUserData();
    float thresh = 0.8f;
    if (ud1 instanceof PlayerData) {
      ((PlayerData)ud1).touchGround |= (point.normal.y < thresh);
    } else if (ud2 instanceof PlayerData) {
      ((PlayerData)ud2).touchGround |= (point.normal.y > thresh);
    }
  }
}

void setup() {
  size(512, 512);
  frameRate(30);

  // World
  {
    AABB worldAABB = new AABB();
    worldAABB.lowerBound.set(-20.0f, -10.0f);
    worldAABB.upperBound.set(+20.0f, +20.0f);
    Vec2 gravity = new Vec2(0.0f, -2.8f);
    world = new World(worldAABB, gravity, true);
    world.setContactListener(new GlobalContactListener());
  }

  // World border
  {
    BodyDef bd = new BodyDef();
    bd.position.set(0.0f, 0.0f);
    
    Body ground = world.createBody(bd);
    
    PolygonDef sd = new PolygonDef();
    sd.setAsBox(20.0f, 1.0f, new Vec2(0, -1), 0);
    ground.createShape(sd);

    sd = new PolygonDef();
    sd.setAsBox(1.0f, 20.0f, new Vec2(-6, 0), 0);
    ground.createShape(sd);

    sd = new PolygonDef();
    sd.setAsBox(1.0f, 20.0f, new Vec2(6, 0), 0);
    ground.createShape(sd);
  }
  
  for (float x = -4.75f; x < 5.0f; x += 0.5f) {
    spawnFixedBlock(world, new Vec2(x, 0.25f));
  }
  
  player = spawnPlayer(world);
}

void draw() {
  smooth();
  noStroke();
  fill(50);
  background(255);
  translate(width / 2, height);
  scale(width / 10, height / -10);
  
  killList = new HashSet();
  
  float dice = random(80);
  if (dice < 1) {
    spawnBlock(world);
  } else if (dice < 2) {
    spawnBomb(world);
  }

  for (Body body = world.getBodyList(); body != null; body = body.getNext()) {
    Object ud = body.getUserData();
    if (ud instanceof Updatable) ((Updatable)ud).update(body);
  }

  world.step(1.0f / frameRate, 4);

  for (Body body = world.getBodyList(); body != null; body = body.getNext()) {
    Object ud = body.getUserData();
    if (ud instanceof Drawable) {
      pushMatrix();
      ((Drawable)ud).draw(body);
      popMatrix();
    }
  }
  
  for (Iterator i = killList.iterator(); i.hasNext();) {
    world.destroyBody((Body)i.next());
  }
}

