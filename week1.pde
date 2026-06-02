//Computational Practices: Sound and Image Processing
//Week 1: Pixels and Colour - Interactive Gradient Suite
//This sketch demonstrates 5 progressive variations of pixel-level gradients
//developed for a hypothetical Computational Art Gallery branding system ("CYPHER").
//It utilizes direct pixel array manipulation via loadPixels() and updatePixels().
//Interactive Controls:
//Press '1' - Horizontal Multi-stop Gradient
//Press '2' - Vertical Multi-stop Gradient
//Press '3' - Diagonal Linear Gradient
//Press '4' - Static Radial Gradient (Centered)
//Press '5' - Dynamic Interactive Radial Gradient (Mouse-tracked with easing)

// Color Palette Definition (Theme: Cybernetic Obsidian & Neon)
color[] palette;
int currentMode = 1;

float targetX, targetY;
float currentX, currentY;
float easing = 0.08;

void setup() {
  size(800, 600);
  frameRate(60);
  
  palette = new color[4];
  palette[0] = color(13, 13, 26);     // Dark Obsidian Space Blue
  palette[1] = color(75, 0, 130);    // Deep Indigo
  palette[2] = color(0, 242, 254);    // Electric Teal
  palette[3] = color(223, 255, 0);    // Acid Lime/Yellow
  
  currentX = width / 2.0;
  currentY = height / 2.0;
}

void draw() {
  loadPixels();
  
  if (currentMode == 5) {
    targetX = mouseX;
    targetY = mouseY;
    currentX += (targetX - currentX) * easing;
    currentY += (targetY - currentY) * easing;
  }
  
  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      
      float t = 0.0;
      
      switch(currentMode) {
        case 1:
          t = map(x, 0, width - 1, 0.0, 1.0);
          break;
          
        case 2:
          t = map(y, 0, height - 1, 0.0, 1.0);
          break;
          
        case 3:
          t = map(x + y, 0, (width - 1) + (height - 1), 0.0, 1.0);
          break;
          
        case 4:
          float dx = x - (width / 2.0);
          float dy = y - (height / 2.0);
          float distance = sqrt(dx*dx + dy*dy);
          float maxRadius = sqrt(sq(width/2.0) + sq(height/2.0));
          t = map(distance, 0, maxRadius, 0.0, 1.0);
          
          t = pow(t, 0.85); 
          break;
          
        case 5:
          float diffX = x - currentX;
          float diffY = y - currentY;
          float dMouse = sqrt(diffX*diffX + diffY*diffY);
          float maxDist = sqrt(sq(width) + sq(height)); // Maximum possible distance
          t = map(dMouse, 0, maxDist * 0.7, 0.0, 1.0);
          t = constrain(t, 0.0, 1.0);
          t = pow(t, 0.9);
          break;
      }
      
      pixels[x + y * width] = getMultiStopColor(t, palette);
    }
  }
  
  updatePixels();
  
  drawUI();
}

//Performs piecewise linear interpolation across an arbitrary color array.
//Maps a single scalar t [0, 1] across N color nodes smoothly.
color getMultiStopColor(float t, color[] colors) {

  if (t <= 0.0) return colors[0];
  if (t >= 1.0) return colors[colors.length - 1];
  
  float segmentRange = 1.0 / (colors.length - 1);
  int index = floor(t / segmentRange);
  
  float localT = (t - (index * segmentRange)) / segmentRange;
  
  return lerpColor(colors[index], colors[index + 1], localT);
}

//Draws professional branding and UI text on screen
void drawUI() {
  fill(0, 180);
  noStroke();
  rect(15, 15, 410, 115, 8);
  
  fill(255);
  textSize(14);
  text("CYPHER // Computational Art Gallery Branding", 25, 38);
  
  fill(180);
  textSize(11);
  text("Core Technology: 1D Pixel Buffer Manipulation (loadPixels)", 25, 55);
  
  // Highlight currently active mode in the UI list
  String[] modesText = {
    "[1] Horizontal 4-Stop Gradient",
    "[2] Vertical 4-Stop Gradient",
    "[3] Diagonal Linear Gradient",
    "[4] Radial Centered Gradient",
    "[5] Interactive Eased Radial (Mouse Tracked)"
  };
  
  for (int i = 0; i < modesText.length; i++) {
    if (currentMode == (i + 1)) {
      fill(0, 242, 254); // Cyan for active state
      text("-> " + modesText[i], 25, 75 + (i * 14));
    } else {
      fill(120);
      text("   " + modesText[i], 25, 75 + (i * 14));
    }
  }
}

//Handle user keyboard input to toggle modes
void keyPressed() {
  if (key >= '1' && key <= '5') {
    currentMode = int(key - '0');
  }
}
