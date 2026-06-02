//UAL Creative Computing Institute
//Computational Practices: Sound and Image Processing
//Week 7: Digital Sound & Advanced Sample-based FM Synthesis
//Architectural Overview:
//1. Dual Audio Engine: Hybrid system combining local WAV sample playback (with fallback oscillators) and real-time physical synth synthesis to guarantee 100% compilation stability.
 //2. Varispeed Pitch Modulation: Emulates John Chowning's classic Frequency Modulation (FM) algorithm 
 //by modulating the playback rate of 'telemetry.wav' using a sinusoidal Low-Frequency Oscillator (LFO).


import processing.sound.*;

// Sound File assets
SoundFile telemetrySF;  
SoundFile engineSF;     
SoundFile windSF;       

boolean useOscFallback = false;
SinOsc telemetryOsc;
TriOsc engineOsc;
SawOsc atmosphereOsc;

// Dynamic DSP Filters
LowPass engineFilter;   
LowPass windFilter;     

// Real-time Audio Analysis
Waveform waveform;
int samples = 512;

// Interactive Mute Toggles
boolean telemetryMute = false;
boolean engineMute = false;
boolean atmosphereMute = false;

// FM & LFO Modulation Parameters
float carrierRate = 1.0;      // Base playback rate for the telemetry sample (1.0 = original pitch)
float modFreq = 8.5;          // Frequency of the modulating LFO (Hz)
float modIndex = 0.45;        // Depth of frequency deviation (Modulation Index)
float modPhase = 0.0;         // Phase accumulator for the modulator

Sound soundSystem;

void setup() {
  size(800, 600);
  frameRate(60);
  smooth(8);
  
  soundSystem = new Sound(this);
  soundSystem.volume(0.5);

  // Initialize filters
  engineFilter = new LowPass(this);
  windFilter = new LowPass(this);

  // Initialize the audio analyzer
  waveform = new Waveform(this, samples);

  // --- Attempt to Load Local WAV Assets from /data ---
  try {
    telemetrySF = new SoundFile(this, "telemetry.wav");
    engineSF = new SoundFile(this, "engine.wav");
    windSF = new SoundFile(this, "wind.wav");
    
    // Play looped streams
    engineSF.loop();
    windSF.loop();
    telemetrySF.loop();
    
    // Route sample outputs to corresponding Low-Pass filters
    engineFilter.process(engineSF);
    windFilter.process(windSF);
    
    println("[SYSTEM] Successfully loaded local WAV files. Activating Varispeed FM Engine.");
  } 
  catch (Exception e) {
    // Graceful Fallback: Initialize raw wave oscillators if files are missing
    println("[WARNING] Local WAV assets missing. Activating fallback physical synthesis engine.");
    useOscFallback = true;
    
    telemetryOsc = new SinOsc(this);
    telemetryOsc.play();
    telemetryOsc.amp(0.12);

    engineOsc = new TriOsc(this);
    engineFilter.process(engineOsc);
    engineOsc.play();
    engineOsc.amp(0.35);

    atmosphereOsc = new SawOsc(this);
    windFilter.process(atmosphereOsc);
    atmosphereOsc.play();
    atmosphereOsc.amp(0.18);
  }

  routeWaveformInput();
}

void draw() {
  background(10, 10, 16); 

  // 1. Process DSP and FM math
  updateSoundSynthesis();

  // 2. Render the interactive vector radar
  drawLandingRadarHUD();
  
  // 3. Render telemetry diagnostic panel
  drawTechnicalMetadata();
}

/**
 * Dynamically updates the Waveform analyzer input source.
 * Prevents null-pointer exceptions and ensures continuous signal analysis.
 */
void routeWaveformInput() {
  if (waveform == null) return;
  
  if (!useOscFallback) {
    if (!engineMute && engineSF != null) {
      waveform.input(engineSF);
    } else if (!atmosphereMute && windSF != null) {
      waveform.input(windSF);
    } else if (!telemetryMute && telemetrySF != null) {
      waveform.input(telemetrySF);
    }
  } else {
    if (!engineMute && engineOsc != null) {
      waveform.input(engineOsc);
    } else if (!atmosphereMute && atmosphereOsc != null) {
      waveform.input(atmosphereOsc);
    } else if (!telemetryMute && telemetryOsc != null) {
      waveform.input(telemetryOsc);
    }
  }
}

/**
 * DSP Synthesis & Pitch Modulation Engine
 */
void updateSoundSynthesis() {
  if (!useOscFallback) {
    // ==========================================
    // MODULE A: Sample-Based Varispeed FM
    // ==========================================
    
    // 1. Telemetry Beacon: modulate playback rate to create electronic chirp pings
    if (!telemetryMute) {
      modPhase += (TWO_PI * modFreq) / 60.0;
      if (modPhase > TWO_PI) modPhase -= TWO_PI;
      
      // Compute modulated rate: Rate = carrierRate + modIndex * sin(modPhase)
      float targetRate = carrierRate + modIndex * sin(modPhase);
      telemetrySF.rate(targetRate);
      telemetrySF.amp(0.25);
    } else {
      telemetrySF.amp(0.0);
    }

    // 2. Engine Resonance LFO
    if (!engineMute) {
      float engineLFO = sin(frameCount * 0.02);
      float targetRate = map(engineLFO, -1, 1, 0.82, 1.12);
      engineSF.rate(targetRate);
      engineSF.amp(0.4);
      
      // Slowly sweep low-pass filter cutoff frequency
      float engineFilterCutoff = map(cos(frameCount * 0.01), -1, 1, 120, 420);
      engineFilter.freq(engineFilterCutoff);
    } else {
      engineSF.amp(0.0);
    }

    // 3. Atmospheric Wind Sweep: mapped directly to mouse coordinates
    if (!atmosphereMute) {
      windSF.amp(0.3);
      windSF.rate(1.0);
      
      float targetCutoff = map(mouseX, 0, width, 80, 2400);
      targetCutoff = constrain(targetCutoff, 80, 2400);
      windFilter.freq(targetCutoff);
    } else {
      windSF.amp(0.0);
    }
    
  } else {
    // ==========================================
    // MODULE B: Physical Oscillator Fallback
    // ==========================================
    if (!telemetryMute) {
      modPhase += (TWO_PI * modFreq) / 60.0;
      if (modPhase > TWO_PI) modPhase -= TWO_PI;
      
      float currentTelemetryFreq = 220.0 + 120.0 * sin(modPhase);
      telemetryOsc.freq(currentTelemetryFreq);
      telemetryOsc.amp(0.12);
    } else {
      telemetryOsc.amp(0.0);
    }

    if (!engineMute) {
      float engineLFO = sin(frameCount * 0.02);
      float engineFreq = map(engineLFO, -1, 1, 45.0, 75.0);
      engineOsc.freq(engineFreq);
      engineOsc.amp(0.35);
      
      float engineFilterCutoff = map(cos(frameCount * 0.01), -1, 1, 100, 400);
      engineFilter.freq(engineFilterCutoff);
    } else {
      engineOsc.amp(0.0);
    }

    if (!atmosphereMute) {
      atmosphereOsc.freq(110.0);
      atmosphereOsc.amp(0.18);
      
      float targetCutoff = map(mouseX, 0, width, 80, 2500);
      targetCutoff = constrain(targetCutoff, 80, 2500);
      windFilter.freq(targetCutoff);
    } else {
      atmosphereOsc.amp(0.0);
    }
  }
}

/**
 * Renders the polar coordinate landing radar
 */
void drawLandingRadarHUD() {
  translate(width/2, height/2);
  
  // Analyse the current active signal path
  waveform.analyze();
  
  float currentModulationOffset = sin(modPhase);
  float radarRadius = 185 + (currentModulationOffset * 22.0); // Pulsates in sync with the FM modulator
  
  // 1. Concentric calibration rings
  noFill();
  stroke(75, 0, 130, 80); // Purple grid lines
  strokeWeight(1);
  ellipse(0, 0, 450, 450);
  ellipse(0, 0, 300, 300);
  
  // Rotating sweep sweep line
  pushMatrix();
  rotate(modPhase);
  stroke(0, 242, 254, 130); // Teal scanner sweep
  strokeWeight(1.5);
  line(0, 0, 0, -225);
  popMatrix();
  
  // 2. Polar Oscilloscope (Transposing linear waveform arrays to a circular ring)
  stroke(0, 242, 254);
  strokeWeight(2);
  noFill();
  
  beginShape();
  for (int i = 0; i < samples; i++) {
    float theta = map(i, 0, samples, 0, TWO_PI);
    
    // Scale amplitude offsets to drive polar radius
    float audioAmpOffset = waveform.data[i] * 50.0;
    float r = radarRadius + audioAmpOffset;
    
    // Polar to Cartesian conversion
    float x = r * cos(theta);
    float y = r * sin(theta);
    
    vertex(x, y);
  }
  endShape(CLOSE);
  
  // 3. Modulo-spaced indicator marks (Inherited from Week 3 pattern principles)
  stroke(223, 255, 0); // Acid Lime
  strokeWeight(1.5);
  
  for (int i = 0; i < 12; i++) {
    if (i % 3 == 0) {
      float angle = i * (TWO_PI / 12.0) + (frameCount * 0.005);
      float targetDist = 260.0 + (waveform.data[i * 10] * 35.0);
      float px = targetDist * cos(angle);
      float py = targetDist * sin(angle);
      
      line(px - 6, py, px + 6, py);
      line(px, py - 6, px, py + 6);
    }
  }
}

/**
 * Displays technical diagnostics and metadata HUD
 */
void drawTechnicalMetadata() {
  resetMatrix();
  
  stroke(75, 0, 130, 150);
  strokeWeight(2);
  line(30, 30, width - 30, 30);
  
  fill(255);
  textSize(13);
  text("CYPHER SYSTEMS // Acheron Descending Telemetry", 40, 52);
  
  fill(0, 242, 254);
  textSize(10);
  text("DESCENT VEHICLE: AR-16 // STATUS: ORBITAL APPROACH", 40, 68);
  
  fill(150);
  if (!useOscFallback) {
    text("Sound Engine Mode: REAL-TIME SAMPLE MODULATION [ACTIVE]", 40, 100);
    text("Telemetry Base Pitch Rate: " + nf(carrierRate, 1, 2) + "x", 40, 115);
  } else {
    text("Sound Engine Mode: SYNTHETIC OSCILLATOR BACKUP [FALLBACK]", 40, 100);
    text("Telemetry Base Frequency: 220.0 Hz", 40, 115);
  }
  text("Modulator Frequency: " + modFreq + " Hz", 40, 130);
  text("Damping Coefficient: " + nf(modPhase, 1, 2) + " rad", 40, 145);
  
  // Interactive control card
  fill(15, 15, 22, 210);
  stroke(223, 255, 0, 120);
  strokeWeight(1);
  rect(30, height - 120, width - 60, 90, 4);
  
  fill(255);
  textSize(11);
  text("DESCENT COCKPIT CAPTAIN CONSOLE", 45, height - 100);
  
  drawToggleState("1. Telemetry [Wav]", !telemetryMute, 45, height - 75);
  drawToggleState("2. Engine Hum [Wav]", !engineMute, 205, height - 75);
  drawToggleState("3. Surface Wind [Wav]", !atmosphereMute, 365, height - 75);
  
  fill(120);
  text("Console Control: Press [1], [2], [3] to toggle channels  |  Move MouseX to adjust Wind Density", 45, height - 45);
}

void drawToggleState(String label, boolean isActive, float x, float y) {
  if (isActive) {
    fill(0, 255, 150);
    text("[ ONLINE ] " + label, x, y);
  } else {
    fill(255, 80, 80);
    text("[ OFFLINE ] " + label, x, y);
  }
}

void keyPressed() {
  if (key == '1') {
    telemetryMute = !telemetryMute;
    if (!useOscFallback) {
      if (telemetryMute) {
        if (telemetrySF != null) telemetrySF.stop();
      } else {
        if (telemetrySF != null) telemetrySF.loop();
      }
    } else {
      if (telemetryMute) {
        if (telemetryOsc != null) telemetryOsc.stop();
      } else {
        if (telemetryOsc != null) telemetryOsc.play();
      }
    }
    routeWaveformInput(); // Re-balance routing on state change
  }
  if (key == '2') {
    engineMute = !engineMute;
    if (!useOscFallback) {
      if (engineMute) {
        if (engineSF != null) engineSF.stop();
      } else {
        if (engineSF != null) engineSF.loop();
      }
    } else {
      if (engineMute) {
        if (engineOsc != null) engineOsc.stop();
      } else {
        if (engineOsc != null) engineOsc.play();
      }
    }
    routeWaveformInput();
  }
  if (key == '3') {
    atmosphereMute = !atmosphereMute;
    if (!useOscFallback) {
      if (atmosphereMute) {
        if (windSF != null) windSF.stop();
      } else {
        if (windSF != null) windSF.loop();
      }
    } else {
      if (atmosphereMute) {
        if (atmosphereOsc != null) atmosphereOsc.stop();
      } else {
        if (atmosphereOsc != null) atmosphereOsc.play();
      }
    }
    routeWaveformInput();
  }
}
