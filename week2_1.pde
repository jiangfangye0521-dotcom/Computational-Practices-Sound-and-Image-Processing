// Computational Practices: Sound and Image Processing
// Week 2: Manipulating and Analysing Pixels - Part 1 Advanced (Channel Swapping & Histograms)
// This sketch performs a channel-swap (RGB to BGR) on the source image,
// displaying a surreal color-shifted version, and generates corresponding RGB
// histograms reflecting the new shifted pixel distribution.

PImage originalImg;
PImage swappedImg;
int[] rHist = new int[256];
int[] gHist = new int[256];
int[] bHist = new int[256];
int maxVal = 0;

void setup() {
  size(600, 800);
  originalImg = loadImage("IMG_3352.jpg");
  originalImg.resize(width, height);
  
  swappedImg = createImage(width, height, RGB);
  
  originalImg.loadPixels();
  swappedImg.loadPixels();
  
  for (int i = 0; i < originalImg.pixels.length; i++) {
    color c = originalImg.pixels[i];
    float r = red(c);
    float g = green(c);
    float b = blue(c);
    
    swappedImg.pixels[i] = color(b, g, r);
  }
  swappedImg.updatePixels();
  
  for (int i = 0; i < swappedImg.pixels.length; i++) {
    color c = swappedImg.pixels[i];
    int r = int(red(c));
    int g = int(green(c));
    int b = int(blue(c));
    
    rHist[r]++;
    gHist[g]++;
    bHist[b]++;
  }
  
  // Find global peak
  for (int i = 0; i < 256; i++) {
    if (rHist[i] > maxVal) maxVal = rHist[i];
    if (gHist[i] > maxVal) maxVal = gHist[i];
    if (bHist[i] > maxVal) maxVal = bHist[i];
  }
}

void draw() {
  
  image(swappedImg, 0, 0);
  
  // UI Panel
  fill(15, 15, 25, 190);
  noStroke();
  rect(0, height - 220, width, 220);
  
  stroke(255, 25);
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
    
    stroke(50, 255, 50, 140);
    line(x, baseY, x, baseY - gHeight);
    
    stroke(50, 100, 255, 140);
    line(x, baseY, x, baseY - bHeight);
  }
  
  // Render UI text indicating channel transformations
  fill(255);
  textSize(12);
  text("Advanced: Swapped Channel Distribution [RGB → BGR]", 30, height - 195);
  textSize(10);
  fill(255, 120, 120);
  text("■ Swapped Red (Old Blue Channel)", 30, height - 175);
  fill(120, 255, 120);
  text("■ Green Channel (Constant)", 220, height - 175);
  fill(120, 160, 255);
  text("■ Swapped Blue (Old Red Channel)", 380, height - 175);
}
