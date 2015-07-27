
/*
KineticTune
 by Alejandro García Salas
 
a particle cloud that responds to movement and music
*/

String audiofilename = "top-of-the-world.mp3"; // The audio source to use.

//BEATS
int BEAT_DETECTION_SENSITIVITY = 50;
int SKIP_BEATS = 1;
int skip_beat_counter = 0;


import org.openkinect.*;
import org.openkinect.processing.*;

import ddf.minim.analysis.*;
import ddf.minim.*;  

//Minim Library object
Minim minim;                  
AudioPlayer s;    

//Beat detection
FFT fft;
BeatDetect beat;
BeatListener blistener;
float buffersize;

//MINIM variables
int sample=2000;                 
float amplyfingFactor = 0.02;
float[] sizeOfModules;                    
float[] analysisOfCurrentSounds;   
                
// Kinect Library object
Kinect kinect;

float a = 0;

// Size of kinect image
int w = 640;
int h = 480;

//Artsy effect variables
color c;

// We'll use a lookup table so that we don't have to repeat the math over and over
float[] depthLookUp = new float[2048];

void setup() {
  size(displayWidth, displayHeight, P3D);
  
  //MINIM setup
  minim = new Minim(this);
  s = minim.loadFile(audiofilename, sample);
  s.play(); //Minim settings                            

  
  sizeOfModules = new float[sample];
  analysisOfCurrentSounds = new float[sample];
  for (int i = 0; ++i < sample;) {
      sizeOfModules[i] = 0;
  }
  
  //BEATS
  beat = new BeatDetect(player.bufferSize(), player.sampleRate());
  beat = new BeatDetect(player.bufferSize(), player.sampleRate());
  beat.setSensitivity(BEAT_DETECTION_SENSITIVITY);
  blistener = new BeatListener(beat, s);
  
  kinect = new Kinect(this);
  kinect.start();
  kinect.enableDepth(true);
  // We don't need the grayscale image in this example
  // so this makes it more efficient
  kinect.processDepthImage(false);

  // Lookup table for all possible depth values (0 - 2047)
  for (int i = 0; i < depthLookUp.length; i++) {
    depthLookUp[i] = rawDepthToMeters(i);
  }
}

void draw() {
  background(255, 255, 255);
  fill(0);
  textMode(SCREEN);
  text("Kinect FR: " + (int)kinect.getDepthFPS() + "\nProcessing FR: " + (int)frameRate,10,16);
  //MINIM
  analysisOfCurrentSounds = s.mix.toArray(); 


  // Get the raw depth as array of integers
  int[] depth = kinect.getRawDepth();

  // We're just going to calculate and draw every 4th pixel (equivalent of 160x120)
  int skip = 10;

  // Translate and rotate
  translate(width/2,height/2,-50);
  rotateY(a);

  for(int x=0; x<w; x+=skip) {
    for(int y=0; y<h; y+=skip) {
      int offset = x+y*w;

      // Convert kinect data to world xyz coordinate
      int rawDepth = depth[offset];
      PVector v = depthToWorld(x,y,rawDepth);
            
      color cmix = color(100, 200, 210); //color definition
      c = generateRandomColor(cmix); //generates pseudo-random colors within a same palette based on the value of cmix
      
      stroke(c);
      fill(c);
      pushMatrix();
      // Scale up by 200
      float factor = 200;
      translate(v.x*factor,v.y*factor,factor-v.z*factor);
      // Draw a point
      box(sizeOfModules[x] += (analysisOfCurrentSounds[x] * amplyfingFactor));
      //rect(0, 0, 3, 3); //uncomment if you don't want sound analysis
      popMatrix();
    }
  }

  // Rotate
  a += 0.015f;
}

// These functions come from: http://graphics.stanford.edu/~mdfisher/Kinect.html
float rawDepthToMeters(int depthValue) {
  if (depthValue < 2047) {
    return (float)(1.0 / ((double)(depthValue) * -0.0030711016 + 3.3309495161));
  }
  return 0.0f;
}

PVector depthToWorld(int x, int y, int depthValue) {

  final double fx_d = 1.0 / 5.9421434211923247e+02;
  final double fy_d = 1.0 / 5.9104053696870778e+02;
  final double cx_d = 3.3930780975300314e+02;
  final double cy_d = 2.4273913761751615e+02;

  PVector result = new PVector();
  double depth =  depthLookUp[depthValue];//rawDepthToMeters(depthValue);
  result.x = (float)((x - cx_d) * depth * fx_d);
  result.y = (float)((y - cy_d) * depth * fy_d);
  result.z = (float)(depth);
  return result;
}

void stop() {
  //MINIM
  s.close();
  minim.stop();
  //KINECT
  kinect.quit();
  super.stop();
}


/* function that returns a random color:
    we average RGB values of random colors with those of a constant color (mix) in order to generate
    an aesthetically pleasent color palette
 */
color generateRandomColor(color mix) {
    int red = int(random(100,250));
    int green = int(random(100,250));
    int blue = int(random(100,250));

    // mixing the color (averaging)
    red = int((red + red(mix)) / 2);
    green = int((green + green(mix)) / 2);
    blue = int((blue + blue(mix)) / 2);
 
    color c= color(red, green, blue);
    return c;
}
