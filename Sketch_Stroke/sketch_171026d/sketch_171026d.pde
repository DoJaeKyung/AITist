import processing.serial.*;

Serial myPort;        // The serial port
int[] val = new int[128];
int colorByAmplitude;
PImage img;
int imgIndex = 0;


void nextImage() {
  background(255);
  loop();
  frameCount = 0;
  img = loadImage("gongU.jpg");
  img.loadPixels();
}


void paintStroke(float strokeLength, color strokeColor, int strokeThickness) {
  float stepLength = strokeLength/4.0;
  
  // Determines if the stroke is curved. A straight line is 0.
  float tangent1 = 0;
  float tangent2 = 0;
  
  float odds = random(1.0);
  
  if (odds < 0.7) {
    tangent1 = random(-strokeLength, strokeLength);
    tangent2 = random(-strokeLength, strokeLength);
  } 
  
  // Draw a big stroke
  noFill();
  stroke(strokeColor);
  strokeWeight(strokeThickness);
  curve(tangent1, -stepLength*2, 0, -stepLength, 0, stepLength, tangent2, stepLength*2);
  
  int z = 1;
  
  // Draw stroke's details
  for (int num = strokeThickness; num > 0; num --) {
    float offset = random(-50, 25);
    color newColor = color(red(strokeColor)+offset, green(strokeColor)+offset, blue(strokeColor)+offset, random(100, 255));
    
    stroke(newColor);
    strokeWeight((int)random(0, 3));
    curve(tangent1, -stepLength*2, z-strokeThickness/2, -stepLength*random(0.9, 1.1), z-strokeThickness/2, stepLength*random(0.9, 1.1), tangent2, stepLength*2);
    
    z += 1;
  }
}

void setup() {
    size(950, 700);
  
  myPort = new Serial(this, "COM3", 9600);
  
  // don't generate a serialEvent() unless you get a newline character:
  myPort.bufferUntil('\n');  
  nextImage();
}



void draw() {
  translate(width/2, height/2);
  
  int index = 0;
  
  for (int y = 0; y < img.height; y+=1) {
    for (int x = 0; x < img.width; x+=1) {
      int odds = (int)random(20000);
      if (odds < 1) {
        color pixelColor = img.pixels[index];
        pixelColor = color(red(pixelColor), green(pixelColor), blue(pixelColor), 100);
        
        if(index % 10 == 0){
         pixelColor = color(red(colorByAmplitude), green(colorByAmplitude), blue(colorByAmplitude), 100);
        }
        pushMatrix();
        translate(x-img.width/2, y-img.height/2);
        rotate(radians(random(-90, 90)));
        
        // Paint by layers from rough strokes to finer details
        if (frameCount < 20) {
          // Big rough strokes
          paintStroke(random(150, 250), pixelColor, (int)random(20, 40));
        } else if (frameCount < 50) {
          // Thick strokes
          paintStroke(random(75, 125), pixelColor, (int)random(8, 12));
        } else if (frameCount < 300) {
          // Small strokes
          paintStroke(random(30, 60), pixelColor, (int)random(1, 4));
        } else if (frameCount < 350) {
          // Big dots
          paintStroke(random(5, 20), pixelColor, (int)random(5, 15));
        } else if (frameCount < 600) {
          // Small dots
          paintStroke(random(1, 10), pixelColor, (int)random(1, 7));
        }
        
        popMatrix();
      }
      
      index += 1;
    }
  }
  
  if (frameCount > 600) {
    noLoop();
  }
}


void mousePressed() {
  nextImage();
}
////////////////
void serialEvent (Serial myPort) {
  try{
  //아두이노의 센서값을 Byte단위로 넘겨 받음.
      byte[] inByte = new byte[400];
      myPort.readBytesUntil('\n',inByte);
        // convert to an int and map to the screen height:
        for(int i = 0; i<128; i++){
         //val[i]에 넘겨 받은 센서값을 저장
         val[i] = int(inByte[i]);
         //잡음을 제외한 주파수 측정. 일정 수준 이상의 주파수가 연속적으로 측정되었을때 
         //그것을 잡음을 제외한 우리가 측정하고자 하는 주파수라고 생각.  
         if(val[i] > 155 && val[i+1] > 155 && val[i+1] > 155 && i < 126 && i !=0 )
         {
            colorByAmplitude = setColor((i*390*2/45)+380);
         }
        }
       
        redraw();

  }catch(Exception e){
    println("Err");
  }
}

int setColor(int inputValue) // 파장에서 RGB를 매칭시키는 함수. 'Dan Bruton'의 매핑 함수 참고
{
  int waveLength, result;
  double R = 0, G = 0, B = 0, c;
  String hexNum;
  
  waveLength = inputValue; // getValue from serialEvent
  //파장을 380-780사이로 측정. 에러검출
  if (waveLength < 380 || waveLength > 780){ 
    //get.value = "Wrong range! (380~780 nm) must be wavelength range";  
  } else if (waveLength < 440){ 
    R = (440-waveLength)/(440-380); 
    G = 0; 
    B = 1; 
  } else if (waveLength < 490){ 
    R = 0; 
    G = (waveLength-440)/(490-440); 
    B = 1; 
  } else if (waveLength < 510){ 
    R = 0; 
    G = 1; 
    B = (510-waveLength)/(510-490); 
  } else if (waveLength < 580){ 
    R = (waveLength-510)/(580-510); 
    G = 1; 
    B = 0; 
  } else if (waveLength < 645){ 
    R = 1; 
    G = (645-waveLength)/(645-580); 
    B = 0; 
  } else { 
    /* (waveLength <=780) */ 
    R = 1; 
    G = 0; 
    B = 0; 
  }

  if (waveLength > 700){ 
    c = 0.3 + (0.7*((780-waveLength)/80)); 
    R *= c; 
    G *= c; 
    B *= c;
  }
  
  if (waveLength < 420){ 
    c = 0.3 + (0.7*((waveLength-380)/40)); 
    R *= c; 
    G *= c; 
    B *= c;
  }
  //측정한 RGB값을 16진수로 나타냄
  //그 후 각각의 값을 더함
  //##172346,이런식으로 표현하기 위함
  hexNum = toHex(R) + toHex(G) + toHex(B);
  print(hexNum);
  print('\n');
  
  result = unhex(hexNum);
  return result;
}
//16진수 변환 함수
String toHex(double x) {
  int value;
  String result;
  
  x = Math.floor(x*255);
  value = (int)x;
  result = hex(value, 2);
  
  return result;
}
