
 // Computational Practices: Sound and Image Processing
 // Week 2: Manipulating and Analysing Pixels - Part 2 (Custom Pixel Sorting)
 // This sketch implements a customized, selective pixel sorting algorithm.
 // Instead of standard brightness-based sorting, it targets pixels based on their
 // SATURATION and HUE thresholds. This allows highly saturated elements (like the red
 // London bus in IMG_3352.jpg) to "melt" downwards, while neutral concrete buildings
 // remain unchanged, generating a narrative-driven glitch aesthetic.
 // Key Commands:
 // Press 'r' - Reset to original image
 // Press '1' - Sort Horizontally by Saturation threshold (Bleeding effect)
 // Press '2' - Sort Vertically by Saturation threshold (Melting rain effect)
 // Press '3' - Sort Horizontally by Brightness threshold
 // Press '4' - Sort Vertically by Hue threshold
 

PImage sourceImg;
PImage sortedImg;
boolean isSorted = false;

float satThreshold = 100.0;  // Only sort vibrant pixels
float brightThreshold = 120.0;

void setup() {
  size(600, 800);
  sourceImg = loadImage("IMG_3352.jpg");
  sourceImg.resize(width, height);
  
  // Clone image for non-destructive editing
  sortedImg = sourceImg.get();
}

void draw() {
  image(sortedImg, 0, 0);
  
  // Display UI Panel
  fill(0, 180);
  noStroke();
  rect(15, 15, 360, 125, 8);
  
  fill(255);
  textSize(13);
  text("GLITCHOLOGY // Selective Pixel Sorter", 25, 35);
  
  textSize(11);
  fill(180);
  text("Interactive Controls:", 25, 55);
  text("Press 'r' to Reset Image", 25, 70);
  text("Press '1' / '2' : Saturation-Targeted Sort (H / V)", 25, 85);
  text("Press '3' / '4' : Brightness / Hue Sorter (H / V)", 25, 100);
  
  // Indicate active state
  if (isSorted) {
    fill(0, 255, 150);
    text("Status: Glitch Applied (Custom Rule Active)", 25, 122);
  } else {
    fill(255, 150, 0);
    text("Status: Original Frame (Awaiting Sorting)", 25, 122);
  }
}

void keyPressed() {
  if (key == 'r' || key == 'R') {
    sortedImg = sourceImg.get();
    isSorted = false;
  }
  
  if (key == '1') {
    sortedImg = sourceImg.get();
    sortPixelsHorizontal(true);
    isSorted = true;
  }
  
  if (key == '2') {
    sortedImg = sourceImg.get();
    sortPixelsVertical(true); 
    isSorted = true;
  }
  
  if (key == '3') {
    sortedImg = sourceImg.get();
    sortPixelsHorizontal(false); 
    isSorted = true;
  }
  
  if (key == '4') {
    sortedImg = sourceImg.get();
    sortPixelsVertical(false);
    isSorted = true;
  }
}

void sortPixelsHorizontal(boolean useSaturationRule) {
  sortedImg.loadPixels();
  
  for (int y = 0; y < sortedImg.height; y++) {
    int x = 0;
    while (x < sortedImg.width) {
      int startX = findStartHorizontal(x, y, useSaturationRule);
      if (startX == -1) break; 
      
      int endX = findEndHorizontal(startX, y, useSaturationRule);

      int length = endX - startX;
      color[] segment = new color[length];
      for (int i = 0; i < length; i++) {
        segment[i] = sortedImg.pixels[(startX + i) + y * sortedImg.width];
      }

      sortSegment(segment, useSaturationRule ? "saturation" : "brightness");
      
      for (int i = 0; i < length; i++) {
        sortedImg.pixels[(startX + i) + y * sortedImg.width] = segment[i];
      }
      
      x = endX + 1;
    }
  }
  sortedImg.updatePixels();
}

void sortPixelsVertical(boolean useSaturationRule) {
  sortedImg.loadPixels();
  
  for (int x = 0; x < sortedImg.width; x++) {
    int y = 0;
    while (y < sortedImg.height) {
      int startY = findStartVertical(x, y, useSaturationRule);
      if (startY == -1) break;
      
      int endY = findEndVertical(x, startY, useSaturationRule);
      
      int length = endY - startY;
      color[] segment = new color[length];
      for (int i = 0; i < length; i++) {
        segment[i] = sortedImg.pixels[x + (startY + i) * sortedImg.width];
      }
      
      sortSegment(segment, useSaturationRule ? "hue" : "brightness");
      
      for (int i = 0; i < length; i++) {
        sortedImg.pixels[x + (startY + i) * sortedImg.width] = segment[i];
      }
      
      y = endY + 1;
    }
  }
  sortedImg.updatePixels();
}
int findStartHorizontal(int startX, int y, boolean useSat) {
  for (int x = startX; x < sortedImg.width; x++) {
    color c = sortedImg.pixels[x + y * sortedImg.width];
    if (useSat) {
      if (saturation(c) > satThreshold) return x;
    } else {
      if (brightness(c) > brightThreshold) return x;
    }
  }
  return -1;
}

int findEndHorizontal(int startX, int y, boolean useSat) {
  for (int x = startX; x < sortedImg.width; x++) {
    color c = sortedImg.pixels[x + y * sortedImg.width];
    if (useSat) {
      if (saturation(c) < satThreshold) return x;
    } else {
      if (brightness(c) < brightThreshold) return x;
    }
  }
  return sortedImg.width - 1;
}

int findStartVertical(int x, int startY, boolean useSat) {
  for (int y = startY; y < sortedImg.height; y++) {
    color c = sortedImg.pixels[x + y * sortedImg.width];
    if (useSat) {
      if (saturation(c) > satThreshold) return y;
    } else {
      if (brightness(c) > brightThreshold) return y;
    }
  }
  return -1;
}

int findEndVertical(int x, int startY, boolean useSat) {
  for (int y = startY; y < sortedImg.height; y++) {
    color c = sortedImg.pixels[x + y * sortedImg.width];
    if (useSat) {
      if (saturation(c) < satThreshold) return y;
    } else {
      if (brightness(c) < brightThreshold) return y;
    }
  }
  return sortedImg.height - 1;
}

void sortSegment(color[] arr, String mode) {
  int n = arr.length;
  for (int i = 0; i < n - 1; i++) {
    for (int j = 0; j < n - i - 1; j++) {
      boolean swapNeeded = false;
      
      if (mode.equals("saturation")) {
        swapNeeded = saturation(arr[j]) > saturation(arr[j+1]);
      } else if (mode.equals("brightness")) {
        swapNeeded = brightness(arr[j]) > brightness(arr[j+1]);
      } else if (mode.equals("hue")) {
        swapNeeded = hue(arr[j]) > hue(arr[j+1]);
      }
      
      if (swapNeeded) {
        color temp = arr[j];
        arr[j] = arr[j+1];
        arr[j+1] = temp;
      }
    }
  }
}
