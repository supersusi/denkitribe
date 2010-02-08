World world;
Set collisionSet;

class BoxInfo {
  public float m_width;
  public float m_height;
  public BoxInfo(float width, float height) {
    m_width = width;
    m_height = height;
  }
}

class BombInfo {
  public float m_radius;
  public BombInfo(float radius) {
    m_radius = radius;
  }
};

class MyContactListener implements ContactListener {
  public void add(ContactPoint point) {
    Body body1 = point.shape1.getBody();
    Body body2 = point.shape2.getBody();
    Object ud1 = body1.getUserData();
    Object ud2 = body2.getUserData();
    if (ud1 instanceof BombInfo && ud2 instanceof BoxInfo) {
      collisionSet.add(body1);
      collisionSet.add(body2);
      return;
    }
    if (ud2 instanceof BombInfo && ud1 instanceof BoxInfo) {
      collisionSet.add(body1);
      collisionSet.add(body2);
      return;
    }
  }
  public void persist(ContactPoint point) {
  }
  public void remove(ContactPoint point) {
  }
  public void result(ContactResult point) {
  }
}

void spawnBox() {
  float w = random(0.1f, 0.5f);
  float h = random(0.1f, 0.5f);
  
  PolygonDef sd = new PolygonDef();
  sd.setAsBox(w, h);
  sd.density = 1.0f;
  sd.friction = 0.3f;
  
  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10);
  bd.userData = new BoxInfo(w, h);
  
  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
}

void spawnBomb() {
  CircleDef sd = new CircleDef();
  sd.radius = 0.3f;
  sd.density = 1.0f;

  BodyDef bd = new BodyDef();
  bd.position.set(random(-4, 4), 10);
  bd.userData = new BombInfo(sd.radius);
  
  Body body = world.createBody(bd);
  body.createShape(sd);
  body.setMassFromShapes();
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
    world.setContactListener(new MyContactListener());
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
}

void draw() {
  smooth();
  noStroke();
  fill(50);
  background(255);
  translate(width / 2, height);
  scale(width / 10, height / -10);
  
  float dice = random(30);
  if (dice < 1) {
    spawnBox();
  } else if (dice < 2) {
    spawnBomb();
  }
  
  collisionSet = new HashSet();
  world.step(1.0f / frameRate, 4);
  
  for (Iterator it = collisionSet.iterator(); it.hasNext();) {
    world.destroyBody((Body)it.next());
  }
  collisionSet = null;
  
  for (Body body = world.getBodyList(); body != null; body = body.getNext()) {
    Object ud = body.getUserData();
    if (ud == null) continue;

    pushMatrix();
    
    if (ud instanceof BoxInfo) {
      BoxInfo info = (BoxInfo)ud;
      Vec2 pos = body.getPosition();
      translate(pos.x, pos.y);
      rotate(body.getAngle());
      rect(-info.m_width, -info.m_height, 
           info.m_width * 2, info.m_height * 2);
    }
    
    if (ud instanceof BombInfo) {
      BombInfo info = (BombInfo)ud;
      Vec2 pos = body.getPosition();
      translate(pos.x, pos.y);
      ellipse(0, 0, info.m_radius * 2, info.m_radius * 2);
    }
    
    popMatrix();
  }
}

