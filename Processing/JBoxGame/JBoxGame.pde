
World world;

ArrayList boxes;
ArrayList bombs;

class BombInfo {
  public float m_radius;
  
  public BombInfo(float radius) {
    m_radius = radius;
  }
};

class BoxInfo {
  public float m_width;
  public float m_height;
  
  public BoxInfo(float w, float h) {
    m_width = w;
    m_height = h;
  }
}

class MyContactListener implements ContactListener {
  public void add(ContactPoint point) {
    Object ud1 = point.shape1.getBody().getUserData();
    Object ud2 = point.shape2.getBody().getUserData();
    if (ud1 instanceof BombInfo && ud2 instanceof BoxInfo) {
      println("1 >> 2");
      return;
    }
    if (ud2 instanceof BombInfo && ud1 instanceof BoxInfo) {
      println("2 >> 1");
      return;
    }
    println("not!!");
  }
  public void persist(ContactPoint point) {
  }
  public void remove(ContactPoint point) {
  }
  public void result(ContactResult point) {
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
    Vec2 gravity = new Vec2(0.0f, -9.8f);
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

  // Boxes
  boxes = new ArrayList();
  {
    for (int i = 0; i < 100; ++i) {
      float w = random(0.1f, 0.5f);
      float h = random(0.1f, 0.5f);
      
      PolygonDef sd = new PolygonDef();
      sd.setAsBox(w, h);
      sd.density = 1.0f;
      sd.friction = 0.3f;
      
      BodyDef bd = new BodyDef();
      bd.position.set(random(-4, 4), random(5, 20));
      bd.userData = new BoxInfo(w, h);
      
      Body body = world.createBody(bd);
      body.createShape(sd);
      body.setMassFromShapes();
      boxes.add(body);
    }
  }
  
  // Boxes
  bombs = new ArrayList();
  {
    CircleDef sd = new CircleDef();
    sd.radius = 0.3f;
    sd.density = 1.0f;
    
    for (int i = 0; i < 20; ++i) {
      BodyDef bd = new BodyDef();
      bd.position.set(random(-4, 4), random(5, 20));
      bd.userData = new BombInfo(sd.radius);
      
      Body body = world.createBody(bd);
      body.createShape(sd);
      body.setMassFromShapes();
      bombs.add(body);
    }
  }

}

void draw() {
  smooth();
  noStroke();
  fill(50);
  background(255);
  world.step(1.0f / frameRate, 4);
  translate(width / 2, height);
  scale(width / 10, height / -10);
  
  // Boxes
  for (int i = 0; i < boxes.size(); ++i) {
    Body body = (Body)boxes.get(i);
    BoxInfo info = (BoxInfo)body.getUserData();
    pushMatrix();
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    rotate(body.getAngle());
    rect(-info.m_width, -info.m_height, 
         info.m_width * 2, info.m_height * 2);
    popMatrix();
  }
  
  // Bombs
  for (int i = 0; i < bombs.size(); ++i) {
    Body body = (Body)bombs.get(i);
    BombInfo info = (BombInfo)body.getUserData();
    pushMatrix();
    Vec2 pos = body.getPosition();
    translate(pos.x, pos.y);
    ellipse(0, 0, info.m_radius * 2, info.m_radius * 2);
    popMatrix();
  }
}

