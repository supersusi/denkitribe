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
      body.applyForce(new Vec2(0, 80), body.getPosition());
    }
    if (keyInLeft) {
      vx = -5.0f;
    } else if (keyInRight) {
      vx = 5.0f;
    }
  
    Vec2 vel = body.getLinearVelocity();
    if (vel.x < vx - 0.8f) {
      body.applyForce(new Vec2(20, 0), body.getPosition());
    } else if (vel.x > vx + 0.8f) {
      body.applyForce(new Vec2(-20, 0), body.getPosition());
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
  sd.density = 3.3f;

  BodyDef bd = new BodyDef();
  bd.position.set(0, 1);
  bd.linearDamping = 0.8f;
  bd.userData = data;

  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
  return body;
}

// Barrier
class BarrierData implements Drawable {
  public float width;
  public float height;
  public BarrierData() {
    width = random(0.3f, 0.6f);
    height = random(0.1f, 0.5f);
  }
  public void draw(Body body) {
    BarrierData data = (BarrierData)body.getUserData();
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    rotate(body.getAngle());
    rect(-data.width, -data.height, data.width * 2, data.height * 2);
  }
}
Body spawnBarrier(World world) {
  BarrierData data = new BarrierData();

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

// Bomb
class BombData implements Drawable {
  public float radius;
  public BombData() {
    radius = 0.3f;
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
    float thresh = 0.6f;
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
  
  player = spawnPlayer(world);
}

void draw() {
  smooth();
  noStroke();
  fill(50);
  background(255);
  translate(width / 2, height);
  scale(width / 10, height / -10);
  
  float dice = random(80);
  if (dice < 1) {
    spawnBarrier(world);
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
}

