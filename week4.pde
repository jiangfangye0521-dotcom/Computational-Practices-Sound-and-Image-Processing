//UAL Creative Computing Institute
//Computational Practices: Sound and Image Processing
// Week 4: Filtering Images & Perlin Noise (2D Vector Flow Landscape)
// * Core Technical Implementations:
// 1. Employs a high-density 2D grid matrix of primitive vector shapes (circles, squares, triangles).
// 2. Uses 2D Perlin Noise (noise()) to modulate rotational angles and position offsets over time.
// 3. Dynamically downsamples "IMG_3352.jpg" and maps processed pixel data directly to vector fills.
// 4. Retains real-time 2D pixel processing filters (Original, Threshold, Duotone, Sepia, High Contrast) using hotkeys '1'-'5'.
// 5. Supports interactive mouse-warp force fields (push-apart vectors) and noise scale sweeps via 'W' and 'S'.

PImage img;
int gridScale = 8;        // High-density downsampling grid resolution (optimized for 2D performance)
int cols, rows;
float noiseScale = 0.06;  // Spatial frequency of the Perlin noise field
float timeOffset = 0.0;   // Temporal phase shift over time
float globalSpeed = 0.015; // Time-progression rate

int filterMode = 1;

color colorA, colorB;

void setup() {
  size(800, 600);
  smooth(8);
  // Load target background image
  img = loadImage("IMG_3352.jpg");
  if (img == null) {
    // Procedural backup: generate a synthetic gradient if image is missing
    img = createImage(800, 600, RGB);
    img.loadPixels();
    for (int i = 0; i < img.pixels.length; i++) {
      img.pixels[i] = color(80, 120, 240);
    }
    img.updatePixels();
  }
  img.resize(width, height);

  cols = width / gridScale;
  rows = height / gridScale;
  colorA = color(10, 15, 35);
  colorB = color(0, 242, 254);
}

void draw() {
  background(13, 13, 26);
  
  // Advance time step for Perlin Noise
  timeOffset += globalSpeed;
  
  img.loadPixels(); 
  
  // Traverse the 2D coordinate grid
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      
      int px = x * gridScale + gridScale / 2;
      int py = y * gridScale + gridScale / 2;
      
      float n = noise(x * noiseScale, y * noiseScale, timeOffset);
      
      color pixelColor = img.get(px, py);
      color processedColor = applyImageFilter(pixelColor, filterMode);
      
      float distanceToMouse = dist(px, py, mouseX, mouseY);
      float mouseInfluence = map(min(distanceToMouse, 160), 0, 160, 1.0, 0.0); 
      float noiseAngle = n * TWO_PI * 2;
      float dOffset = n * gridScale * 1.5;
      float offsetX = cos(noiseAngle) * dOffset;
      float offsetY = sin(noiseAngle) * dOffset;
      
      // Apply interactive repulsive physics on mouse press (Simulating localized force vectors)
      if (mousePressed) {
        float forceAngle = atan2(py - mouseY, px - mouseX);
        float forceMagnitude = mouseInfluence * gridScale * 4.0;
        offsetX += cos(forceAngle) * forceMagnitude;
        offsetY += sin(forceAngle) * forceMagnitude;
      }
      pushMatrix();
      translate(px + offsetX, py + offsetY);
      rotate(noiseAngle);
      
      fill(processedColor);
      noStroke();
      
      int primitiveSelector = (x + y) % 3;
      
      float shapeSize = map(n, 0, 1, 1.5, gridScale * 1.8) * (1.0 - mouseInfluence * 0.4);
      
      if (primitiveSelector == 0) {
        ellipse(0, 0, shapeSize, shapeSize);
      } else if (primitiveSelector == 1) {

        rectMode(CENTER);
        rect(0, 0, shapeSize, shapeSize);
      } else {
        float h = shapeSize * (sqrt(3) / 2.0);
        triangle(0, -h / 2.0, -shapeSize / 2.0, h / 2.0, shapeSize / 2.0, h / 2.0);
      }
      
      popMatrix();
    }
  }

  drawOverlay();
}

color applyImageFilter(color c, int mode) {
  float r = red(c);
  float g = green(c);
  float b = blue(c);
  
  switch(mode) {
    case 1: 
      return c;
      
    case 2: 
      float gray = (r + g + b) / 3.0;
      return (gray > 115) ? color(255) : color(25, 25, 40);
      
    case 3: 
      float normGray = (r + g + b) / 3.0;
      float lerpAmount = normGray / 255.0;
      return lerpColor(colorA, colorB, lerpAmount);
      
    case 4: 
      float outR = (r * .393) + (g * .769) + (b * .189);
      float outG = (r * .349) + (g * .686) + (b * .168);
      float outB = (r * .272) + (g * .534) + (b * .131);
      return color(constrain(outR, 0, 255), constrain(outG, 0, 255), constrain(outB, 0, 255));
      
    case 5: 
      float factor = (259.0 * (150.0 + 255.0)) / (255.0 * (259.0 - 150.0));
      float newR = factor * (r - 128.0) + 128.0;
      float newG = factor * (g - 128.0) + 128.0;
      float newB = factor * (b - 128.0) + 128.0;
      return color(constrain(newR, 0, 255), constrain(newG, 0, 255), constrain(newB, 0, 255));
      
    default:
      return c;
  }
}
void keyPressed() {
  // Map W and S to adjust spatial frequency (Noise Scale) of the flow field
  if (key == 'w' || key == 'W') noiseScale = min(noiseScale + 0.005, 0.25);
  if (key == 's' || key == 'S') noiseScale = max(noiseScale - 0.005, 0.01);
  
  if (key >= '1' && key <= '5') {
    filterMode = int(key - '0');
  }
}

void drawOverlay() {
  // Translucent background container
  fill(15, 15, 25, 210);
  noStroke();
  rect(15, 15, 410, 160, 6);
  stroke(0, 242, 254, 80);
  strokeWeight(1);
  rect(15, 15, 410, 160, 6);
  
  // Headers
  fill(255);
  textSize(12);
  text("GEN_FLOW // 2D Vector Noise Landscape", 30, 38);
  
  fill(140);
  textSize(10);
  text("Engine: JAVA2D | Spatial Noise Scale: " + nf(noiseScale, 1, 3), 30, 54);
  
  // Dynamic filter state menu
  String[] menuItems = {
    "[1] Original RGB Texture",
    "[2] Binary Threshold (B&W)",
    "[3] Cyberpunk Duotone (Teal/Obsidian)",
    "[4] Sepia Retro Tint",
    "[5] High-Contrast Boost"
  };
  
  for (int i = 0; i < menuItems.length; i++) {
    if (filterMode == (i + 1)) {
      fill(0, 242, 254); // Neon Cyan Highlight
      text("-> " + menuItems[i], 30, 78 + (i * 15));
    } else {
      fill(110);
      text("   " + menuItems[i], 30, 78 + (i * 15));
    }
  }
  fill(100);
  text("Controls: Press [W]/[S] to tune Noise Scale | Click + Drag to Repel", 30, 160);
}
