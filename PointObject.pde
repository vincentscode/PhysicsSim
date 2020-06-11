float distance(float x1, float y1, float x2, float y2) {
  float deltaX = y1 - y2;
  float deltaY = x1 - x2;
  float result = sqrt(deltaX*deltaX + deltaY*deltaY);
  return result; 
}

float angle(float x1, float y1, float x2, float y2) {
  float deltaX = y1 - y2;
  float deltaY = x1 - x2;
    float angle = degrees(atan2(deltaY, deltaX));

    if (angle < 0) {
        angle += 360;
    }

    return angle;
}

float projectionFactor(float sx1, float sy1, float sx2, float sy2, float px, float py) {
  if (px == sx1 && py == sy1) return 0.0;
  if (px == sx2 && py == sy2) return 1.0;
  float dx = sx2 - sx1;
  float dy = sy2 - sy1;
  float len = dx * dx + dy * dy;
  
  // handle zero-length segments
  if (len <= 0.0) return Float.NaN;
  
  float r = ( (px - sx1) * dx + (py - sy1) * dy ) / len;
  return r;
}


PVector project(float sx1, float sy1, float sx2, float sy2, float px, float py) {
  if ((px == sx1 && py == sy1) || (px == sx2 && py == sy2)) return new PVector(px, py);

  float r = projectionFactor(sx1, sy1, sx2, sy2, px, py);
  PVector coord = new PVector();
  coord.x = sx1 + r * (sx2 - sx1);
  coord.y = sy1 + r * (sy2 - sy1);
  return coord;
}

PVector closestPointOnLine(float sx1, float sy1, float sx2, float sy2, float px, float py) {
    double factor = projectionFactor(sx1, sy1, sx2, sy2, px, py);
    if (factor > 0 && factor < 1) {
      return project(sx1, sy1, sx2, sy2, px, py);
    }
    double dist0 = distance(sx1, sy1, px, py);
    double dist1 = distance(sx2, sy2, px, py);
    if (dist0 < dist1) return new PVector(sx1, sy1);
    return new PVector(sx2, sy2);
}


class PointObject implements IObject {
  float x;  
  float y;

  float mass;
  float q;
  
  boolean imovable = false;
  
  float getX() { return x; };
  float getY() { return y; };
  float getW() { return 0; };
  float getH() { return 0; };
  float getQ() { return q; };
  
  float x0;
  float y0;
  boolean drawingInvalidated = false;
  float toffset;
  color col;
  
  ArrayList<PVector> forceVectors = new ArrayList<PVector>();
  PVector forceVectorResult;

  PointObject(float initialX, float initialY, float initialMass, float initialQ, color c, float toffset, boolean imovable) {
    this.x0 = initialX;
    this.y0 = initialY;
    this.x = initialX;
    this.y = initialY;
    this.mass = initialMass;
    this.q = initialQ;
    this.toffset = toffset;
    this.col = c;
    this.imovable = imovable;
  }
  
  void tick() {
    if (this.imovable) {
      return;
    }
    float localFrameCount = physicsFrameCount - toffset + physicsResolutionFactor;
    localFrameCount /= physicsResolutionFactor;
    if (localFrameCount < 1) {
      drawingInvalidated = true;
      return;
    }
    forceVectors.clear();
  
    // gravity
    float fg = - (mass * g);
    PVector fgv = new PVector(0, fg);
    forceVectors.add(fgv);
    
    // interaction
    for (IObject obj : physicsObjects) {
      if (obj == this) continue;
      
      // TODO: use integration
      if (obj.getW() == 0) {
        // calculate correlation
        float dist = distance(x, y, obj.getX(), obj.getY());
        float ang = angle(x, y, obj.getX(), obj.getY());
        
        // electrical field
        float fcoul = (1 / (4 * PI * E0)) * ((q * (obj.getQ())) / pow(dist, 2));
        PVector fcoulv = new PVector(0, fcoul).rotate(radians(-ang));
        forceVectors.add(fcoulv);
      } else {
        for (int xItr = 0; xItr < obj.getW() / physicsObjectResolution; xItr += physicsObjectResolution) {
          PVector objPos = new PVector(obj.getX()+xItr, obj.getY());
          
          // calculate correlation
          float dist = distance(x, y, objPos.x, objPos.y);
          float ang = angle(x, y, objPos.x, objPos.y);
          // println(x, y, "|", objPos.x, objPos.y, "=>",  ang);
          
          // electrical field
          float fcoul = (1 / (4 * PI * E0)) * ((q * (obj.getQ() / (obj.getW() / physicsObjectResolution))) / pow(dist, 2));
          PVector fcoulv = new PVector(0, fcoul).rotate(radians(-ang));
          forceVectors.add(fcoulv);
        }
      }
    }
    
    // calculate result vector
    forceVectorResult = new PVector(0, 0, 0);
    for (PVector f : forceVectors) {
      forceVectorResult.add(f);
    }
   
    // apply transformation
    float deltaSx = (0.5 * forceVectorResult.x / mass * pow(localFrameCount, 2)) - (0.5 * forceVectorResult.x / mass * pow(localFrameCount-1, 2));
    float deltaSy = (0.5 * forceVectorResult.y / mass * pow(localFrameCount, 2)) - (0.5 * forceVectorResult.y / mass * pow(localFrameCount-1, 2));
    
    x += deltaSx;
    y += deltaSy;
    
    
    // deactivate if error
    if (Float.isNaN(y) || Float.isNaN(x)) {
      this.x = random(0, width);
      this.y = random(0, height);
    }

    
    // boundaries
    //if (y <= (0.5 * shapeSize)) y = 0;
    //if (x <= (0.5 * shapeSize)) x = 0;
    //if (y >= height - (0.5 * shapeSize)) y = height;
    //if (x >= width - (0.5 * shapeSize)) x = width;
    
    // invalidate drawing
    drawingInvalidated = true;
  }

  int currentShapeIdx = 0;
  float[] shapeX = new float[maxTrailCount];
  float[] shapeY = new float[maxTrailCount];
  float[] shapeA = new float[maxTrailCount];
  int shapeSize = 2;
  void display() { //<>//
    if (imovable) {
      noStroke();
      fill(col, 200);
      ellipse(x, y, shapeSize, shapeSize);
      return;
    }
    
    // add to trail
    if (drawingInvalidated) {
      shapeX[currentShapeIdx] = x;
      shapeY[currentShapeIdx] = y;
      shapeA[currentShapeIdx] = 255;
    }
    
    // draw current state
    noStroke();
    fill(col, 200);
    ellipse(x, y, shapeSize, shapeSize);
    
    // draw forces
    if (forceVectors.size() > 0 && drawForcesEnabled) {
      float drawingFactor = pow(10, 3);
      
      stroke(col, 60);
      strokeWeight(1);
      for (PVector f : forceVectors) {
        line(x, y, x + (f.x)*drawingFactor, y + (f.y)*drawingFactor);
      }
      
      strokeWeight(10);
      line(x, y, x + (forceVectorResult.x)*drawingFactor, y + (forceVectorResult.y)*drawingFactor);
    }

    // draw + draw tail
    if (drawTailEnabled) {
      for (int i = 0; i < maxTrailCount; i++) {
        // draw circle
        noStroke();
        fill(col, shapeA[i]);
        ellipse(shapeX[i], shapeY[i], shapeSize, shapeSize);
  
        // fade out trail
        if (drawingInvalidated) {
          shapeA[i] -= 255 / maxTrailCount;
        }
      }
    }

    // update trail index
    if (drawingInvalidated) {
      currentShapeIdx++;
      currentShapeIdx %= maxTrailCount;
    }

    drawingInvalidated = false;
  }
}
