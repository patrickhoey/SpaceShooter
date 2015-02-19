//Patrick Hoey

import ddf.minim.*;

//ship dimensions
int ship_width = 6;
int ship_height = 10;

//global score variable
int score = 0;

//set the number of enemies to be displayed at once
int numBugs = 10;

//default value for total size of display
int total_size = 640*480;

//display buffers
int[] tempPixels = new int[640*480]; //backbuffer

//Image datatype - supports GIF or JPG
PImage backgroundImage;

//font for display
PFont font;

Minim minim;

//sound effects for game
AudioPlayer shoot;
AudioPlayer endgame;
AudioPlayer explosion;
AudioPlayer shield_sound;
AudioPlayer hit_sound;
AudioPlayer background_loop;

boolean isDestroyed = false;

//enemy bugs
Bug bugs[] = new Bug[numBugs];
//main ship
Ship ship = new Ship();
//missle from ship
Missile missile = new Missile();
//shield
Shield shield = new Shield();

//initialization function
void setup() {

//set up the display
  size(640, 480);
  colorMode(RGB);
  background(0);

  //initialize image data
  backgroundImage = loadImage("supernova_640x480.png");
 
  
   //a little optimization so that the size of display does not get recomputed
   //everytime it checks in a loop 
   total_size = width*height;

  //init font
  font = loadFont("OCR-B.vlw.gz");
  textFont(font, 20);
  //hint(ENABLE_OPENGL_4X_SMOOTH);

  //init sounds
  minim = new Minim(this);
  shoot = minim.loadFile("laser.mp3");
  endgame = minim.loadFile("endgame.mp3");
  explosion = minim.loadFile("explosion.mp3");
  shield_sound = minim.loadFile("shield.mp3");
  hit_sound = minim.loadFile("enemy_hit.mp3");
  background_loop = minim.loadFile("background_loop.mp3");

  //System.out.println("Length of sample is " + shoot.length());
 
  //play background music
  background_loop.loop();
  //background_loop.play();

  //copy contents of image to array
  for(int i =0; i < total_size; i++) {
    tempPixels[i] = backgroundImage.pixels[i];
  }
  // Init bugs
  for(int i = 0; i < numBugs; i++) {
    bugs[i] = new Bug();
  }

  rectMode(CENTER);
  noStroke();
}

//main game loop
void draw() {
  //clear background each frame
  background(0);
 
  if( false == isDestroyed ){
      image(backgroundImage, 0, 0, width, height);
  }
  
//display the shield object
  shield.display();

  fill(255,255,255);
  text("Score: " + score, 10,20);

  int i = 0;
  int firstElement = 0;
  int lastElement = (total_size - width);
  int middleElement = ( (total_size)/2  );

  backgroundImage.loadPixels();

  //copy last element to first element in temp array
  for(i = lastElement, firstElement = 0; i < total_size; i++, firstElement++) {
      tempPixels[firstElement] = backgroundImage.pixels[i];
  }
  
  //System.out.println(" i for first element: " + i + " first element " + firstElement );

  int secondElement = width;
  //copy rest data in temp array (back buffer)
  for( i = 0; i < total_size && secondElement < total_size; i++, secondElement++){
      tempPixels[secondElement] = backgroundImage.pixels[i];
  }

  
  //copy entire temp array to dataPixel array (display buffer)
  for( i = 0; i < total_size; i++){
      backgroundImage.pixels[i] = tempPixels[i];
  }
  backgroundImage.updatePixels();

//display ship
  ship.display();

//this loop is for moving the enemies on the screen
//this also checks for collision with ship to modify shield object
  for( i = 0; i < numBugs; i++) {
    bugs[i].display();
    bugs[i].move();
    
    //System.out.println("Created: " + bugs[i].bug_x + "," + bugs[i].bug_y);
    
    if( bugs[i].collision == true ) {
      if( shield.shield_hit > 0 ) {
        shield.shield_hit--;
        bugs[i].collision = false;
        shield_sound.rewind();
        shield_sound.play();
      }else{
        background_loop.pause();
        explosion.play();
        endgame.play();
        ship.destroyed();
      }
    }

//this is the main collision detection for when the missile object
//hits the enemy bug
    if( missile.fired == true
    && missile.missile_y <= bugs[i].bug_y
    && missile.missile_x  > bugs[i].bug_x - bugs[i].bug_size
    && missile.missile_x  < bugs[i].bug_x + bugs[i].bug_size ) {
      bugs[i].bug_x = random(width, 0);
      bugs[i].bug_y = -height/2 - bugs[i].bug_size;
      bugs[i].dx = 0;
      score++;
      missile.fired = false;
      hit_sound.rewind();
      hit_sound.play();
    }
  }

//this determines if ship can fire missile or not
  if( ship.destroyed == false
  && mousePressed == true
  && missile.fired == false) {
    missile.fired = true;
    missile.display(ship.top_left_X, ship.top_left_Y);
    shoot.rewind();
    shoot.play();
  }

//increments the missile object location if it was fired
  if( missile.fired == true ) {
    missile.fire();
  }

  //fill back to a default so background is not affected
  //fill(255);
}

//this is the shield object class
class Shield {
  float shield_x;
  float shield_y;
  float shield_width;
  float shield_height;
  int shield_hit;

  Shield() {
    shield_x = 20;
    shield_y = 35;
    shield_width = 20;
    shield_height = 10;
    shield_hit = 3;
  }

  void display() {
    if( shield_hit == 3)
    fill(1,1,255);
    else if( shield_hit == 2)
    fill(255,255,1);
    else if( shield_hit == 1)
    fill(255,1,1);
    else
    noFill();

    rect(this.shield_x, this.shield_y, this.shield_width, this.shield_height);

  }

} //end class Shield

//this is the missile object class
class Missile {
  float missile_x;
  float missile_y;
  float missile_size;
  float missile_dir;
  float ship_X;
  float ship_Y;
  boolean fired;

  Missile() {
    missile_x = 0;
    missile_y = 0;
    missile_size = 5;
    missile_dir = 20;
    ship_X = 0;
    ship_Y = 0;
    fired = false;
  }

  void display(float ship_X, float ship_Y) {
    missile_x = ship_X + (ship_width/2);
    missile_y = ship_Y - ship_height;

    fill(1,1,255);
    ellipse(this.missile_x, this.missile_y, this.missile_size, this.missile_size);
  }

  void display() {
    fill(1,1,255);
    ellipse(this.missile_x, this.missile_y, this.missile_size, this.missile_size);
  }

  void fire() {
    missile_y -= missile_dir;
    this.display();
    this.collision();
  }

  void collision() {

    //check collision with top wall
    if ( missile_y < missile_size) {
      this.fired = false;
    }
  }

} //class Missile


//this is the ship object class
class Ship {
  float top_left_X;
  float top_left_Y;
  float shipX;
  boolean destroyed;

  Ship() {
    shipX = 0.0;
    top_left_X = 0;
    top_left_Y = 0;
    destroyed = false;
  }

  void destroyed() {
    destroyed = true;
    isDestroyed = true;
    fill(0,0,0);
    rect(0,0,width, height);
    fill(255,255,255);
    textFont(font, 30);
    text("Your ship is Destroyed", 50 , height / 2 );
    text("Please try again...", 50, (height/2) + 30 );
  }

  void display() {
    //draw ship
    fill(255,1,1);
    shipX = constrain(mouseX, ship_width , width);
    rect(shipX, height, ship_width, ship_height);

    top_left_X = shipX - ship_width;
    top_left_Y = height-ship_height;
    triangle(top_left_X, top_left_Y,                        //point 1
    top_left_X+ship_width, (top_left_Y)-ship_height,  //point 2
    top_left_X+(ship_width*2), top_left_Y);                  //point 3
    rect(shipX, height, ship_width*3, ship_height/2);
  } //end display

} //end of class Ship


//this is the enemy object class
class Bug {
  float bug_x;
  float bug_y;
  float bug_dir;
  float bug_size;
  float dx;
  float bug_col;
  boolean collision;

  Bug() {
    bug_x = (int)random(width);
    bug_y = (int)random(height);
    bug_dir = random(2,5);
    bug_col = 0;
    bug_size = 10;
    dx = 0;
    collision = false;
  }

  void display() {
    //draw bugs
    fill(1,255,1);
    ellipse(this.bug_x, this.bug_y, this.bug_size, this.bug_size);
  }

  void move() {
    bug_x += dx;
    bug_y += bug_dir;
    
    //System.out.println("Current bug: " + bug_x + "," + bug_y);

    this.clip();
    this.collision();
  }//end move

  void clip() {
    //if bug is off the bottom of screen
    if( bug_y > height+bug_size ) {
      //System.out.println("Clip bug before: " + bug_x + "," + bug_y);
      bug_x = random(2, width-2);
      bug_y = -height/2 - bug_size;
      //System.out.println("Clip bug after: " + bug_x + "," + bug_y);
      dx = 0;
    }
  }

  void collision() {
    bug_col = height - ship_height;

    //collision with the ship object
    if( bug_y >= bug_col
    && bug_x > mouseX - ship_width - bug_size
    && bug_x < mouseX + ship_width + bug_size ) {
      bug_dir *= -1;
      collision = true;
      //if the x coord is different then previous means that the mouse moved
      //so change the x coord on the object
      if(mouseX != pmouseX ) {
        dx = (mouseX-pmouseX)/2.0;
        if(dx > 5 )
        dx = 5;
        if(dx < -5 )
        dx = -5;
      }

    }

    //check collision with top wall
    if ( bug_y < bug_size && bug_dir < 0) {
      bug_dir *= -1;
      //System.out.println("Collision with top wall");
    }

    //check with collisions on right wall
    if ( bug_x > (width - bug_size) ) {
      dx *= -1;
      //System.out.println("Collision with right wall");
    }
    //check collision with left wall
    if( bug_x < bug_size ) {
      dx *= -1;
      //System.out.println("Collision with left wall");
    }

  }//end collision

} //end of class


