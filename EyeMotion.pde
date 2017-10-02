import gab.opencv.*;
import processing.video.*;

//-------Change the variables in this section to adjust parameters

//Change this to LEFT for the left eye
String eye = "RIGHT";

//change this to increase / decrease smoothing
int lagAmount = 10;

//change these to change the amount of field in the left and right to cutoff
int xcutoff = 1000;     //for the right eye
int leftxcutoff = 300;  //for the left eye

//set these to the resolution of your camera, check setup function to properly choose camera
int camwidth = 1280;
int camheight = 960;

//how far 'down' the eye looks
int yadjust = 120;

//if you don't want to look above a certain point, increase this number
int ycutoff = 0;

//--------end adjustable parameters

Capture video;
OpenCV opencv;
ArrayList<PVector> lag = new ArrayList<PVector>();
int eyeLidPushDown = 0;


void setup() {
  //set the size to the camwidth + 480
  size(2500, 960);
  
  if(eye.equals("LEFT")){
    xcutoff = leftxcutoff;
  }
  
  String[] cameras = Capture.list();
  
  //Optionally, print the cameras attached to computer, and find the camera you want to use.
  //To do so, uncomment the next 3 lines.
  //for(int i = 0; i < cameras.length; i++){
  //  println(i+": "+cameras[i]);
  //}
  
  //Load the camera you want by putting the right number where it says cameras[0] below:
  video = new Capture(this, camwidth, camheight, cameras[0]);
  opencv = new OpenCV(this, camwidth, camheight);
  opencv.startBackgroundSubtraction(5, 3, 0.5);  //need to play with
  video.start();
}

void draw() {
  background(0);
  video.read();
  opencv.loadImage(video);
  image(opencv.getOutput(), 480, 0);
  line(xcutoff+480, 0, xcutoff+480, height); //show where the processing stops, X
  line(480,ycutoff,480+camwidth,ycutoff);    //where it stops, Y
  opencv.updateBackground();
  
  //Get all the contours, or all the points of motion by framedifferencing:
  ArrayList<Contour> conts = opencv.findContours();
  
  //Comment/Uncomment below to draw the contours
  drawContours(conts);
  
  //find the center of the contour with the most points (highest motion)
  PVector center = maxVector(conts);
  
  //if it exists, add it to our lagged set of points, draw a red circle
  if(center != null){
    lag.add(center);
    ellipse(center.x+480, center.y, 100,100);
  }
  
  if(conts.size() <= 2){ //not enough motion
    fill(255);
    ellipse(480/2,480/2+eyeLidPushDown,480,480);
    ellipse(240,125,700,400); //eyelid
  } else { //enough motion!
    drawEyes();
  }
  
  //remove the front of the queue
  if(lag.size() > legAmount){
    lag.remove(0);
  }
  
}


PVector maxVector(ArrayList<Contour> contours){
  float avX = 0;
  float avY = 0;
  int total = 0;
  int max = 0;
  int index = -1;
  Contour maxContour = null;
  
  //Find the countour with most number of points
  for(Contour cont : contours){
    float x = cont.getPoints().get(0).x;
    float y = cont.getPoints().get(0).y;
    if((eye.equals("RIGHT") && x < xcutoff) 
    || (eye.equals("LEFT")  && x > xcutoff)){
      if(y > ycutoff && max < cont.numPoints()){
        max = cont.numPoints();
        index = contours.indexOf(cont);
      }
    }
  }
  
  //If there is a contour, find the average of its points
  if(index != -1)
  { 
    maxContour = contours.get(index);
    for(PVector vector : maxContour.getPoints()){
      avX += vector.x;
      avY += vector.y;
      total++;
    }
  } else {
    return null;
  }
  avX = avX / total;
  avY = avY / total;
  //return that point as a PVector
  return new PVector(avX, avY);
}


void drawEyes(){
  
  //The eye outline
  fill(255);
  stroke(0);
  ellipse(480/2,480/2+eyeLidPushDown,480,480);
  
  //the average of the lag
  float avX = 0;
  float avY = 0;
  for(int i = 0; i < lag.size(); i++){
    avX += lag.get(i).x;
    avY += lag.get(i).y;
  }
  avX = avX / lag.size();
  avY = avY / lag.size();
  PVector point = new PVector(avX, avY);
  
  //Draw the unadjusted lagged point, i.e. where the eye is looking on the camera screen:
  fill(150);  //a grey circle
  ellipse(point.x+480, point.y, 100,100);
  
  point.y = (point.y*(480.0/camheight))+yadjust;
  point.x = point.x*((float)480.0/(float)camwidth);

  //ye old stay in the circle trick, here be math:
  if(dist(point.x, point.y, 240, 240) > 145){  
    float x = point.x-240;
    float y = ((point.y)-240);
    
    float t = atan(y/x);

    if(x < 0){
      y = -145*sin(t);
      x = -145*cos(t);
    } else {
      y = 145*sin(t);
      x = 145*cos(t);
    }
    
    point.x = abs(x + 240);
    point.y = abs(y + 240);
  }
  
  stroke(255,0,0);
  //Iris color:
  fill(150,150,255);
  ellipse(point.x,point.y,150,150);
  //pupil color:
  fill(0);
  ellipse(point.x,point.y,75,75);
  
  //upper eyelid
  fill(255);
  beginShape();
  vertex(0, 0);
  vertex(480,0);
  vertex(480,200);
  curveVertex(480,200);
  curveVertex(480, 200);
  curveVertex(240,  150);
  curveVertex(0,  200);
  curveVertex(0,  200);
  vertex(0,200);
  endShape();
  //fill(0);
  //ellipse(240,50,700,400);
}


void drawContours(ArrayList<Contour> contours){
    noFill();
  stroke(255, 0, 0);
  strokeWeight(3);
  pushMatrix();
  translate(480,0);
  for (Contour contour : contours) {
    if(contour.numPoints()> 100){
      contour.draw();
    }
  } 
  popMatrix();
}
