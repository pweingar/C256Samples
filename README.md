# C256Samples
A collection of various assembly code samples and experiments to try out different features of the C256 Foenix. These programs were written for the RevB board and may or may not work on the RevC version. I will try to update them as needed.

The code in this project should not be considered production-worthy.
These are little experiments I've written, so they do not have all the error checking and other
qualities you would expect from proper code.
Still, these may be useful as examples of how to get various things working on the C256.

## Included Samples

* BouncingSprite: Display a sprite on the screen and make it bounce around. This demo shows the
    use of sprites, the MVN instruction, and how to use C256 interrupts to animate the sprite in
    synch with the screen refresh to avoid "tearing".

* ImageViewer: Display a picture on the bitmapped graphics screen. This project includes a simple
    Python script to convert a BMP file to assembly files that are included in an assembly program
    that copies the image and color palette to the graphics system.
