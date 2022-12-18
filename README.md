# Flow Map Editor - CS50 2022 Final Project
## CS50
----
Work in progress final project for the CS50x 2022 Intro to Computer Science course

## What is this

A software for painting 2D vectormaps to be used in video game shaders, using the LÖVE framework (https://love2d.org/). 

----

Vector maps are often used in video game shaders to distort materials and textures. One use case is in flow shaders, which use vector maps to offset a texture in a certain direction to create the appearance of a flowing surface, such as water. As the vector maps encode vectors in images as pixel colors, they can be made in regular image editing software such as Photoshop or Substance Designer. However, they are not dedicated vector editing software, and using them for this admittedly niche purpose can be clunky. This project is intended to make that process a bit easier, with the brush painting its own movement direction instead of a preset color.

## Features

#### Vector map painting
Use a brush to paint 2D vector maps normalized to 0...1 space. Change properties like spacing and lazy mouse radius to ensure smooth strokes. You can also draw using random walkers to get interesting procedural patterns.

----

### Filters

#### Blur
A simple box blur. Very slow at the moment

#### Normalize
Force all vectors to unit vectors (length = 1)

----

### File/Document Operations
#### Saving
LÖVE isn't exactly designed for this type of usage, so all images are saved in %appdata%/LOVE/VectorMapPainter/output/. You can save in subdirectories by including the path in the save name (e.g. "subdirectory/filename" will save filename.png into %appdata%/LOVE/VectorMapPainter/output/subdirectory/)

#### Loading
The vector map painter can load in any image in the root folder specified above, as long as the format is supported by LÖVE (png, jpg). Some png files might use compression which messes things up, but resaving them should resolve any issues. Due to the incredibly custom nature of the UI system, the file list menu will go outside window borders when there are enough files, and there is no scrolling implemented. Just a heads up

#### Resizing
Images can be resized to any 4-digit size, though powers of 2 are recommended. Large sizes also slow down performance

----

### Custom UI system
A UI system created purely for this software. All UI elements reside in frame objects, which can be nested inside each other and in other elements as dropdowns. Elements include icon-based buttons, buttons with custom text, text input boxes, and dropdown menus. Right clicking an element opens a properties window in case one exists

## Intro Video

TODO

## Images
----
TODO
