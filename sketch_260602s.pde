/**
 * UAL Creative Computing Institute
 * Computational Practices: Sound and Image Processing
 * Week 9: Vectors, Forces and Autonomous Movement - "CYPHER: Void Escape"
 * * Core Technical Implementations:
 * 1. Newtonian Vector Mechanics: Implements force accumulator update equations based on F = m * a.
 * 2. Aerodynamic Drag (Fluid Damp): Calculates quadratic resistance vectors opposing velocity.
 * 3. Inverse Kinematics Linkage: Animates a multi-segment autonomous predator (VoidWorm) using segment follow constraint rules.
 * 4. Craig Reynolds Steering Behaviors: Drives predator AI using seek vectors bounded by maxForce and maxSpeed limits.
 * 5. Screen Boundary Bounce: Performs elastic momentum transfers on wall impacts.
 */

// Game States: 0-Start Menu, 1-Gameplay, 2-Game Over
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
  background(13, 13, 26); // Obsidian background
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

/**
 * Reset game parameters
 */
void resetGame() {
  score = 0;
  spaceship = new Player(width / 2.0, height / 2.0 + 150);
  monster = new VoidWorm(100, 100, 18); // 18-segment giant worm
  
  anomalies = new ArrayList<GravityAnomaly>();
  for (int i = 0; i < 3; i++) {
    anomalies.add(new GravityAnomaly(random(100, width - 100), random(100, height - 300), random(15, 35)));
  }
  
  cores = new ArrayList<EnergyCore>();
  for (int i = 0; i < 4; i++) {
    cores.add(new EnergyCore());
  }
}

/**
 * Process core game loop physics
 */
void runGameLogic() {
  // 1. Process gravitational anomalies (Gravitational Attractors)
  for (GravityAnomaly ga : anomalies) {
    ga.update();
    ga.display();
    
    // Universal Gravitation calculation
    PVector gravityForce = ga.calculateGravity(spaceship);
    spaceship.applyForce(gravityForce);
    
    // Core collision damage
    if (PVector.dist(spaceship.position, ga.position) < ga.radius + 15) {
      spaceship.shield -= 0.8;
      // Apply slight repulsive thrust to prevent overlap
      PVector repel = PVector.sub(spaceship.position, ga.position).normalize().mult(0.8);
      spaceship.applyForce(repel);
    }
  }
  
  // 2. Process environmental fluid drag on ship
  // Formula: F_drag = -c * ||v||^2 * v_unit
  float c = 0.15; // Coefficient of drag
  PVector drag = spaceship.velocity.copy();
  drag.normalize();
  drag.mult(-c * spaceship.velocity.magSq()); // Drag is proportional to square of velocity
  spaceship.applyForce(drag);
  
  // 3. Process mouse interactive engine thrust
  if (mousePressed) {
    PVector mouseVec = new PVector(mouseX, mouseY);
    PVector thrust = PVector.sub(mouseVec, spaceship.position);
    thrust.normalize();
    thrust.mult(0.45); // Engine thrust strength
    spaceship.applyForce(thrust);
    
    // Draw graphical tether line
    stroke(0, 242, 254, 100);
    strokeWeight(1.5);
    line(spaceship.position.x, spaceship.position.y, mouseX, mouseY);
  }
  
  // 4. Update ship parameters
  spaceship.update();
  spaceship.display();
  
  // 5. Update autonomous seeker AI
  monster.update(spaceship.position);
  monster.display();
  
  // 6. Damage checks: check if monster bite coordinate is close to ship
  if (PVector.dist(spaceship.position, monster.segments[0]) < 28) {
    spaceship.shield -= 1.5;
    PVector knockback = PVector.sub(spaceship.position, monster.segments[0]).normalize().mult(5);
    spaceship.velocity.add(knockback);
  }
  
  // 7. Core collections
  for (int i = cores.size() - 1; i >= 0; i--) {
    EnergyCore core = cores.get(i);
    core.display();
    
    if (PVector.dist(spaceship.position, core.position) < 22) {
      score += 100;
      spaceship.shield = min(100, spaceship.shield + 15); // Replenish shields
      cores.remove(i);
      cores.add(new EnergyCore()); 
    }
  }
  
  // 8. Death check
  if (spaceship.shield <= 0) {
    gameState = 2;
  }
  
  drawHUD();
}

/**
 * Ambient background space dust
 */
void drawSpaceDust() {
  stroke(255, 40);
  for (int i = 0; i < 20; i++) {
    float x = (noise(i, frameCount * 0.002) * width);
    float y = (noise(i + 10, frameCount * 0.002) * height);
    strokeWeight(noise(i) * 3);
    point(x, y);
  }
}

/**
 * Start Menu
 */
void drawStartScreen() {
  textAlign(CENTER, CENTER);
  
  fill(0, 242, 254);
  textSize(32);
  text("CYPHER // VOID ESCAPE SYSTEM", width/2, height/2 - 80);
  
  fill(255, 180);
  textSize(14);
  text("Newtonian Mechanics & Autonomous Agent System", width/2, height/2 - 40);
  
  fill(120);
  textSize(11);
  text("PHYSICS FEATURES: Gravitational Pull | Viscous Aerodynamic Drag | Euler Semi-Implicit Integration", width/2, height/2 - 10);
  
  fill(223, 255, 0);
  textSize(13);
  text("Hold [MOUSE LEFT CLICK] to steer engines, escape the worm, and collect green cores.", width/2, height/2 + 60);
  
  fill(255, 150);
  rectMode(CENTER);
  noFill();
  stroke(0, 242, 254);
  rect(width/2, height/2 + 130, 200, 40, 5);
  fill(0, 242, 254);
  text("CLICK MOUSE TO ENGAGE", width/2, height/2 + 134);
  
  if (mousePressed && gameState == 0) {
    gameState = 1;
  }
}

/**
 * Game Over Menu
 */
void drawGameOverScreen() {
  textAlign(CENTER, CENTER);
  
  fill(230, 50, 50);
  textSize(36);
  text("CAPSULE SHIELD DESTROYED", width/2, height/2 - 60);
  
  fill(255);
  textSize(16);
  text("Escape Score: " + score, width/2, height/2 - 10);
  
  fill(120);
  text("The VoidWorm consumed your nuclear energy grid...", width/2, height/2 + 20);
  
  fill(223, 255, 0);
  textSize(12);
  text("Press Key [ R ] to Re-engage the Capsule Engines", width/2, height/2 + 80);
}

/**
 * HUD Dashboard
 */
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
  text("SHIELD INTEGRITY LEVEL", 25, 36);
  
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
  text("ENERGY CORES: " + score, 25, 80);
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    resetGame();
    gameState = 1;
  }
}
class Player {
  PVector position;
  PVector velocity;
  PVector acceleration;
  
  float mass = 12.0;    // Structural mass driving F = m * a
  float shield = 100.0; // Health bar
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
    acceleration.mult(0); // Clear forces
  }
  
  void display() {
    pushMatrix();
    translate(position.x, position.y);
    
    float heading = velocity.heading() + HALF_PI;
    rotate(heading);
    
    // Draw particle thruster exhaust fire when active
    if (mousePressed) {
      fill(223, 255, 0, random(150, 255));
      noStroke();
      triangle(-4, 10, 4, 10, 0, 10 + random(10, 25));
    }
    
    // Draw spaceship chassis
    stroke(0, 242, 254);
    strokeWeight(1.8);
    fill(13, 13, 26);
    beginShape();
    vertex(0, -size);
    vertex(size * 0.8, size);
    vertex(0, size * 0.4);
    vertex(-size * 0.8, size);
    endShape(CLOSE);
    
    // Render energy field shield bubble
    noFill();
    stroke(0, 242, 254, map(shield, 0, 100, 20, 100));
    ellipse(0, 0, size * 2.5, size * 2.5);
    
    popMatrix();
  }
  
  void checkEdges() {
    float bounceCoeff = -0.65; // Coefficient of restitution on wall collisions
    
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
  float segmentDist = 16.0; // Distance constraints between segments
  
  PVector position; // Head coordinate
  PVector velocity;
  PVector acceleration;
  float maxSpeed = 3.6;     
  float maxForce = 0.08;    // Steering limits for organic curves
  
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
    // 1. seek vector = target position - current position
    PVector desired = PVector.sub(target, position);
    desired.normalize();
    desired.mult(maxSpeed);
    
    // 2. steering force = desired - velocity
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(maxForce); 
    
    acceleration.add(steer);
    velocity.add(acceleration);
    velocity.limit(maxSpeed);
    position.add(velocity);
    
    acceleration.mult(0); 
    
    // 3. Inverse Kinematics Linkage segment follower loop
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
    // Draw spinal link line
    stroke(75, 0, 130, 120);
    strokeWeight(12);
    noFill();
    beginShape();
    for (int i = 0; i < numSegments; i++) {
      vertex(segments[i].x, segments[i].y);
    }
    endShape();
    
    // Render outer carapace sections
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
    
    // Draw predator head
    fill(24, 15, 8);
    stroke(230, 50, 50);
    strokeWeight(2.5);
    ellipse(position.x, position.y, 28, 28);
    
    // Glowing compound eyes
    fill(223, 255, 0);
    noStroke();
    ellipse(position.x - 6, position.y - 4, 5, 5);
    ellipse(position.x + 6, position.y - 4, 5, 5);
  }
}

// ==========================================
// 3. GravityAnomaly Class
// ==========================================
class GravityAnomaly {
  PVector position;
  float radius;
  float pulseOffset = 0.0;
  float gConstant = 12.0; // Gravity amplitude scalar
  
  GravityAnomaly(float x, float y, float r) {
    position = new PVector(x, y);
    radius = r;
    pulseOffset = random(100);
  }
  
  PVector calculateGravity(Player p) {
    PVector force = PVector.sub(position, p.position);
    float distance = force.mag();
    
    // Prevent divide-by-zero or infinite gravity pull near core
    distance = constrain(distance, 20.0, 300.0);
    
    force.normalize();
    
    // Formula: F = G * (m1 * m2) / r^2
    float strength = (gConstant * p.mass) / (distance * distance);
    force.mult(strength);
    return force;
  }
  
  void update() {
    // Slowly float through space using Perlin Noise
    position.x += (noise(frameCount * 0.005 + pulseOffset) - 0.5) * 1.2;
    position.y += (noise(frameCount * 0.005 + pulseOffset + 50) - 0.5) * 1.2;
  }
  
  void display() {
    pushMatrix();
    translate(position.x, position.y);
    
    float pulse = sin(frameCount * 0.05 + pulseOffset) * 6;
    
    // Outer gravitational field rings
    noFill();
    for (int i = 1; i < 4; i++) {
      stroke(180, 80, 255, 120 / i);
      strokeWeight(1.2);
      ellipse(0, 0, (radius * 2 * i) + pulse * i * 0.5, (radius * 2 * i) + pulse * i * 0.5);
    }
    
    // Attractor Core
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
