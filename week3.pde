// Computational Practices: Sound and Image Processing
//Week 3: Vector Graphics - Symmetric Modulo Lattice
// * Concept:
// An abstract dynamic geometric artwork exploring mathematical symmetry, 
// matrix transformations, and optical interference using the modulo operator.
// Technical Constraints Met:
// 1. Uses 3 distinct primitives: rect(), ellipse() (circle), and triangle().
// 2. Employs the modulo (%) operator to alternate shapes and colors dynamically.
// 3. Utilizes pushMatrix(), popMatrix(), translate(), and rotate() for local transformations.
// 4. Incorporates blendMode(DIFFERENCE) to generate emergent overlapping geometries.


int cols = 7;
int rows = 7;
float spacingX, spacingY;
color[] palette = {
  color(240, 240, 240), // Chalk White
  color(230, 50, 50),   // Vermillion Red
  color(40, 90, 240),   // Cobalt Blue
  color(15, 15, 20)     // Charcoal Dark
};

float baseAngle = 0;

void setup() {
  size(700, 700);
  smooth();
  spacingX = width / (cols + 1);
  spacingY = height / (rows + 1);
  rectMode(CENTER);
}

void draw() {
  background(15, 15, 20);
  
  // Use DIFFERENCE blend mode to create complex structural negatives where shapes overlap
  blendMode(DIFFERENCE);

  baseAngle += 0.4;

  for (int r = 0; r < rows; r++) {
    for (int c = 0; c < cols; c++) {
      float x = spacingX * (c + 1);
      float y = spacingY * (r + 1);
      
      int primitiveSelector = (r + c) % 3;
      int colorSelector = (r * c + c) % palette.length;
      // If the sum of row and column is even, rotate clockwise; if odd, rotate counter-clockwise
      float direction = ((r + c) % 2 == 0) ? 1.0 : -1.0;
      float rotationSpeed = ((r * 2 + c) % 3 + 1) * 0.5;
      float localAngle = baseAngle * direction * rotationSpeed;
      
      // Calculate responsive shape size based on mouse interaction
      float sizeOffset = sin(radians(baseAngle + (r * 10) + (c * 10))) * 15;
      float shapeSize = map(mouseX, 0, width, 35, 75) + sizeOffset;
      
      pushMatrix();
      
      // Translate the origin to the center of the current grid cell
      translate(x, y);
      rotate(radians(localAngle));
      fill(palette[colorSelector]);
      noStroke();
      if (primitiveSelector == 0) {
        rect(0, 0, shapeSize, shapeSize);
        
      } else if (primitiveSelector == 1) {
        ellipse(0, 0, shapeSize, shapeSize);
        
      } else if (primitiveSelector == 2) {
        float h = shapeSize * (sqrt(3) / 2.0);
        triangle(
          0, -h / 2.0, 
          -shapeSize / 2.0, h / 2.0, 
          shapeSize / 2.0, h / 2.0
        );
      }
      
      popMatrix();
    }
  }
  blendMode(BLEND);
  drawUI();
}

//Renders technical and theoretical metadata overlay
void drawUI() {
  fill(255, 160);
  textSize(11);
  text("SYSTEM: Symmetric Modulo Lattice // Dynamic Matrix Transformation", 30, height - 45);
  text("PRIMITIVES: [(r+c)%3 == 0: Rect]  [(r+c)%3 == 1: Circle]  [(r+c)%3 == 2: Triangle]", 30, height - 30);
  text("INTERACTION: Move Mouse horizontally to alter spatial geometry", 30, height - 15);
}
