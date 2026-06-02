
 //UAL Creative Computing Institute
//Computational Practices: Sound and Image Processing
// Week 8: Algorithmic Music and Sampling - Dynamic Drum Machine
import processing.sound.*;

// Drum Sample players
SoundFile sKick, sSnare, sHihat, sPerc;
boolean[] useSynthFallback = new boolean[4]; 

// Fallback Synthesis Engines (Simulates drum physical hits if files are missing)
SinOsc synthKick;
WhiteNoise synthHihatNoise;
LowPass hihatFilter;
SqrOsc synthSnare;
TriOsc synthPerc;

// Integrated Week 7 Bassline Synth
TriOsc synthBass;
LowPass bassFilter;

// Sequencer Clock Configuration
float bpm = 120.0;
int stepFrames = 15;   // 15 frames per 1/8 note under 60fps
int currentStep = 0;   // Active step (0-15)
int currentMeasure = 0; // Active bar (0-3)

// 4-Channel x 16-Step Pattern Grid Matrix
boolean[][] gridPattern = {
  { true,  false, false, false, true,  false, false, false, true,  false, false, false, true,  false, false, false }, // Row 0: Kick
  { false, false, false, false, true,  false, false, false, false, false, false, false, true,  false, false, false }, // Row 1: Snare
  { true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true  }, // Row 2: Hi-hat
  { false, false, true,  false, false, false, true,  false, false, true,  false, false, false, false, true,  true  }  // Row 3: Percussion
};

// Visual Reaction Pulses
float kickPulse = 0.0;
float snareFlash = 0.0;
float hihatTick = 0.0;
float percVibe = 0.0;

void setup() {
  size(800, 600);
  frameRate(60);
  smooth(8);
  
  // Set overall system volume limit
  Sound s = new Sound(this);
  s.volume(0.5);

  // --- Initialize Drum Channels (WAV with Fallback Synths) ---
  // Channel 0: Kick
  try {
    sKick = new SoundFile(this, "kick.wav");
    useSynthFallback[0] = false;
  } catch (Exception e) {
    println("[SYSTEM] kick.wav missing. Initializing SinOsc Kick Synthesizer.");
    synthKick = new SinOsc(this);
    useSynthFallback[0] = true;
  }

  // Channel 1: Snare
  try {
    sSnare = new SoundFile(this, "snare.wav");
    useSynthFallback[1] = false;
  } catch (Exception e) {
    println("[SYSTEM] snare.wav missing. Initializing SqrOsc Snare Synthesizer.");
    synthSnare = new SqrOsc(this);
    useSynthFallback[1] = true;
  }

  // Channel 2: Hihat
  try {
    sHihat = new SoundFile(this, "hihat.wav");
    useSynthFallback[2] = false;
  } catch (Exception e) {
    println("[SYSTEM] hihat.wav missing. Initializing filtered Noise Hi-hat Synthesizer.");
    synthHihatNoise = new WhiteNoise(this);
    hihatFilter = new LowPass(this);
    hihatFilter.process(synthHihatNoise);
    useSynthFallback[2] = true;
  }

  // Channel 3: Percussion
  try {
    sPerc = new SoundFile(this, "perc.wav");
    useSynthFallback[3] = false;
  } catch (Exception e) {
    println("[SYSTEM] perc.wav missing. Initializing TriOsc Percussion Synthesizer.");
    synthPerc = new TriOsc(this);
    useSynthFallback[3] = true;
  }

  // --- Initialize Bassline Synth (Week 7 Integration) ---
  synthBass = new TriOsc(this);
  bassFilter = new LowPass(this);
  bassFilter.process(synthBass);
  synthBass.play();
  synthBass.amp(0.2);
}

void draw() {
  background(12, 12, 20); // Obsidian dark blue
  
  // --- Check Modulo Rhythmic Clock ---
  if (frameCount % stepFrames == 0) {
    triggerStepLogic();
    
    // Advance sequencer pointer
    currentStep = (currentStep + 1) % 16;
    
    // Increment bar index
    if (currentStep == 0) {
      currentMeasure = (currentMeasure + 1) % 4; // 4-bar loop
    }
  }

  // Decay visual reactions over time
  kickPulse *= 0.90;
  snareFlash *= 0.88;
  hihatTick *= 0.85;
  percVibe *= 0.92;

  // Render visual assets
  drawAudioReactiveGrid();
  drawSequencerUI();
}

/**
 * Handles beat triggers, temporal pattern mutations, and stochastic variations
 */
void triggerStepLogic() {
  // Read baseline matrix values
  boolean playKick  = gridPattern[0][currentStep];
  boolean playSnare = gridPattern[1][currentStep];
  boolean playHihat = gridPattern[2][currentStep];
  boolean playPerc  = gridPattern[3][currentStep];

  // --- Process Algorithmic Bar Evolution (Modulo Counting) ---
  if (currentMeasure == 2) {
    // Bar 3: Stochastic/Probability-based percussion fills
    if (random(1.0) < 0.20) playHihat = false; // 20% drop rate for Hi-hat
    if (random(1.0) < 0.40) playPerc = true;   // 40% added trigger rate for Percussion
  } 
  else if (currentMeasure == 3) {
    // Bar 4: Automatic drum fill breakdown
    if (currentStep % 2 == 1 && random(1.0) < 0.7) playKick = true; // High-velocity kick roll
    if (currentStep >= 12) {
      playSnare = true; // High-velocity snare roll at the end of the bar
      playHihat = false;
    }
  }

  // --- Trigger Active Channels ---
  if (playKick) {
    triggerAudioChannel(0);
    kickPulse = 1.0;
  }
  if (playSnare) {
    triggerAudioChannel(1);
    snareFlash = 1.0;
  }
  if (playHihat) {
    triggerAudioChannel(2);
    hihatTick = 1.0;
  }
  if (playPerc) {
    triggerAudioChannel(3);
    percVibe = 1.0;
  }

  // --- Process Bassline Synthesis (Week 7 Integration) ---
  // Renders Fm Pentatonic bass progressions synced to 1/4 note steps
  if (currentStep % 4 == 0) {
    float[] bassScale = { 43.65, 51.91, 58.27, 65.41, 77.78 }; // F1, Ab1, Bb1, C2, Eb2
    int scaleIndex = (currentStep + currentMeasure * 2) % bassScale.length;
    float targetFreq = bassScale[scaleIndex];
    
    synthBass.freq(targetFreq);
    float cutoff = map(sin(frameCount * 0.1), -1, 1, 150, 600);
    bassFilter.freq(cutoff);
    synthBass.amp(0.25);
  } else if (currentStep % 4 == 2) {
    synthBass.amp(0.08); // Damp note volume on weak beats
  }
}

/**
 * Universal sound player dispatching sample buffers or synthesizers
 */
void triggerAudioChannel(int channel) {
  if (channel == 0) { // Kick
    if (!useSynthFallback[0]) {
      sKick.play(1.0, 1.0);
    } else {
      synthKick.play();
      synthKick.amp(0.6);
      synthKick.freq(120);
      thread("decayKickSynth");
    }
  } 
  else if (channel == 1) { // Snare
    if (!useSynthFallback[1]) {
      sSnare.play(1.0, 0.8);
    } else {
      synthSnare.play();
      synthSnare.amp(0.4);
      synthSnare.freq(240);
      thread("decaySnareSynth");
    }
  } 
  else if (channel == 2) { // Hihat
    if (!useSynthFallback[2]) {
      sHihat.play(1.2, 0.4);
    } else {
      synthHihatNoise.play();
      hihatFilter.freq(8000);
      synthHihatNoise.amp(0.18);
      thread("decayHihatSynth");
    }
  } 
  else if (channel == 3) { // Percussion
    if (!useSynthFallback[3]) {
      sPerc.play(0.9, 0.5);
    } else {
      synthPerc.play();
      synthPerc.amp(0.3);
      synthPerc.freq(1200);
      thread("decayPercSynth");
    }
  }
}

// --- Multi-Threaded Decay Envelope Emulators ---
void decayKickSynth() {
  for (int i = 0; i < 12; i++) {
    delay(10);
    if (useSynthFallback[0]) {
      synthKick.freq(120 - (i * 8)); // Rapid pitch sweep down
      synthKick.amp(0.6 * (1.0 - i/12.0));
    }
  }
  if (useSynthFallback[0]) synthKick.stop();
}

void decaySnareSynth() {
  delay(80);
  if (useSynthFallback[1]) {
    synthSnare.amp(0.1);
    delay(40);
    synthSnare.stop();
  }
}

void decayHihatSynth() {
  delay(40);
  if (useSynthFallback[2]) {
    synthHihatNoise.amp(0.0);
    synthHihatNoise.stop();
  }
}

void decayPercSynth() {
  for (int i = 0; i < 8; i++) {
    delay(15);
    if (useSynthFallback[3]) {
      synthPerc.freq(1200 - (i * 100));
      synthPerc.amp(0.3 * (1.0 - i/8.0));
    }
  }
  if (useSynthFallback[3]) synthPerc.stop();
}

/**
 * Draws audio-reactive structural grid lines
 */
void drawAudioReactiveGrid() {
  pushMatrix();
  translate(width/2, height/2 - 50);
  
  // Ambient radial glow
  noFill();
  stroke(75, 0, 130, 40 + int(kickPulse * 100));
  strokeWeight(3);
  ellipse(0, 0, 260 + kickPulse * 40, 260 + kickPulse * 40);
  
  // Draw structural connection lattice
  int nodes = 12;
  float baseRadius = 110 + snareFlash * 30;
  
  for (int i = 0; i < nodes; i++) {
    float angle = i * (TWO_PI / nodes) + (frameCount * 0.005);
    float x = baseRadius * cos(angle);
    float y = baseRadius * sin(angle);
    
    float currentPulse = (i % 2 == 0) ? hihatTick : percVibe;
    float targetSize = 6 + currentPulse * 14;
    
    if (i % 3 == 0) {
      fill(0, 242, 254, 200); 
    } else if (i % 3 == 1) {
      fill(223, 255, 0, 200); 
    } else {
      fill(230, 50, 50, 200); 
    }
    noStroke();
    ellipse(x, y, targetSize, targetSize);
    
    // Draw structural lines
    stroke(255, 20 + int(snareFlash * 80));
    strokeWeight(0.5);
    for (int j = i + 1; j < nodes; j++) {
      if ((i + j) % 4 == 0) { 
        float otherAngle = j * (TWO_PI / nodes) + (frameCount * 0.005);
        float ox = baseRadius * cos(otherAngle);
        float oy = baseRadius * sin(otherAngle);
        line(x, y, ox, oy);
      }
    }
  }
  popMatrix();
}

/**
 * Renders the interactive 16-step sequencer HUD
 */
void drawSequencerUI() {
  // Panel background card
  fill(20, 20, 32, 220);
  stroke(75, 0, 130, 150);
  strokeWeight(2);
  rect(40, height - 210, width - 80, 180, 8);
  
  // Metadata text
  fill(255);
  textSize(12);
  text("GEN_SEQUENCER // Real-Time Algorithmic Sample Controller", 60, height - 185);
  
  fill(0, 242, 254);
  textSize(10);
  text("TEMPO: " + int(bpm) + " BPM  |  BAR STATE: " + (currentMeasure + 1) + " / 4  |  ACTIVE STEP: " + (currentStep + 1) + " / 16", 60, height - 170);
  
  String[] labels = { "KICK", "SNARE", "HIHAT", "PERC" };
  color[] rowColors = {
    color(230, 50, 50),   
    color(0, 242, 254),   
    color(223, 255, 0),   
    color(180, 80, 255)   
  };
  
  float startX = 140;
  float stepW = (width - 240) / 16.0;
  float startY = height - 150;
  float rowH = 20;
  
  // Draw the 4x16 interactive grid
  for (int r = 0; r < 4; r++) {
    fill(180);
    textSize(10);
    text(labels[r], 60, startY + (r * rowH) + 12);
    
    // Fallback indicator lights (Green = sample playing; Orange = physical synthesis fallback active)
    if (useSynthFallback[r]) {
      fill(255, 150, 0);
      ellipse(115, startY + (r * rowH) + 8, 5, 5);
    } else {
      fill(0, 255, 100);
      ellipse(115, startY + (r * rowH) + 8, 5, 5);
    }
    
    for (int s = 0; s < 16; s++) {
      float rx = startX + (s * stepW);
      float ry = startY + (r * rowH);
      
      if (gridPattern[r][s]) {
        fill(rowColors[r]); 
      } else {
        if (s % 4 == 0) {
          fill(50, 50, 70); // Strong beat marker
        } else {
          fill(30, 30, 45); // Weak beat marker
        }
      }
      
      // Highlight current playhead step
      if (s == currentStep) {
        stroke(255, 255);
        strokeWeight(2);
      } else {
        stroke(12, 12, 20);
        strokeWeight(1);
      }
      
      rect(rx, ry, stepW - 4, rowH - 4, 3);
    }
  }
  
  fill(120);
  textSize(9);
  text("Interactive Guide: Click grid cells to customize sequence  |  Green Indicator = WAV Sample Active  |  Orange Indicator = Synth Fallback Mode", 60, height - 42);
}

/**
 * Handle grid clicks to mutate patterns
 */
void mousePressed() {
  float startX = 140;
  float stepW = (width - 240) / 16.0;
  float startY = height - 150;
  float rowH = 20;
  
  if (mouseX >= startX && mouseX <= startX + (16 * stepW) &&
      mouseY >= startY && mouseY <= startY + (4 * rowH)) {
        
    int targetStep = floor((mouseX - startX) / stepW);
    int targetRow = floor((mouseY - startY) / rowH);
    
    targetStep = constrain(targetStep, 0, 15);
    targetRow = constrain(targetRow, 0, 3);
    
    gridPattern[targetRow][targetStep] = !gridPattern[targetRow][targetStep];
  }
}
