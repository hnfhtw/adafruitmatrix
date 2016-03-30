# ppm2mif #

Converts an input file in PPM format to a Quartus Memory Initialization File
with the given color bit width in packed format.


## Preequisites ##

* libpbm10
* libpbm10-dev

## Building ##

    $ make clean && make

## Getting Started ##

Input is read from `stdin`, output is written to to `stdout`.

Initialization files for a `3 * Color Bit Width` wide RAM are generated.

The colors are packed the following way:

    N = Color Bit Width

    3N-1     2N-1     N-1      0
    |        |        |        |
    |  RED   |  GREEN |  BLUE  |
    +--------+--------+--------+
    |N  ..  0|N  ..  0|N  ..  0|
    +--------+--------+--------+

### Usage ###

    $ ppm2mif <bits-per-color> [split-rows] < <infile.ppm> > outfile.mif

    bits-per-color  The desired color bit width (for one color channel)

    split-rows      Split the output in RAM blocks of the specified number of
                    rows. As output is printed to the console, you need to
                    split it to multiple files. For this purpose, ppm2mif
                    places a marker at each start of a RAM file: "##START".
                    You can split the RAM files e.g. using 
                    
                    ppm2mif [ARGS] | csplit -f ram -b '%02d.mif' -z - '/##START/' '{*}'

### Example ###

    $ ./ppm2mif 4 < test.ppm > outfile.mif
