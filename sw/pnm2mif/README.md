# pnm2mif #

Converts a *.PNM image (width x 32) to two Quartus MIF files (alligned for memory addressing format:
PP RRRR XXXXX, PP = Panel Number, RRRR = Pixel Row Address A-D, XXXXX = Pixel Column Number (0 to 31))
Currently only images with height = 32 and color depth = 8 Bit per color are supported.

## Building ##

    $ make clean && make

## Getting Started ##

Input is read from `stdin`, output is written to to `stdout`.

Initialization files for a `3 * 8 Bit` wide RAM are generated.

The colors are packed the following way:

    N = Color Bit Width (currently only 8 Bit supported)

    3N-1     2N-1     N-1      0
    |        |        |        |
    |  RED   |  GREEN |  BLUE  |
    +--------+--------+--------+
    |N  ..  0|N  ..  0|N  ..  0|
    +--------+--------+--------+

### Usage ###

    $ ./pnm2mif [width] [height] [0 or 1 (for upper or lower halfimage)] < inputfilename.pnm > outputfilename.mif

    width           Width of the image in pixels (64, 96, 128)

    height          Height of the image in pixels (currently only 32 supported)
	
	0 or 1			0 creates the *.mif file for the upper half panel, 1 for the lower half panel -> two executions of pnm2mif needed for one image
                   

### Example ###
	
	Convert image to PNM (e.g. GIMP -> File - Export As -> PNM image (*.PNM) -> Data formatting: ASCII -> Export)
	Example for a 128x32 upper halfimage (128x16): $ ./pnm2mif 128 32 0 < testimage_128x32.pnm > testimage_128x32_upper.mif
	Example for a 128x32 lower halfimage (128x16): $ ./pnm2mif 128 32 1 < testimage_128x32.pnm > testimage_128x32_lower.mif
   