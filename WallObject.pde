class WallObject implements IObject {
  float x;  
  float y;
  float w;
  float h;
  float q;
  
  float getX() { return x; };
  float getY() { return y; };
  float getW() { return w; };
  float getH() { return h; };
  float getQ() { return q; };

  WallObject(float x, float y, float w, float h, float q) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
    this.q = q;
  }
  
  void tick() {
  }

  void display() {    
    // draw current state
    noStroke();
    fill(255, 255, 255, 200);    
    rect(x, y, w, h);
  }
}
