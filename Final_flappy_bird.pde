import processing.serial.*;

Serial myPort;
int distance;
float birdy = 200;
float birdx = 80;

int speed = 2;
boolean gameOver = false;
int score = 0;
int highscore = 0;
boolean sentGameOver = false;

Pipe p1 = new Pipe();
Pipe p2 = new Pipe();
Pipe p3 = new Pipe();

PFont font;

void setup() {
  size(400, 600);
  smooth();
  font = createFont("Arial Bold", 24);
  textFont(font);

  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil('\n');

  p1.x = width + 100;
  p2.x = width + 300;
  p3.x = width + 500;
}

void draw() {
  drawBackground();
  p1.pipe();
  p2.pipe();
  p3.pipe();

  drawBird();
  play();
  checkCollision(p1);
  checkCollision(p2);
  checkCollision(p3);

  if (!gameOver) {
    int minDist = 5;
    int maxDist = 40;
    float mappedY = map(constrain(distance, minDist, maxDist), minDist, maxDist, height - 50, 50);
    birdy = lerp(birdy, mappedY, 0.3);  // Smooth motion
  }
}

void drawBackground() {
  for (int i = 0; i < height; i++) {
    int c = lerpColor(color(135, 206, 250), color(255, 223, 186), map(i, 0, height, 0, 1));
    stroke(c);
    line(0, i, width, i);
  }

  noStroke();
  fill(255, 255, 255, 60);
  ellipse(100, 100, 100, 80);
  ellipse(300, 140, 120, 90);
}

void drawBird() {
  fill(255, 204, 0);
  ellipse(birdx, birdy, 50, 50);
  fill(0);
  ellipse(birdx + 12, birdy - 6, 10, 10);
  fill(0, 0, 0, 50);
  ellipse(birdx + 4, birdy + 4, 50, 50);
}

void play() {
  if (!gameOver) {
    p1.x -= speed;
    p2.x -= speed;
    p3.x -= speed;

    textAlign(CENTER);
    fill(255);
    textSize(30);
    text(score, width / 2, 40);
  } else {
    textSize(20);
    fill(255);
    textAlign(CENTER);
    text("Click to Play Again", width / 2, height / 2 + 10);
    text("Score: " + score, width / 2, height / 2 - 20);
    text("High Score: " + highscore, width / 2, height / 2 - 50);

    if (mousePressed) {
      resetGame();
    }
  }
}

void resetGame() {
  delay(300);
  score = 0;
  gameOver = false;
  sentGameOver = false;
  birdy = 200;

  p1.reset(width + 100);
  p2.reset(width + 300);
  p3.reset(width + 500);

  myPort.write("RESTART\n");
}

void checkCollision(Pipe pipe) {
  if (birdy < pipe.top || birdy > height - pipe.bottom) {
    if (birdx + 25 > pipe.x && birdx - 25 < pipe.x + pipe.w) {
      if (!gameOver) {
        gameOver = true;
        if (!sentGameOver) {
          myPort.write("GAME_OVER\n");
          sentGameOver = true;
        }
        if (score > highscore) {
          highscore = score;
        }
      }
    }
  }

  if (!gameOver && !pipe.passed && pipe.x + pipe.w < birdx) {
    pipe.passed = true;
    score++;
    myPort.write("CLEAR\n");
  }
}

void serialEvent(Serial myPort) {
  String inData = myPort.readStringUntil('\n');
  if (inData != null) {
    inData = trim(inData);
    if (inData.matches("\\d+")) {
      distance = int(inData);
    }
  }
}

class Pipe {
  float top;
  float bottom;
  float gap = 180;
  float x;
  float w = 70;
  boolean passed = false;
  color pipeColor = color(76, 187, 23);

  Pipe() {
    x = width + 150;
    randomize();
  }

  void pipe() {
    noStroke();
    fill(pipeColor);
    rect(x, 0, w, top, 15);
    rect(x, height - bottom, w, bottom, 15);

    if (x < -w) {
      reset(width + 100);
    }
  }

  void reset(float newX) {
    x = newX;
    passed = false;
    randomize();
  }

  void randomize() {
    float center = random(180, height - 180);
    top = center - gap / 2;
    bottom = height - (center + gap / 2);
  }
}
