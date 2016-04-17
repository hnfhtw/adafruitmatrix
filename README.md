# Adafruit RGB LED Panel Framebuffer #

## CHANGELOG: ##
V01: Support only for 1, 2 or 4 panel columns (panels switched in series), but multiple panel rows
V02: Support for 3 or 5 panel columns enabled:
     ctrl.vhd:      Addressing of framebuffer changed from RRRR PP XXXXX to PP RRRR XXXXX
                    (with RRRR = 4 address bits A-D, PP = panel number, XXXXX = 5 Bits for pixel number)
                    Panel counter had to be changed, overflow counter could count only to 2^n
     matrix.vhd:    MIF files had to be changed due to new framebuffer address format.
                    
                    Old format of addresses(example for 128x16 -> upper half of a 128x32 image):
                    0 ....... 31 32 ....... 63 64 ....... 95 96 ....... 127
                    128 .... 159 160 ..... 191 192 ..... 223 224 ...... 255
                    .                                                     .
                    .  Panel 1      Panel 2        Panel 3      Panel 4   .
                    .                                                     .
                    1920 .. 1951 1952 ... 1983 1984 ... 2015 2016 .... 2047
                    
                    New format of addresses(example for 128x16 -> upper half of a 128x32 image):
                    0 ....... 31 512 ..... 543 1024 ... 1055 1536 .... 1567
                    32 ...... 63 544 ..... 575 1056 ... 1087 1568 .... 1599	
                    .                                                     .
                    .  Panel 1      Panel 2        Panel 3      Panel 4   .
                    .                                                     .
                    480 ..... 511 992 ... 1023 1504 ... 1535 2016 .... 2047

V03: Reservation of unused RAM avoided:
     testram.vhd:    Generic ADDR_WIDTH exchanged with DATA_RANGE -> memory_t array changed from 2^ADDR_WIDTH
                     to the actual needed value given by DATA_RANGE
     matrix.vhd:     Adaptions for the ADDR_WIDHT -> DATA_RANGE changed
                     First signal definitions for RGB data decoder which fills the framebuffers

V04: RGB data decoder implemented which sets the s_we signal for the correct framebuffer.
     matrix.vhd:     Decoder code implemented
     Example for 4x4 Panels: Input address format s_waddr_i = PP TTT RRRR XXXXX -> PP = panel column number, TTT = panel row number, RRRR = pixel row number, XXXXX = pixel column number
                             Output address format s_waddr = PP RRRR XXXXX and s_we(TTT) -> set write address at all framebuffers but activate only the correct one for writing
     -> the 24 Bit wide data input s_data_i, the write clock s_wclk_i and the relevant parts of s_waddr_i are directly connected to all framebuffers
     -> writing this data to the correct framebuffer is ensued by the decoder which evaluates the TTT part of the input address s_waddr_i
     Testbench updated to test the decoder in modelsim (matrix_tb.vhd, compile.do and sim.do updated)

V05: Testbench updated to test LED panel driver
     1 Pixel shift fixed - LATCH signal needed to come 1 clk period earlier
     Pin Assignments changed to support 4 Panel Rows

V06: UART receiver added, clock changed from 40MHz to 30MHz to decrease distortions, gamma correction temporarily deactivated, bug fixed: R and B were mixed in earlier versions -> old ppm2mif and pnm2mif 
     scripts generated framebuffer data in format GBR (instead of RGB) -> pnm2mif script adapted to get correct output (RGB -> Bit 7 to Bit 0 is blue), additionally in matrix.vhd the process RGB01_output_signals
     adapted to get the correct signals to the RGB0/1 outputs.
     matrix.vhd: 	UART receiver added, BGR -> RGB bug fixed
     ctrl.vhd:		Gamma correction deactivated
     -> Drawing and data streaming is now possible with the 6 Byte RGB protocol consisting of: X Y R G B CS (X = X coordinate of pixel, Y = Y coordinate, R, G, B, and checksum CS which is XOR of all 5 prior Bytes)
     
V06a: pnm2mif script updated to generate MIF files with reduced color depths
     
## TODO: ##
Tidy up rtl/ctrl.vhd
     -> 1 counter module, 4 instantiations
     -> check counter, currently BCM Bit 0 is written to the wrong (previous) RGB pixel row address (A-D)


## LAST MODIFIED: ##
V01: 30.03.2016
V02: 31.03.2016
V03: 01.04.2016
V04: 01.04.2016
V05: 12.04.2016
V06: 15.04.2016
V06a: 17.04.2016