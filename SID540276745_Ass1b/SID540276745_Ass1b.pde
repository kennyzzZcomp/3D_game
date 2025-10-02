// SID: 540276745
// Assignment 1b
// === Globals ===
final float W = 800, H = 600, D = 1500;
final float GRAV = 800;  // Reduced gravity for better ball bouncing
final float REST_WALL = 0.65;
final float REST_BALL = 0.75;
final float LIN_DAMP = 0.03;  // Low damping - maintains more momentum
final float ANG_DAMP = 0.12;

ArrayList<Ball> balls;
PImage[] textures;

void setup() {
  size(1280, 720, P3D);  
  
  balls = new ArrayList<Ball>();
  
  textures = new PImage[3];
  
  // Load texture images
  String[] textureFiles = {"Wood.jpg", "Metal.jpg", "Rock.jpg"};
  int loadedCount = 0;
  
  for (int i = 0; i < textureFiles.length; i++) {
    try {
      textures[i] = loadImage(textureFiles[i]);
      if (textures[i] != null) {
        println("✓ Loaded: " + textureFiles[i]);
        loadedCount++;
      } else {
        println("✗ Failed to load: " + textureFiles[i]);
      }
    } catch (Exception e) {
      println("✗ Error loading: " + textureFiles[i]);
      textures[i] = null;
    }
  }
  
  println("Loaded " + loadedCount + " out of 3 textures");
  if (loadedCount == 0) {
    println("No textures found - balls will use solid colors");
  }
  
  println("Setup complete! Click anywhere to shoot balls into the cube.");
}

void draw(){
    background(20, 20, 40);  
    lights();
    
    camera(0, 0, D - 200, 
           0, 0, 0,               
           0, 1, 0);              
    
    drawBoundaries();

    for(int i = balls.size() - 1; i >= 0; i--){
        Ball b = balls.get(i);
        b.update();
        
        if(b.isOutOfBounds()) {
            balls.remove(i); 
            println("Ball flew away and removed");
        } else {
            b.draw(); 
        }
    }
    
    // Detect ball-to-ball collisions
    for(int i = 0; i < balls.size(); i++) {
        for(int j = i + 1; j < balls.size(); j++) {
            Ball ball1 = balls.get(i);
            Ball ball2 = balls.get(j);
            ball1.checkBallCollision(ball2);
        }
    }
    
    displayInfo();
}

class Ball{
    PVector pos;
    PVector vel;           // Velocity
    PVector acc;           // Acceleration
    PVector angularVel;    // Angular velocity (rotation)
    PVector rotation;      // Current rotation angle
    PVector initialBoost;  // Initial boost
    int boostFrames;       // Boost duration in frames
    int currentFrame;      // Current frame count
    int collisionCount;    // Collision count
    float energyLevel;     // Energy level (0-1)
    boolean isResting;     // Is resting
    float r;
    PImage texture;
    int textureIndex;
    color ballColor;
    PShape ball3D;  // 3D ball object
    
    Ball(PVector pos, PVector velocity, float radius){
        this.pos = pos.copy();
        this.vel = new PVector(0, 0, 0);  // initial velocity is zero
        this.acc = new PVector(0, 0, 0);
        this.rotation = new PVector(0, 0, 0);
        this.initialBoost = velocity.copy(); 
        
        PVector normalizedDir = velocity.copy();
        normalizedDir.normalize();
        
        this.angularVel = new PVector(
            normalizedDir.z * 6 + random(-1, 1),  
            -normalizedDir.x * 6 + random(-1, 1), 
            normalizedDir.y * 6 + random(-1, 1)   
        );
        this.boostFrames = 10;  // Boost duration in frames
        this.currentFrame = 0;
        this.collisionCount = 0;
        this.energyLevel = 1.0;  // Full energy at start
        this.isResting = false;
        this.r = radius;
        
        // Randomly select texture
        this.textureIndex = int(random(textures.length));
        this.texture = textures[textureIndex];

        // Set fallback color (if texture fails to load)
        switch(textureIndex) {
            case 0: ballColor = color(255, 140, 0); break;   // Orange - Basketball
            case 1: ballColor = color(255, 255, 255); break; // White - Volleyball
            case 2: ballColor = color(139, 69, 19); break;   // Brown - Soccer
            default: ballColor = color(random(100, 255), random(100, 255), random(100, 255));
        }

        // Create textured 3D sphere
        createTexturedSphere();
    }
    
    void createTexturedSphere() {
        // Create sphere geometry
        int detail = 30; // Sphere detail level
        ball3D = createShape();
        ball3D.beginShape(TRIANGLES);
        
        if (texture != null) {
            ball3D.texture(texture);
            ball3D.fill(255); // Use white to preserve texture colors
        } else {
            ball3D.fill(ballColor);
        }
        
        ball3D.noStroke();
        
        // Generate sphere vertices and texture coordinates
        for (int i = 0; i < detail; i++) {
            float lat1 = map(i, 0, detail, -PI/2, PI/2);
            float lat2 = map(i+1, 0, detail, -PI/2, PI/2);
            
            for (int j = 0; j < detail*2; j++) {
                float lon1 = map(j, 0, detail*2, -PI, PI);
                float lon2 = map(j+1, 0, detail*2, -PI, PI);
                
                // Calculate sphere coordinates
                PVector p1 = spherePoint(lat1, lon1);
                PVector p2 = spherePoint(lat2, lon1);
                PVector p3 = spherePoint(lat1, lon2);
                PVector p4 = spherePoint(lat2, lon2);
                
                float u1 = map(j, 0, detail*2, 0, texture != null ? texture.width : 1);
                float u2 = map(j+1, 0, detail*2, 0, texture != null ? texture.width : 1);
                float v1 = map(i, 0, detail, 0, texture != null ? texture.height : 1);
                float v2 = map(i+1, 0, detail, 0, texture != null ? texture.height : 1);
                // First triangle
                ball3D.vertex(p1.x * r, p1.y * r, p1.z * r, u1, v1);
                ball3D.vertex(p2.x * r, p2.y * r, p2.z * r, u1, v2);
                ball3D.vertex(p3.x * r, p3.y * r, p3.z * r, u2, v1);

                // Second triangle
                ball3D.vertex(p3.x * r, p3.y * r, p3.z * r, u2, v1);
                ball3D.vertex(p2.x * r, p2.y * r, p2.z * r, u1, v2);
                ball3D.vertex(p4.x * r, p4.y * r, p4.z * r, u2, v2);
            }
        }
        
        ball3D.endShape();
    }
    
    PVector spherePoint(float lat, float lon) {
        float x = cos(lat) * cos(lon);
        float y = sin(lat);
        float z = cos(lat) * sin(lon);
        return new PVector(x, y, z);
    }
    
    void update() {
        // If already resting, no need to update physics
        if (isResting) {
            return;
        }

        // Reset acceleration
        acc.set(0, 0, 0);

        // Apply gravity
        acc.y = GRAV / 50.0;

        // Apply initial boost (first few frames)
        if (currentFrame < boostFrames) {
            // Calculate boost decay - start strong, gradually weaken
            float boostPower = map(currentFrame, 0, boostFrames, 1.0, 0.0);
            PVector boost = PVector.mult(initialBoost, boostPower * 0.3f); // Super strong initial boost!
            acc.add(boost);

            // Display boost status
            if (currentFrame == 0) {
                println("Initial boost: " + boost.mag());
            }
        }
        
        currentFrame++;

        // Update linear physics
        vel.add(acc);
        
        energyLevel *= 0.999f; 
        float dampingFactor = LIN_DAMP + (1 - energyLevel) * 0.05f; 
        vel.mult(1 - dampingFactor);
        
        pos.add(PVector.mult(vel, 1.0f/60)); 
        
        angularVel.mult(1 - ANG_DAMP - (1 - energyLevel) * 0.02f); 
        rotation.add(PVector.mult(angularVel, 1.0f/60));
        
        checkBoundaryCollisions();
        
        checkRestingState();
        
        acc.mult(0);
    }
    
    // Check if ball should enter resting state
    void checkRestingState() {
        // If ball is near ground, low velocity, and low energy, enter resting state
        boolean nearGround = (pos.y >= H/2 - r - 5);
        boolean lowVelocity = (vel.mag() < 50);
        boolean lowEnergy = (energyLevel < 0.3f);
        boolean lowRotation = (angularVel.mag() < 1.0f);
        
        if (nearGround && lowVelocity && lowEnergy && lowRotation) {
            isResting = true;
            vel.set(0, 0, 0);
            angularVel.set(0, 0, 0);
            pos.y = H/2 - r; // Ensure ball is on the ground
            println("Ball came to rest after " + collisionCount + " collisions");
        }
    }
    
    // Check if ball is still within screen bounds
    boolean isOutOfBounds() {
        // Only consider out of bounds if ball flies too far (front/back) or falls too low
        return (pos.z < -D/2 - 300 || pos.z > D/2 + 300 || 
                pos.y > H/2 + 300 || 
                pos.x < -W/2 - 300 || pos.x > W/2 + 300);
    }
    
    void checkBoundaryCollisions() {
        boolean hasCollided = false;
        
        // Left/Right wall collision - generate realistic rotation effect
        if (pos.x - r <= -W/2) {
            pos.x = -W/2 + r;
            float impactVel = abs(vel.x);
            vel.x *= -REST_WALL;
            
            // Generate rotation based on collision speed and direction
            float spinStrength = impactVel * 0.02f;
            angularVel.y += vel.z * spinStrength; // Z velocity affects Y-axis rotation
            angularVel.z -= vel.y * spinStrength; // Y velocity affects Z-axis rotation
            hasCollided = true;
        } else if (pos.x + r >= W/2) {
            pos.x = W/2 - r;
            float impactVel = abs(vel.x);
            vel.x *= -REST_WALL;
            
            float spinStrength = impactVel * 0.02f;
            angularVel.y -= vel.z * spinStrength;
            angularVel.z += vel.y * spinStrength;
            hasCollided = true;
        }
        
        // Up/Down wall collision - ceiling and ground
        if (pos.y - r <= -H/2) {
            pos.y = -H/2 + r;
            float impactVel = abs(vel.y);
            vel.y *= -REST_WALL;
            
            float spinStrength = impactVel * 0.02f;
            angularVel.x += vel.z * spinStrength; // Z velocity affects X-axis rotation
            angularVel.z -= vel.x * spinStrength; // X velocity affects Z-axis rotation
            hasCollided = true;
        } else if (pos.y + r >= H/2) {
            pos.y = H/2 - r;
            float impactVel = abs(vel.y);
            vel.y *= -REST_WALL;
            
            // Ground collision - generate rolling effect
            float spinStrength = impactVel * 0.025f; // Ground friction is stronger
            angularVel.x -= vel.z * spinStrength; // Forward/backward rolling
            angularVel.z += vel.x * spinStrength; // Left/right rolling
            hasCollided = true;
        }
        
        // Front/Back wall collision
        if (pos.z - r <= -D/2) {
            pos.z = -D/2 + r;
            float impactVel = abs(vel.z);
            vel.z *= -REST_WALL;
            
            float spinStrength = impactVel * 0.02f;
            angularVel.x += vel.y * spinStrength; // Y velocity affects X-axis rotation
            angularVel.y -= vel.x * spinStrength; // X velocity affects Y-axis rotation
            println("Ball hit BACK wall! Collision #" + (collisionCount + 1));
            hasCollided = true;
        } else if (pos.z + r >= D/2) {
            pos.z = D/2 - r;
            float impactVel = abs(vel.z);
            vel.z *= -REST_WALL;
            
            float spinStrength = impactVel * 0.02f;
            angularVel.x -= vel.y * spinStrength;
            angularVel.y += vel.x * spinStrength;
            println("Ball hit FRONT wall! Collision #" + (collisionCount + 1));
            hasCollided = true;
        }
        
        // If collision occurred, increase counter and lose energy
        if (hasCollided) {
            collisionCount++;
            energyLevel *= 0.85f; // Lose 15% energy per collision
            
            // Limit rotation speed
            angularVel.limit(10);
            
            if (collisionCount % 5 == 0) {
                println("Energy level: " + nf(energyLevel * 100, 0, 1) + "%");
            }
        }
    }

    void draw(){
        pushMatrix();
        translate(pos.x, pos.y, pos.z);
        
        // Apply rotation
        rotateX(rotation.x);
        rotateY(rotation.y);
        rotateZ(rotation.z);
        
        if (ball3D != null) {
            // Draw textured sphere
            if (isResting) {
                tint(255, 150); // Resting ball semi-transparent
            } else {
                // Adjust brightness based on energy level
                float brightness = map(energyLevel, 0, 1, 150, 255);
                tint(brightness, brightness, brightness);
            }
            shape(ball3D);
            noTint(); // Reset tint
        } else {
            // Fallback: use simple sphere
            if (texture != null) {
                // Handle case when texture exists but can't use 3D shape
                if (isResting) {
                    fill(255, 150);
                } else {
                    float brightness = map(energyLevel, 0, 1, 150, 255);
                    fill(brightness);
                }
            } else {
                // Resting balls use darker colors
                if (isResting) {
                    fill(red(ballColor) * 0.6f, green(ballColor) * 0.6f, blue(ballColor) * 0.6f);
                } else {
                    fill(ballColor);
                }
            }
            noStroke();
            sphere(r);
        }
        popMatrix();
    }
    
    // Ball-to-ball collision detection and handling
    void checkBallCollision(Ball other) {
        if (this == other) return; // Don't check collision with itself
        
        // Calculate distance between ball centers
        PVector distance = PVector.sub(other.pos, pos);
        float dist = distance.mag();
        float minDist = r + other.r; // Sum of both ball radii
        
        if (dist <= minDist && dist > 0) {
            // Collision occurred!
            println("Ball collision detected! Distance: " + nf(dist, 0, 2));
            
            // Normalize collision direction
            distance.normalize();
            
            // Separate overlapping spheres
            float overlap = minDist - dist;
            PVector separation = PVector.mult(distance, overlap / 2);
            pos.sub(separation);
            other.pos.add(separation);
            
            // Calculate relative velocity
            PVector relativeVel = PVector.sub(vel, other.vel);
            float velAlongNormal = PVector.dot(relativeVel, distance);
            
            // If spheres are separating, don't handle collision
            if (velAlongNormal > 0) return;
            
            // Calculate post-collision velocity change (elastic collision)
            float restitution = REST_BALL; // Use ball collision coefficient
            float impulse = -(1 + restitution) * velAlongNormal;
            impulse /= 2; // Assume equal mass for both balls
            
            PVector impulseVector = PVector.mult(distance, impulse);
            
            // Apply impulse to velocities
            vel.add(impulseVector);
            other.vel.sub(impulseVector);
            
            // Generate rotation effects based on collision
            float spinStrength = abs(impulse) * 0.03f;
            
            // Tangential velocity at collision point generates spin
            PVector tangent = new PVector(-distance.y, distance.x, 0); // Perpendicular to collision direction
            float tangentVel = PVector.dot(relativeVel, tangent);
            
            // Add rotation to both balls
            angularVel.add(PVector.mult(distance, tangentVel * spinStrength));
            other.angularVel.sub(PVector.mult(distance, tangentVel * spinStrength));
            
            // Increase collision count and energy loss
            collisionCount++;
            other.collisionCount++;
            energyLevel *= 0.92f; // Ball collision loses 8% energy
            other.energyLevel *= 0.92f;
            
            // Limit rotation speed
            angularVel.limit(8);
            other.angularVel.limit(8);
        }
    }
}

// Draw cube boundaries
void drawBoundaries() {
    // Define cube boundaries
    float left = -W/2, right = W/2;
    float top = -H/2, bottom = H/2;
    float back = -D/2, front = D/2;
    
    // Draw simple clear cube wireframe
    strokeWeight(2);
    stroke(255, 255, 255); // White lines
    noFill();
    
    // Front frame
    line(left, top, front, right, top, front);      // Front top
    line(right, top, front, right, bottom, front);  // Front right
    line(right, bottom, front, left, bottom, front); // Front bottom
    line(left, bottom, front, left, top, front);    // Front left
    
    // Back frame
    line(left, top, back, right, top, back);         // Back top
    line(right, top, back, right, bottom, back);     // Back right
    line(right, bottom, back, left, bottom, back);   // Back bottom
    line(left, bottom, back, left, top, back);       // Back left
    
    // Connect front and back edges
    line(left, top, front, left, top, back);         // Left top
    line(right, top, front, right, top, back);       // Right top
    line(right, bottom, front, right, bottom, back); // Right bottom
    line(left, bottom, front, left, bottom, back);   // Left bottom
    
    // Emphasize bottom surface - green
    stroke(100, 255, 100);
    line(left, bottom, front, right, bottom, front);
    line(right, bottom, front, right, bottom, back);
    line(right, bottom, back, left, bottom, back);
    line(left, bottom, back, left, bottom, front);
    
    // Add surface labels
    fill(255, 255, 100);
    textAlign(CENTER);
    textSize(20);
    
    // Back label
    text("BACK", 0, 0, back - 20);
    
    // Left/Right surface labels
    text("LEFT", left - 30, 0, 0);
    text("RIGHT", right + 30, 0, 0);
    
    // Top/Bottom surface labels
    text("TOP", 0, top - 30, 0);
    text("BOTTOM", 0, bottom + 30, 0);
}

// Display information
void displayInfo() {
    // Switch to 2D mode for UI display
    camera();
    hint(DISABLE_DEPTH_TEST);
    
    fill(255);
    textAlign(LEFT);
    textSize(16);
    text("Balls: " + balls.size(), 10, 25);
    text("INITIAL BOOST: 2000-4000 (20 frames)", 10, 45);
    text("Gravity: " + GRAV + " (can overcome boost)", 10, 65);
    text("XY boost: 800-1500", 10, 85);
    text("33% explosive launch chance!", 10, 105);
    text("Click anywhere to shoot ball!", 10, 125);
    text("Press 'c' to clear all balls", 10, 145);
    
    // Display texture status
    int loadedTextures = 0;
    for (PImage tex : textures) {
        if (tex != null) loadedTextures++;
    }
    text("Textures loaded: " + loadedTextures + "/3", 10, 165);
    if (loadedTextures > 0) {
        text("✓ Using PNG textures", 10, 185);
    } else {
        text("✗ Using solid colors", 10, 185);
    }
    
    hint(ENABLE_DEPTH_TEST);
}

// Mouse interaction - shoot ball at click position
public void mousePressed() {
    // Convert screen coordinates to world coordinates (click position)
    float worldX = map(mouseX, 0, width, -W/2, W/2);
    float worldY = map(mouseY, 0, height, -H/2, H/2);
    
    // Ball starting position - from cube front wall (inside cube)
    PVector startPos = new PVector(worldX, worldY, D/2 - 20);
    
    // Generate random XY plane direction angle
    float randomAngle = random(0, TWO_PI);
    
    // Initial boost parameters - super strong boost!
    float xyBoost = random(800, 1500);    // XY plane strong boost (increased ~3x)
    float zBoost = random(4000, 8000);    // Z-axis super strong boost (increased 2x)
    
    // 33% chance to generate "explosive ball" - super strong initial boost
    if (random(100) < 33) {
        xyBoost *= 1.5f;
        zBoost *= 1.8f;
        println("EXPLOSIVE LAUNCH! Boost: " + nf(zBoost, 0, 0));
    }
    
    // Calculate initial boost components based on random angle
    float boostX = cos(randomAngle) * xyBoost;
    float boostY = sin(randomAngle) * xyBoost;
    float boostZ = -zBoost;  // Negative Z = fly backward
    
    // Create initial boost vector
    PVector initialBoost = new PVector(boostX, boostY, boostZ);
    
    // Random ball size
    float radius = random(15, 35);
    
    // Create and shoot ball (using initial boost)
    Ball newBall = new Ball(startPos, initialBoost, radius);
    balls.add(newBall);
    
    println("Ball shot from (" + mouseX + ", " + mouseY + ") -> (" + 
            nf(worldX,0,1) + ", " + nf(worldY,0,1) + ")");
    println("   Random angle: " + nf(degrees(randomAngle),0,1) + "°");
    println("   XY boost: " + nf(xyBoost,0,1) + ", Z boost: " + nf(zBoost,0,1));
    println("   Initial boost: (" + nf(boostX,0,1) + ", " + nf(boostY,0,1) + ", " + nf(boostZ,0,1) + ")");
}

// Keyboard interaction  
public void keyPressed() {
    if (key == 'c' || key == 'C') {
        balls.clear();
        println(" Balls cleared ");
    }
}
