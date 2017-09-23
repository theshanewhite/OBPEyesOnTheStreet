import gab.opencv.*;
import processing.video.*;

Capture video;
OpenCV opencv;
ArrayList<PVector> lag = new ArrayList<PVector>(5);

int camwidth = 1280;
int camheight = 960;
int rightxcutoff = 1000;
int leftxcutoff = 0;
int ycutoff = 0;
int eyeLidPushDown = 0;
int yadjust = 120;

void setup() {
  size(2500, 960);
  String[] cameras = Capture.list();
  //println(cameras);
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
  line(rightxcutoff+480, 0, rightxcutoff+480, height);
  //line(480,ycutoff,width,ycutoff);
  opencv.updateBackground();
  
  //Get all the contours, or all the points of motion by framedifferencing:
  ArrayList<Contour> conts = opencv.findContours();
  
  //Comment/Uncomment below to draw the contours
  noFill();
  stroke(255, 0, 0);
  strokeWeight(3);
  for (Contour contour : opencv.findContours()) {
    if(contour.numPoints()> 100){
      pushMatrix();
      translate(480,0);
      contour.draw();
      popMatrix();
    }
  } //end contour draw
  
  //find the center of the contour with the most points (highest motion)
  PVector center = maxVector(conts);
  
  lag.add(center);
  ellipse(center.x+480, center.y, 100,100);
  
  if(conts.size() <= 2 || (center.y < ycutoff) || (center.x > rightxcutoff)){
    fill(255);
    ellipse(480/2,480/2+eyeLidPushDown,480,480);
    //fill(0);
    ellipse(240,125,700,400);
    //line(0,240,480,240);
  } else {
    drawEyes();
  }
  if(lag.size() > 10){
    lag.remove(0);
  }
 // noFill();
  
  
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
    //println(cont.numPoints());
    if(cont.getPoints().get(0).x < rightxcutoff && max < cont.numPoints()){
      max = cont.numPoints();
      index = contours.indexOf(cont);
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
  
  float avX = 0;
  float avY = 0;
  for(int i = 0; i < lag.size(); i++){
    avX += lag.get(i).x;
    avY += lag.get(i).y;
  }
  avX = avX / lag.size();
  avY = avY / lag.size();
  
  PVector point = new PVector(avX, avY);
  
  //the unadjusted lagged point:
  fill(150);
  ellipse(point.x+480, point.y, 100,100);
  
  point.y = (point.y*(480.0/camheight))+yadjust;
  //print(point.x+" ");
  point.x = point.x*((float)480.0/(float)rightxcutoff);
  //println(point.x);
  if(dist(point.x, point.y, 240, 240) > 145){
    float x = point.x-240;
    float y = ((point.y)-240);
    
    float t = atan(y/x);
    //println(t);

    if(x < 0){
      y = -145*sin(t);
      x = -145*cos(t);
    } else {
      y = 145*sin(t);
      x = 145*cos(t);
    }
    
    point.x = (x + 240);
    point.y = (y + 240);
    //println("confining");
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
