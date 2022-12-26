# Flow Map Editor - CS50 2022 Final Project
## CS50
----
Final project for the CS50x 2022 Intro to Computer Science course

## What is this

A tool for painting 2D vectormaps to be used in video game shaders, written in Lua using the LÖVE framework (https://love2d.org/). 

Vector maps are often used in video game shaders to distort materials and textures. One use case is in flow shaders, which use vector maps to offset a texture in a certain direction to create the appearance of a flowing surface, such as water. As the vector maps encode vectors in images as pixel colors, they can be made in regular image editing software such as Photoshop or Substance Designer. However, they are not dedicated vector editing software, and using them for this admittedly niche purpose can be clunky. This project is intended to make that process a bit easier, with the brush painting its own movement direction instead of a preset color.

## Installation instructions (Windows)

1. Download LÖVE from https://love2d.org/
2. Clone this repository to your computer
3.  1. Drag the folder containing `main.lua` on love.exe
OR
    2. Run `Love.exe` from command line with the directory containing `main.lua` as the argument. e.g. `"C:\path\to\Love.exe" "C:\path\to\project\"`

## Features

### Vector map painting
Use a brush to paint 2D vector maps normalized to 0...1 space. Change properties like spacing and lazy mouse radius to ensure smooth strokes, or change alphas to change the brush shape. Brush can also be set to align to brush direction, as well as to constantly rotate when drawn with. Use right click to erase.

Parameters:
- **Brush Radius:** Brush size
- **Brush Hardness:** Tends the brush alpha towards solid white, aka harder edges
- **Lazy Radius:** Lazy mouse radius. Independent from brush radius. Stabilizes brush movement to produce smoother strokes
- **Spacing:** How closely spaced the brush spots in a stroke are. Lower values = smoother, slower stroke
- **Alpha:** Brush transparency, or 'flow rate'. How faded the stroke is

### Random walkers
Use Random Walkers to draw procedural patterns. Different parameters can produce very different results

Parameters:
- **Walker Count:** How many random walkers are on screen at any time
- **Walker Size Range Min/Max:** The bounds for changing the walker size while it is drawing
- **Turn Range (deg):** The turning limit for the walkers. Degrees signifying a cone pointing straight down. >=360 allows for walkers to make loops
- **Turn Rate (rad/s):** How steep turns the walkers make
- **Change Rate:** Affects how frequent the changes to turn amount and size are
- **Spacing:** Scalar for spacing. Unlike regular brush, spacing for walkers changes dynamically with walker's variable size, so this parameter is for scaling that amount
- **Alpha:** Stroke transparency. Same as with brush

### Live Preview
See the changes made to the vector map on a flow shader in real time.

----

### Filters

#### Blur
A simple box blur. Very slow at the moment

#### Normalize
Force all vectors to unit vectors (length == 1)

----

### File/Document Operations
#### Saving
LÖVE isn't exactly designed for this type of usage, so all images are saved in %appdata%/LOVE/VectorMapPainter/output/. You can save in subdirectories by including the path in the save name (e.g. "subdirectory/filename" will save filename.png into %appdata%/LOVE/VectorMapPainter/output/subdirectory/)

#### Loading
The vector map painter can load in any image in the root folder specified above, as long as the format is supported by LÖVE (png, jpg). Some png files might use compression which messes things up, but resaving them in another program should resolve any issues. Due to the incredibly custom nature of the UI system, the file list menu will go outside window borders when there are enough files, and there is no scrolling implemented. Just a heads up.

#### Resizing
Images can be resized to any 4-digit size, though powers of 2 are recommended. Large sizes also slow down performance

----

### Custom UI system
A UI system created purely for this tool. All UI elements (in `UI/elements.lua`) reside in frame objects (in `UI/frame.lua`), which can be nested inside each other and in other elements as dropdowns. Elements include icon-based buttons, buttons with custom text, text input boxes, dropdown menus, checkboxes, and labels. UI elements also support tooltips. Right clicking an element opens a properties window in case one exists

## Intro Video

TODO

## Images
----
TODO
