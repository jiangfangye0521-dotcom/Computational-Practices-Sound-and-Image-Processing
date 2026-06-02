//Computational Practices: Sound and Image Processing
// Week 2: Manipulating and Analysing Pixels - Part 1 (RGB Histograms)
// This sketch loads a full-color image (IMG_3352.jpg), displays it in its
// original color space, and dynamically analyzes and plots three overlapping
// histograms representing the Red, Green, and Blue color channels.
// Technical Highlights:
// - Dynamic 1D pixel array analysis.
// - Global normalization: scaling all three channels relative to the global maximum peak.
// - Alpha-blended visualization for readable overlapping waves.

PImage img;
int[] rHist = new int[256];
int[] gHist = new int[256];
int[] bHist = new int[256];
int maxVal = 0; 

void setup() {
  size(600, 800);
  img = loadImage("IMG_3352.jpg");
  img.resize(width, height);
  img.loadPixels();
  for (int i = 0; i < img.pixels.length; i++) {
    color c = img.pixels[i];
    int r = int(red(c));
    int g = int(green(c));
    int b = int(blue(c));
    rHist[r]++;
    gHist[g]++;
    bHist[b]++;
  }
  
  // Find the global maximum across all three channels to normalize the graphs proportionally
  for (int i = 0; i < 256; i++) {
    if (rHist[i] > maxVal) maxVal = rHist[i];
    if (gHist[i] > maxVal) maxVal = gHist[i];
    if (bHist[i] > maxVal) maxVal = bHist[i];
  }
}

void draw() {
  image(img, 0, 0);
  
  // Draw semi-transparent background panel for the histogram display
  fill(15, 15, 25, 180);
  noStroke();
  rect(0, height - 220, width, 220);
  stroke(255, 30);
  strokeWeight(1);
  for (int i = 1; i < 4; i++) {
    float y = height - 20 - (i * 50);
    line(20, y, width - 20, y);
  }
  
  strokeWeight(2);
  
  for (int i = 0; i < 256; i++) {
    float x = map(i, 0, 255, 30, width - 30);
    float baseY = height - 20;
    
    float rHeight = map(rHist[i], 0, maxVal, 0, 160);
    float gHeight = map(gHist[i], 0, maxVal, 0, 160);
    float bHeight = map(bHist[i], 0, maxVal, 0, 160);
    stroke(255, 50, 50, 140);
    line(x, baseY, x, baseY - rHeight);
    
    // 2. Green Channel Plot
    stroke(50, 255, 50, 140);
    line(x, baseY, x, baseY - gHeight);

    stroke(50, 100, 255, 140);
    line(x, baseY, x, baseY - bHeight);
  }
  fill(255);
  textSize(12);
  text("Original RGB Channel Distribution (IMG_3352.jpg)", 30, height - 195);
  
  textSize(10);
  fill(255, 100, 100);
  text("■ RED", 30, height - 175);
  fill(100, 255, 100);
  text("■ GREEN", 80, height - 175);
  fill(100, 150, 255);
  text("■ BLUE", 145, height - 175);
}
