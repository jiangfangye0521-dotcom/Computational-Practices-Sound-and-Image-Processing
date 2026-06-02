//UAL Creative Computing Institute
//Computational Practices: Sound and Image Processing
//Week 9: Vectors, Forces and Autonomous Movement - "CYPHER: Void Escape"

int gameState = 0; 
int score = 0;

Player spaceship;
VoidWorm monster;
ArrayList<GravityAnomaly> anomalies;
ArrayList<EnergyCore> cores;

void setup() {
  size(800, 800);
  frameRate(60);
  smooth(8);
  resetGame();
}

void draw() {
  // 绘制深空黑曜石背景与粒子微尘
  background(13, 13, 26);
  drawSpaceDust();
  
  if (gameState == 0) {
    drawStartScreen();
  } 
  else if (gameState == 1) {
    runGameLogic();
  } 
  else if (gameState == 2) {
    drawGameOverScreen();
  }
}

void resetGame() {
  score = 0;
  spaceship = new Player(width / 2.0, height / 2.0 + 150);
  monster = new VoidWorm(100, 100, 18); 
  
  anomalies = new ArrayList<GravityAnomaly>();
  for (int i = 0; i < 3; i++) {
    anomalies.add(new GravityAnomaly(random(100, width - 100), random(100, height - 300), random(15, 35)));
  }
  
  cores = new ArrayList<EnergyCore>();
  for (int i = 0; i < 4; i++) {
    cores.add(new EnergyCore());
  }
}

void runGameLogic() {
  
  for (GravityAnomaly ga : anomalies) {
    ga.update();
    ga.display();

    PVector gravityForce = ga.calculateGravity(spaceship);
    spaceship.applyForce(gravityForce);
    
    if (PVector.dist(spaceship.position, ga.position) < ga.radius + 15) {
      spaceship.shield -= 0.8;

      PVector repel = PVector.sub(spaceship.position, ga.position).normalize().mult(0.8);
      spaceship.applyForce(repel);
    }
  }
  

  // Formula: F_drag = -c * ||v|| * v
  float c = 0.15; 
  PVector drag = spaceship.velocity.copy();
  drag.normalize();
  drag.mult(-c * spaceship.velocity.magSq()); 
  spaceship.applyForce(drag);
  
  // (Engine Thrust)
  if (mousePressed) {
    PVector mouseVec = new PVector(mouseX, mouseY);
    PVector thrust = PVector.sub(mouseVec, spaceship.position);
    thrust.normalize();
    thrust.mult(0.45); 
    spaceship.applyForce(thrust);
    
    stroke(0, 242, 254, 100);
    strokeWeight(1.5);
    line(spaceship.position.x, spaceship.position.y, mouseX, mouseY);
  }
  
  spaceship.update();
  spaceship.display();
  
  monster.update(spaceship.position);
  monster.display();
  
  if (PVector.dist(spaceship.position, monster.segments[0]) < 28) {
    spaceship.shield -= 1.5;
  
    PVector knockback = PVector.sub(spaceship.position, monster.segments[0]).normalize().mult(5);
    spaceship.velocity.add(knockback);
  }
  
  for (int i = cores.size() - 1; i >= 0; i--) {
    EnergyCore core = cores.get(i);
    core.display();
    
    if (PVector.dist(spaceship.position, core.position) < 22) {
      score += 100;
      spaceship.shield = min(100, spaceship.shield + 15); 
      cores.remove(i);
      cores.add(new EnergyCore());
    }
  }
  
  if (spaceship.shield <= 0) {
    gameState = 2;
  }
  drawHUD();
}

void drawSpaceDust() {
  stroke(255, 40);
  for (int i = 0; i < 20; i++) {
    float x = (noise(i, frameCount * 0.002) * width);
    float y = (noise(i + 10, frameCount * 0.002) * height);
    strokeWeight(noise(i) * 3);
    point(x, y);
  }
}

void drawStartScreen() {
  textAlign(CENTER, CENTER);
  
  fill(0, 242, 254);
  textSize(32);
  text("CYPHER // 虚空逃逸系统", width/2, height/2 - 80);
  
  fill(255, 180);
  textSize(14);
  text("物理交互与自主运动矢量游戏", width/2, height/2 - 40);
  
  fill(120);
  textSize(11);
  text("【物理引擎特征】：万有引力场 | 空气粘滞阻力 | 欧拉半隐式积分", width/2, height/2 - 10);
  
  // 玩法提示
  fill(223, 255, 0);
  textSize(13);
  text("长按【鼠标左键】激活引擎反冲，避开巨兽与紫色重力异常，收集莹绿核心", width/2, height/2 + 60);
  
  fill(255, 150);
  rectMode(CENTER);
  noFill();
  stroke(0, 242, 254);
  rect(width/2, height/2 + 130, 180, 40, 5);
  fill(0, 242, 254);
  text("点击鼠标开始逃生", width/2, height/2 + 134);
  
  if (mousePressed && gameState == 0) {
    gameState = 1;
  }
}

void drawGameOverScreen() {
  textAlign(CENTER, CENTER);
  
  fill(230, 50, 50);
  textSize(36);
  text("飞船护盾已瓦解", width/2, height/2 - 60);
  
  fill(255);
  textSize(16);
  text("逃逸得分: " + score, width/2, height/2 - 10);
  
  fill(120);
  text("虚空巨兽吞噬了你的能量矩阵...", width/2, height/2 + 20);
  
  fill(223, 255, 0);
  textSize(12);
  text("按下键盘 [ R ] 键重新装载逃逸舱", width/2, height/2 + 80);
}

void drawHUD() {
  rectMode(CORNER);
  
  fill(15, 15, 25, 200);
  noStroke();
  rect(15, 15, 300, 85, 6);
  stroke(0, 242, 254, 100);
  strokeWeight(1);
  rect(15, 15, 300, 85, 6);
  
  fill(255);
  textSize(11);
  text("护盾能级 (SHIELD LIFE)", 25, 36);
  
  noFill();
  stroke(255, 40);
  rect(25, 45, 150, 10, 3);
  
  color shieldColor = lerpColor(color(230, 50, 50), color(0, 255, 150), spaceship.shield / 100.0);
  fill(shieldColor);
  noStroke();
  rect(26, 46, map(spaceship.shield, 0, 100, 0, 148), 8, 2);
  
  fill(shieldColor);
  text(int(spaceship.shield) + "%", 185, 54);
  
  fill(255);
  text("核心分数: " + score, 25, 80);
}

void keyPressed() {
  if ((key == 'r' || key == 'R')) {
    resetGame();
    gameState = 1;
  }
}

class Player {
  PVector position;
  PVector velocity;
  PVector acceleration;
  
  float mass = 12.0; 
  float shield = 100.0; 
  float size = 18.0;
  
  Player(float x, float y) {
    position = new PVector(x, y);
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, 0);
  }
  
  void applyForce(PVector force) {
    PVector f = PVector.div(force, mass);
    acceleration.add(f);
  }
  
  void update() {
    velocity.add(acceleration);
    position.add(velocity);
    
    checkEdges();

    acceleration.mult(0);
  }
  
  void display() {
    pushMatrix();
    translate(position.x, position.y);
    
    float heading = velocity.heading() + HALF_PI;
    rotate(heading);
    
    if (mousePressed) {
      fill(223, 255, 0, random(150, 255));
      noStroke();
      triangle(-4, 10, 4, 10, 0, 10 + random(10, 25));
    }
    
    stroke(0, 242, 254);
    strokeWeight(1.8);
    fill(13, 13, 26);
    beginShape();
    vertex(0, -size);
    vertex(size * 0.8, size);
    vertex(0, size * 0.4);
    vertex(-size * 0.8, size);
    endShape(CLOSE);
    
    noFill();
    stroke(0, 242, 254, map(shield, 0, 100, 20, 100));
    ellipse(0, 0, size * 2.5, size * 2.5);
    
    popMatrix();
  }
  
  void checkEdges() {
    float bounceCoeff = -0.65; 
    
    if (position.x < size) {
      position.x = size;
      velocity.x *= bounceCoeff;
    } else if (position.x > width - size) {
      position.x = width - size;
      velocity.x *= bounceCoeff;
    }
    
    if (position.y < size) {
      position.y = size;
      velocity.y *= bounceCoeff;
    } else if (position.y > height - size) {
      position.y = height - size;
      velocity.y *= bounceCoeff;
    }
  }
}

class VoidWorm {
  PVector[] segments;
  int numSegments;
  float segmentDist = 16.0; 
  
  PVector position; 
  PVector velocity;
  PVector acceleration;
  float maxSpeed = 3.6;   
  float maxForce = 0.08;  
  
  VoidWorm(float x, float y, int n) {
    numSegments = n;
    segments = new PVector[numSegments];
    for (int i = 0; i < numSegments; i++) {
      segments[i] = new PVector(x, y + i * segmentDist);
    }
    
    position = segments[0];
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, 0);
  }
  
  void update(PVector target) {
 
    PVector desired = PVector.sub(target, position);
    desired.normalize();
    desired.mult(maxSpeed);
    
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxForce); 
    acceleration.add(steer);
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);
    
    acceleration.mult(0); 
  
    for (int i = 1; i < numSegments; i++) {
      PVector prev = segments[i - 1];
      PVector current = segments[i];
      
      PVector dir = PVector.sub(current, prev);
      dir.normalize();
      dir.mult(segmentDist);
      
      segments[i] = PVector.add(prev, dir);
    }
  }
  
  void display() {
  
    stroke(75, 0, 130, 120);
    strokeWeight(12);
    noFill();
    beginShape();
    for (int i = 0; i < numSegments; i++) {
      vertex(segments[i].x, segments[i].y);
    }
    endShape();

    for (int i = numSegments - 1; i > 0; i--) {
  
      float size = map(i, 0, numSegments, 22, 6);
      
      fill(13, 13, 26);
      stroke(180, 80, 255, map(i, 0, numSegments, 255, 50));
      strokeWeight(1.8);
      
      ellipse(segments[i].x, segments[i].y, size, size);
      
      if (i % 2 == 0) {
        fill(230, 50, 50, 150);
        ellipse(segments[i].x + 3, segments[i].y + 3, 3, 3);
      }
    }
    
    fill(24, 15, 8);
    stroke(230, 50, 50);
    strokeWeight(2.5);
    ellipse(position.x, position.y, 28, 28);
    
    fill(223, 255, 0);
    noStroke();
    ellipse(position.x - 6, position.y - 4, 5, 5);
    ellipse(position.x + 6, position.y - 4, 5, 5);
  }
}

class GravityAnomaly {
  PVector position;
  float radius;
  float pulseOffset = 0.0;
  float gConstant = 12.0;
  
  GravityAnomaly(float x, float y, float r) {
    position = new PVector(x, y);
    radius = r;
    pulseOffset = random(100);
  }
  
  PVector calculateGravity(Player p) {
    PVector force = PVector.sub(position, p.position);
    float distance = force.mag();
    
    distance = constrain(distance, 20.0, 300.0);
    
    force.normalize();
    
    // Formula: F = (G * m1 * m2) / d^2
    float strength = (gConstant * p.mass) / (distance * distance);
    force.mult(strength);
    return force;
  }
  
  void update() {
    position.x += (noise(frameCount * 0.005 + pulseOffset) - 0.5) * 1.2;
    position.y += (noise(frameCount * 0.005 + pulseOffset + 50) - 0.5) * 1.2;
  }
  
  void display() {
    pushMatrix();
    translate(position.x, position.y);
    
    float pulse = sin(frameCount * 0.05 + pulseOffset) * 6;
    
    noFill();
    for (int i = 1; i < 4; i++) {
      stroke(180, 80, 255, 120 / i);
      strokeWeight(1.2);
      ellipse(0, 0, (radius * 2 * i) + pulse * i * 0.5, (radius * 2 * i) + pulse * i * 0.5);
    }
    
    // 奇点核心
    fill(20, 10, 35);
    stroke(180, 80, 255);
    strokeWeight(2.5);
    ellipse(0, 0, radius, radius);
    
    popMatrix();
  }
}

class EnergyCore {
  PVector position;
  float pulseAngle;
  
  EnergyCore() {

    position = new PVector(random(50, width - 50), random(50, height - 100));
    pulseAngle = random(TWO_PI);
  }
  
  void display() {
    pushMatrix();
    translate(position.x, position.y);
    
    pulseAngle += 0.05;
    float pulse = sin(pulseAngle) * 4;
    
    noFill();
    stroke(0, 255, 150, 150);
    strokeWeight(1.5);
    ellipse(0, 0, 18 + pulse, 18 + pulse);
    
    fill(223, 255, 0);
    noStroke();
    rectMode(CENTER);
    pushMatrix();
    rotate(pulseAngle * 0.5);
    rect(0, 0, 8, 8);
    popMatrix();
    
    popMatrix();
  }
}
