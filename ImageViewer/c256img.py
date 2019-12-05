#
# Convert an image for the C256
#

from PIL import Image

with Image.open("Pepeshan.bmp") as im:
    with open("src/palette.s", "w") as palette_file:
        palette_file.write("LUT_START\n")
        palette = im.getpalette()
        while palette:
            r = palette.pop(0)
            g = palette.pop(0)
            b = palette.pop(0)
            palette_file.write(".byte {}, {}, {}, 0\n".format(b, g, r))
        palette_file.write("\nLUT_END = *")


    count = 0
    line = ""

    with open("src/image.s", "w") as image_file:
        (w, h) = im.size
        for v in range(0, h):
            for u in range(0, w):
                pixel = im.getpixel((u, v))
                if count % 65536 == 0:
                    address = 0x110000 + count
                    image_file.write("\n* = ${:x}".format(address))
                    if count == 0:
                        image_file.write("\nIMG_START = *")
                if count % 16 == 0:
                    image_file.write("\n.byte {}".format(pixel))
                else:
                    image_file.write(", {}".format(pixel))
                count = count + 1

        image_file.write("\nIMG_END = *")