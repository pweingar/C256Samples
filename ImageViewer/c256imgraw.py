#
# Convert an image for the C256
#

from PIL import Image
from optparse import OptionParser

parser = OptionParser()
parser.add_option("-i", "--input", dest="input", help="Source image file")
parser.add_option("-p", "--pixmap", dest="pixmap", help="Destination for pixel data.")
parser.add_option("-c", "--color-table", dest="color_table", help="Destination for color data.")

(options, args) = parser.parse_args()

with Image.open(options.input) as im:
    with open(options.color_table, "wb") as palette_file:
        palette = im.getpalette()
        while palette:
            r = palette.pop(0)
            g = palette.pop(0)
            b = palette.pop(0)
            color = bytes([b, g, r, 0])
            palette_file.write(color)

    with open(options.pixmap, "wb") as image_file:
        (w, h) = im.size
        for v in range(0, h):
            for u in range(0, w):
                pixel = im.getpixel((u, v))
                image_file.write(pixel.to_bytes(1, byteorder='little', signed=False))