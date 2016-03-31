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

    bits-per-color  The desired color bit width (for one color channel)

    split-rows      Split the output in RAM blocks of the specified number of
                    rows. As output is printed to the console, you need to
                    split it to multiple files. For this purpose, ppm2mif
                    places a marker at each start of a RAM file: "##START".
                    You can split the RAM files e.g. using 
                    
                    ppm2mif [ARGS] | csplit -f ram -b '%02d.mif' -z - '/##START/' '{*}'

### Example ###
	
	Convert image to PNM (e.g. GIMP -> File - Export As -> PNM image (*.PNM) -> Data formatting: ASCII -> Export)
	Example for a 128x32 upper halfimage (128x16): $ ./pnm2mif 128 32 0 < testimage_128x32.pnm > testimage_128x32_upper.mif
	Example for a 128x32 lower halfimage (128x16): $ ./pnm2mif 128 32 1 < testimage_128x32.pnm > testimage_128x32_lower.mif
   