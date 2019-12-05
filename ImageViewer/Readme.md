# ImageViewer

A very simple image display program, written in assembly for the C256 Foenix.

The Python script c256img.py takes a 640x480 BMP file and extracts the color
palette to an assembly file palette.s, that contains the color information in a 
form suitable for copying into a color lookup table in Vicky (i.e. in 32-bit GBRA
format). Then it extracts the pixel data from the picture into another assembly file
image.s, suitable for copying directly into video RAM.

NOTE: 64TASS does not like large blocks of data (larger than 65,536 bytes). So the
script breaks the large image file up into bank-sized blocks of assembly data and
sets the program counter sequentially for each block so that each block goes in its
proper page in system RAM for later copying.

The assembly code just copies the color palette to LUT#0 and the image data to video
RAM, after setting the Vicky control registers to cause the bitmap to be displayed.
The assembly code just uses simple copy loops and could use the MVN/MVP instructions
just as well. On the RevC board, it should even be possible to use SDMA to do the
copying.
