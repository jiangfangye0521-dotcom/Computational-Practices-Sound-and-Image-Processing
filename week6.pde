/**
 * UAL Creative Computing Institute
// Computational Practices: Sound and Image Processing
// Week 06: Dithering, Convolution and Real-time Camera Systems
// Core Features:
// 1. Real-time capture via processing.video.* with automated procedurally generated 
// simulation fallback if no hardware camera is detected (fail-safe compilation).
// 2. Pre-processing: real-time pixel filters (Sepia, Cyberpunk Duotone, High Contrast).
// 3. Chromatic Palette-constrained Error Diffusion: Floyd-Steinberg and Atkinson algorithms 
// diffusing RGB error vectors independently onto neighbors.
// 4. Interactive Palette swaps: Mono (2-color), Cyberpunk Neon (4-color), Vintage Sepia (4-color).
// 5. Comic book vignette framing overlay with real-time frame capture callback ('C' key)
// and physical camera-shutter flash feedback to create a 10-shot story reel.

import processing.video.*;

Capture cam;
boolean useCamera = false;
PImage inputSource; // Polymorphic container for camera feed or procedural fallback

// Interactive parameters
int ditherMode = 1;      // 1: Floyd-Steinberg, 2: Atkinson
int filterMode = 2;      // 1: No Filter, 2: Cyberpunk Duotone, 3: Retro Sepia, 4: High Contrast
int activePalette = 1;   // 1: Stark Monochrome, 2: Cybernetic Neon, 3: Vintage Ink

// 10-shot Comic Storyboard variables
int savedFramesCount = 0;
int flashTimer = 0;

// Color Palettes
color[][] palettes = {
  { color(0), color(255) },
  { color(13, 13, 26), color(75, 0, 130), color(0, 242, 254), color(223, 255, 0) },
  { color(24, 15, 8), color(110, 60, 30), color(210, 160, 100), color(255, 245, 230) }
};

int viewWidth = 640;
int viewHeight = 480;
int frameMarginX = 80;
int frameMarginY = 60;

void setup() {
  size(800, 600);
  frameRate(30);
  
  try {
    String[] cameras = Capture.list();
    if (cameras.length > 0) {
      cam = new Capture(this, viewWidth, viewHeight, cameras[0], 30);
      cam.start();
      useCamera = true;
      println("Hardware Camera initiated successfully.");
    } else {
      println("No camera detected. Activating procedural feed fallback.");
    }
  } catch (Exception e) {
    println("Camera acquisition failed. Activating procedural feed fallback. Error: " + e.getMessage());
  }
  
  if (!useCamera) {
    inputSource = createImage(viewWidth, viewHeight, RGB);
  }
}

void draw() {
  background(15, 15, 22); 
  if (useCamera) {
    if (cam.available()) {
      cam.read();
    }
    inputSource = cam.get();
  } else {
    generateProceduralFeed();
  }
  PImage processedFrame = createImage(viewWidth, viewHeight, RGB);
  processedFrame.copy(inputSource, 0, 0, viewWidth, viewHeight, 0, 0, viewWidth, viewHeight);
  
  applyRealtimeFilters(processedFrame);
  applyChromaticDither(processedFrame, palettes[activePalette - 1], ditherMode);
  
  image(processedFrame, frameMarginX, frameMarginY);
  
  drawPictureFrame();
  drawCameraUI();
  if (flashTimer > 0) {
    fill(255, map(flashTimer, 0, 10, 0, 255));
    noStroke();
    rect(frameMarginX, frameMarginY, viewWidth, viewHeight);
    flashTimer--;
  }
}

void generateProceduralFeed() {
  inputSource.loadPixels();
  float t = frameCount * 0.05;
  for (int x = 0; x < viewWidth; x++) {
    for (int y = 0; y < viewHeight; y++) {
      float r = map(sin(x * 0.01 + t) * cos(y * 0.012 - t), -1, 1, 30, 220);
      float g = map(cos(x * 0.008 - t * 0.5) * sin(y * 0.015 + t), -1, 1, 20, 180);
      float b = map(sin(x * 0.015 + y * 0.008 + t), -1, 1, 50, 255);
      float cx = viewWidth/2 + sin(t)*120;
      float cy = viewHeight/2 + cos(t)*90;
      float d = dist(x, y, cx, cy);
      if (d < 80) {
        r += (80 - d) * 2;
        g -= (80 - d);
        b = 50;
      }
      
      inputSource.pixels[x + y * viewWidth] = color(constrain(r,0,255), constrain(g,0,255), constrain(b,0,255));
    }
  }
  inputSource.updatePixels();
}

void applyRealtimeFilters(PImage img) {
  img.loadPixels();
  
  for (int i = 0; i < img.pixels.length; i++) {
    color c = img.pixels[i];
    float r = red(c);
    float g = green(c);
    float b = blue(c);
    
    switch (filterMode) {
      case 2: 
        float tone = (r + g + b) / 3.0;
        img.pixels[i] = lerpColor(color(10, 10, 35), color(0, 255, 180), tone / 255.0);
        break;
        
      case 3: 
        float outR = (r * .393) + (g * .769) + (b * .189);
        float outG = (r * .349) + (g * .686) + (b * .168);
        float outB = (r * .272) + (g * .534) + (b * .131);
        img.pixels[i] = color(constrain(outR, 0, 255), constrain(outG, 0, 255), constrain(outB, 0, 255));
        break;
        
      case 4:
        float factor = (259.0 * (180.0 + 255.0)) / (255.0 * (259.0 - 180.0));
        float nR = factor * (r - 128.0) + 128.0;
        float nG = factor * (g - 128.0) + 128.0;
        float nB = factor * (b - 128.0) + 128.0;
        img.pixels[i] = color(constrain(nR, 0, 255), constrain(nG, 0, 255), constrain(nB, 0, 255));
        break;
        
      default:
        break;
    }
  }
  img.updatePixels();
}
void applyChromaticDither(PImage img, color[] currentPalette, int algorithm) {
  img.loadPixels();
  
  int w = img.width;
  int h = img.height;
  
  float[] rArr = new float[img.pixels.length];
  float[] gArr = new float[img.pixels.length];
  float[] bArr = new float[img.pixels.length];
  
  for (int i = 0; i < img.pixels.length; i++) {
    rArr[i] = red(img.pixels[i]);
    gArr[i] = green(img.pixels[i]);
    bArr[i] = blue(img.pixels[i]);
  }
  
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      int idx = x + y * w;
      
      float currentR = rArr[idx];
      float currentG = gArr[idx];
      float currentB = bArr[idx];
      
      // Find closest palette color matching Euclidean distance in 3D color-space
      color closestColor = findClosestPaletteColor(currentR, currentG, currentB, currentPalette);
      img.pixels[idx] = closestColor;
      
      // Compute raw error difference vector
      float errR = currentR - red(closestColor);
      float errG = currentG - green(closestColor);
      float errB = currentB - blue(closestColor);
      
      // Distribute error matrix
      if (algorithm == 1) {
        // --- Floyd-Steinberg Error Diffusion ---
        //   .   X   7/16
        // 3/16 5/16 1/16
        distributeError(rArr, gArr, bArr, x + 1, y,     w, h, errR, errG, errB, 7.0/16.0);
        distributeError(rArr, gArr, bArr, x - 1, y + 1, w, h, errR, errG, errB, 3.0/16.0);
        distributeError(rArr, gArr, bArr, x,     y + 1, w, h, errR, errG, errB, 5.0/16.0);
        distributeError(rArr, gArr, bArr, x + 1, y + 1, w, h, errR, errG, errB, 1.0/16.0);
      } else {
        // --- Atkinson Error Diffusion ---
        // Gives highly structured dither waves with strong edge details
        //   .   X   1/8  1/8
        //  1/8 1/8  1/8
        //       1/8
        distributeError(rArr, gArr, bArr, x + 1, y,     w, h, errR, errG, errB, 1.0/8.0);
        distributeError(rArr, gArr, bArr, x + 2, y,     w, h, errR, errG, errB, 1.0/8.0);
        distributeError(rArr, gArr, bArr, x - 1, y + 1, w, h, errR, errG, errB, 1.0/8.0);
        distributeError(rArr, gArr, bArr, x,     y + 1, w, h, errR, errG, errB, 1.0/8.0);
        distributeError(rArr, gArr, bArr, x + 1, y + 1, w, h, errR, errG, errB, 1.0/8.0);
        distributeError(rArr, gArr, bArr, x,     y + 2, w, h, errR, errG, errB, 1.0/8.0);
      }
    }
  }
  img.updatePixels();
}

color findClosestPaletteColor(float r, float g, float b, color[] palette) {
  color chosen = palette[0];
  float minDistance = 1000000;
  
  for (int i = 0; i < palette.length; i++) {
    float pr = red(palette[i]);
    float pg = green(palette[i]);
    float pb = blue(palette[i]);
    float d = sqrt(sq(r - pr) + sq(g - pg) + sq(b - pb));
    if (d < minDistance) {
      minDistance = d;
      chosen = palette[i];
    }
  }
  return chosen;
}

void distributeError(float[] rArr, float[] gArr, float[] bArr, int x, int y, int w, int h, float errR, float errG, float errB, float ratio) {
  if (x >= 0 && x < w && y >= 0 && y < h) {
    int idx = x + y * w;
    rArr[idx] += errR * ratio;
    gArr[idx] += errG * ratio;
    bArr[idx] += errB * ratio;
  }
}

void drawPictureFrame() {
  noFill();
  stroke(10, 10, 15);
  strokeWeight(24);
  rect(frameMarginX, frameMarginY, viewWidth, viewHeight);
  stroke(223, 255, 0); // Acid lime highlight
  strokeWeight(2);
  rect(frameMarginX + 2, frameMarginY + 2, viewWidth - 4, viewHeight - 4);
  
  // Comic Vignette Header Panel
  fill(223, 255, 0);
  noStroke();
  rect(frameMarginX + 15, frameMarginY + 15, 180, 26, 3);
  
  fill(13, 13, 26);
  textSize(11);
  text("SCENE 06 // FRAME [0" + (savedFramesCount + 1) + "]", frameMarginX + 25, frameMarginY + 32);
  
  // Comic Panel Dialogue Bubbles (simulated retro comic book graphic)
  fill(255);
  stroke(10, 10, 15);
  strokeWeight(3);
  rect(frameMarginX + viewWidth - 250, frameMarginY + viewHeight - 45, 230, 28, 4);
  triangle(frameMarginX + viewWidth - 80, frameMarginY + viewHeight - 17, 
           frameMarginX + viewWidth - 60, frameMarginY + viewHeight, 
           frameMarginX + viewWidth - 40, frameMarginY + viewHeight - 17);
           
  fill(0);
  textSize(10);
  text("“The reality has dithered away...”", frameMarginX + viewWidth - 235, frameMarginY + viewHeight - 27);
}

void drawCameraUI() {
  // Reset typography styling
  fill(255);
  textSize(14);
  text("CHROMATIC ERROR DIFFUSION LAB", 40, 36);
  fill(180);
  textSize(10);
  String ditherName = (ditherMode == 1) ? "Floyd-Steinberg" : "Atkinson (High Edge Contrast)";
  String filterName = "NONE";
  if (filterMode == 2) filterName = "Cyberpunk Duotone";
  if (filterMode == 3) filterName = "Retro Sepia Tint";
  if (filterMode == 4) filterName = "High Contrast Amplifier";
  
  text("Dither Algorithm: " + ditherName, 40, 568);
  text("Pre-Filter Matrix: " + filterName, 40, 584);
  
  // Action triggers
  fill(223, 255, 0);
  text("Comic Shots Taken: " + savedFramesCount + " / 10", 500, 36);
  
  fill(150);
  text("Controls:  [1-3] Swap Palette  |  [F] Swap Algorithm  |  [T] Cycle Pre-filter  |  [C] Save Comic Shot", 250, 584);
}

void keyPressed() {
  if (key == '1') activePalette = 1;
  if (key == '2') activePalette = 2;
  if (key == '3') activePalette = 3;
  
  if (key == 'f' || key == 'F') {
    ditherMode = (ditherMode == 1) ? 2 : 1;
  }
  if (key == 't' || key == 'T') {
    filterMode++;
    if (filterMode > 4) filterMode = 1;
  }
  if (key == 'c' || key == 'C') {
    if (savedFramesCount < 10) {
      savedFramesCount++;
      saveFrame("comic-storyboard-frame-" + savedFramesCount + ".png");
      println("Saved Frame " + savedFramesCount + " to library.");
      
      flashTimer = 10;
    }
  }
}
