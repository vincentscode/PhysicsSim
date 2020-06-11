// setup
final int graphicsFramerate = 120;
final int physicsFramerate = 120;
final int physicsResolutionFactor = 240;
final int physicsObjectResolution = 1;

final int maxTrailCount = 256;

boolean drawForcesEnabled = false;
boolean drawTailEnabled = false;
boolean drawGlobalFieldEnabled = false;

float physicsFrameCount = 0;
float physicsFrameCountOffset = 0;

// physics
ArrayList<IObject> physicsObjects;

// physics consts
final float g = 0; // 9.81;
final float E0 = 8.85 * pow(10, -12);

// display
PFont f;

void reset() {
  physicsFrameCountOffset += physicsFrameCount;
  physicsObjects = new ArrayList<IObject>();

  //physicsObjects.add(new WallObject(
  //  // x / y / w / h
  //  width/2-10, 
  //  height/2, 
  //  20, 
  //  1, 
  //  0.01
  //));
  //physicsObjects.add(new WallObject(
  //  // x / y / w / h
  //  width/2-10, 
  //  height/2+200, 
  //  20, 
  //  1, 
  //  -0.01
  //));
    
    physicsObjects.add(new PointObject(
      // x / y
      width/2-100, 
      height/2, 
      // mass
      10, 
      // q
      0.1,
      // color
      color(random(0, 255), random(0, 255), random(0, 255)), 
      0,
      true
    ));
    
    physicsObjects.add(new PointObject(
      // x / y
      width/2+100, 
      height/2, 
      // mass
      10, 
      // q
      -0.1,
      // color
      color(random(0, 255), random(0, 255), random(0, 255)), 
      0,
      true
    ));

  for (int x = width/2-400; x < width/2+400; x += 20) {
    for (int y = height/2-400; y < height/2+400; y += 20) {
      physicsObjects.add(new PointObject(
        // x / y
        x, y,
        // mass
        10, 
        // q
        0.001, 
        // color
        color(random(0, 255), random(0, 255), random(0, 255)), 
        0,
        false
      ));
    }
  }

  // borders
  //physicsObjects.add(new WallObject(
  //  0, 0, 10, height,
  //  0.01
  //));
  //physicsObjects.add(new WallObject(
  //  width-10, 0, 10, height,
  //  0.01
  //));
}

boolean paused = false;
float physicsFrameAtPause;
void togglePause() {
  if (paused) {
    paused = false;
    physicsFrameCountOffset += physicsFrameCount - physicsFrameAtPause;
  } else {
    paused = true;
    physicsFrameAtPause = physicsFrameCount;
  }
}

void setup() {
  size(1000, 750);

  frameRate(graphicsFramerate);
  f = createFont("Arial", 16, true);
  textFont(f, 24);
  textAlign(LEFT);

  reset();
  togglePause();
}

void draw() {
  background(0);
  fill(255);
  text(frameRate, 10, 10+24);

  scale(1, -1);
  translate(0, -height);

  stroke(255, 0, 0);

  physicsFrameCount = (frameCount / ((float) graphicsFramerate / physicsFramerate)) - physicsFrameCountOffset;
  if (!paused && frameCount % ((float) graphicsFramerate / physicsFramerate) == 0) {
    //println("physicFrame");
    for (IObject obj : physicsObjects) {
      //println(" - tick", obj);
      obj.tick();
    }
  }

  for (IObject obj : physicsObjects) {
    obj.display();
  }

  if (drawGlobalFieldEnabled) {
    int step = width / 55;
    float drawingFactor = 1;
    float q = 0.001;
    strokeWeight(1);
    stroke(255, 0, 0);
    fill(255, 0, 0) ;
    for (int ix = step; ix < width; ix += step) {
      for (int iy = step; iy < height; iy += step) {
        ellipse(ix, iy, 2, 2);
        
        // interaction
        ArrayList<PVector> forceVectors = new ArrayList<PVector>();
        for (IObject obj : physicsObjects) {
          if (obj.getW() == 0) {
            // calculate correlation
            float dist = distance(ix, iy, obj.getX(), obj.getY());
            float ang = angle(ix, iy, obj.getX(), obj.getY());
            
            // electrical field
            float fcoul = (1 / (4 * PI * E0)) * ((q * (obj.getQ())) / pow(dist, 2));
            PVector fcoulv = new PVector(0, fcoul).rotate(radians(-ang));
            forceVectors.add(fcoulv);
          } else {
            for (int xItr = 0; xItr < obj.getW() / physicsObjectResolution; xItr += physicsObjectResolution) {
              PVector objPos = new PVector(obj.getX()+xItr, obj.getY());
              
              // calculate correlation
              float dist = distance(ix, iy, objPos.x, objPos.y);
              float ang = angle(ix, iy, objPos.x, objPos.y);
              // println(x, y, "|", objPos.x, objPos.y, "=>",  ang);
              
              // electrical field
              float fcoul = (1 / (4 * PI * E0)) * ((q * (obj.getQ() / (obj.getW() / physicsObjectResolution))) / pow(dist, 2));
              PVector fcoulv = new PVector(0, fcoul).rotate(radians(-ang));
              forceVectors.add(fcoulv);
            }
          }
        }
        
        // calculate result vector
        PVector forceVectorResult = new PVector(0, 0, 0);
        for (PVector f : forceVectors) {
          forceVectorResult.add(f);
        }
        line(ix, iy, ix + (forceVectorResult.x)*drawingFactor, iy + (forceVectorResult.y)*drawingFactor);        
      }
    }
  }

  stroke(255, 255, 255, 40);
  strokeWeight(1);
  if (paused) {
    line(physicsFrameAtPause*20 % width, 0, physicsFrameAtPause*20 % width, height);
  } else {
    line(physicsFrameCount*20 % width, 0, physicsFrameCount*20 % width, height);
  }
}

void keyPressed() {
  if (keyCode == java.awt.event.KeyEvent.VK_F1) {
    drawForcesEnabled = !drawForcesEnabled;
  }
  if (keyCode == java.awt.event.KeyEvent.VK_F2) {
    drawTailEnabled = !drawTailEnabled;
  }
  if (keyCode == java.awt.event.KeyEvent.VK_F3) {
    drawGlobalFieldEnabled = !drawGlobalFieldEnabled;
  }
  if (keyCode == java.awt.event.KeyEvent.VK_F5) {
    reset();
  }
  if (keyCode == java.awt.event.KeyEvent.VK_SPACE) {
    togglePause();
  }
}

void mouseMoved() {
  // println("mouseMoved:", mouseX, "|", mouseY);
}

void mousePressed() {
  // println("mousePressed:", mouseX, "|", mouseY);

  float offset;
  if (paused) {
    offset = physicsFrameAtPause;
  } else {
    offset = physicsFrameCount;
  }

  physicsObjects.add(new PointObject(
    // x / y
    mouseX, height-mouseY, 
    // mass
    10, 
    // q
    0.001, 
    // color
    color(random(0, 255), random(0, 255), random(0, 255)), 
    offset,
    false
    ));
}
