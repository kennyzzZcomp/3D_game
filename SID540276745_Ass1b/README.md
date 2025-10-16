# Assignment 1b Instructions
Usyd assignment
SID: 540276745
Name: Zijian Huang

## File structure

1. All the code are write in one file: "SID5402745_Assignment1b.pde"
```
SID540276745_Ass1b/
├── SID540276745_Assignment1b.pde    # Main program file
├── Bricks.jpg                # Texture1
├── Bricks1.jpg               # Texture2
├── Ground.jpg                # Texture3
├── Metal.jpg                 # Texture4
├── Rock.jpg                  # Texture5
└── Wood.jpg                  # Texture6
```

2. The initial speed of the balls were set at function "mousePressed()". We can find the code "float xyBoost = random(800, 1200)". We make a rundom speed range from 800 to 1200. 
3. We have 33% chance to generate "explosive ball" - super strong initial boost. You will see a really fast ball.

## How to run? 

Software requirement: Processing 3.0 or later version.

### Running the Program
1. Open Processing IDE
2. Click "File" → "Open" and navigate to the project folder
3. Select `SID540276745_Assignment1b.pde` to open the main program file
4. Click the "Run" button (play icon) in the Processing IDE.

### How to Play
- **Click anywhere** on the screen to shoot balls into the 3D cube
- Balls will bounce around with realistic physics
- Different texture materials are applied to the balls
- You can press button "C" to clean all the balls on the screen. 
- The ball will loss all the energy and nerver move when it lying on the groun.