# Adafruit RGB LED Panel Framebuffer #

## CHANGELOG: ##
```
V01: Support only for 1, 2 or 4 panel columns (panels switched in series), but multiple panel rows
```
```
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
```
```
V03: Reservation of unused RAM avoided:
     testram.vhd:    Generic ADDR_WIDTH exchanged with DATA_RANGE -> memory_t array changed from 2^ADDR_WIDTH
                     to the actual needed value given by DATA_RANGE
     matrix.vhd:     Adaptions for the ADDR_WIDHT -> DATA_RANGE changed
                     First signal definitions for RGB data decoder which fills the framebuffers
```
```
V04: RGB data decoder implemented which sets the s_we signal for the correct framebuffer.
     matrix.vhd:     Decoder code implemented
     Example for 4x4 Panels: Input address format s_waddr_i = PP TTT RRRR XXXXX -> PP = panel column number, TTT = halfpanel row number, RRRR = pixel row number, XXXXX = pixel column number
                             Output address format s_waddr = PP RRRR XXXXX and s_we(TTT) -> set write address at all framebuffers but activate only the correct one for writing
     -> the 24 Bit wide data input s_data_i, the write clock s_wclk_i and the relevant parts of s_waddr_i are directly connected to all framebuffers
     -> writing this data to the correct framebuffer is ensued by the decoder which evaluates the TTT part of the input address s_waddr_i
     Testbench updated to test the decoder in modelsim (matrix_tb.vhd, compile.do and sim.do updated)
```
```
V05: Testbench updated to test LED panel driver
     1 Pixel shift fixed - LATCH signal needed to come 1 clk period earlier
     Pin Assignments changed to support 4 Panel Rows
```
```
V06: UART receiver added, clock changed from 40MHz to 30MHz to decrease distortions, gamma correction temporarily deactivated, bug fixed: R and B were mixed in earlier versions -> old ppm2mif and pnm2mif 
     scripts generated framebuffer data in format GBR (instead of RGB) -> pnm2mif script adapted to get correct output (RGB -> Bit 7 to Bit 0 is blue), additionally in matrix.vhd the process RGB01_output_signals
     adapted to get the correct signals to the RGB0/1 outputs.
     matrix.vhd: 	UART receiver added, BGR -> RGB bug fixed
     ctrl.vhd:		Gamma correction deactivated
     -> Drawing and data streaming is now possible with the 6 Byte RGB protocol consisting of: X Y R G B CS (X = X coordinate of pixel, Y = Y coordinate, R, G, B, and checksum CS which is XOR of all 5 prior Bytes)
```
```
V06a: pnm2mif script updated to generate MIF files with reduced color depths
```
```
V07: Support of lower color depths than 8 Bit per color enabled -> UART input is always 8 Bit per color (R G B) but if the color depth is set to e.g. 6 Bit the upper 2 Bits are not considered - therefore the 
     color depth reduction has to be done on the sender side (Android program RGBStreamer was also adapted to send RGB data already scaled to the desired color depth, see https://github.com/hnfhtw/RGBStreamer)
     matrix.vhd:    Adaptions to support lower color depth (tested with 8 Bit per color and 6 Bit per color)
     pnm2mif:       Bug fixed concerning correct handling of command line parameters - now MIF files for lower color depths (e.g. 6 Bit per color) can be created without problem.
```
```
V08: matrix.vhd:    UART receiver code made generic -> streaming to different panel combinations were tested and work (e.g. 1x1, 1x2, 1x3, 1x4, 4x1, 4x4, ... (rows x col))
     pnm2mif:       Bug fixed (output to MIF files is now 2 digits wide per color - see changelog of pnm2mif)
```
```
V09: matrix.vhd:    Code cleaned up 
     ctrl.vhd:      Code cleaned up, 4 counters merged to 1
```
```
V10: Code cleaned up in matrix.vhd and ctrl.vhd (rename of several signals); impl\testram.vhd renamed and moved to rtl\ram.vhd; rs232.vhd renamed to uart.vhd
```
```
V11: UART Receiver and matrix entity separated -> new toplevel created which instantiates the receiver and the matrix entity separately
     Input address format of matrix entity changed from PP TTT RRRR XXXXX to TTT RRRR PP XXXXX -> now the framebuffer input data which is written to the matrix entity conveniently row by row from 000 0000 00 00000 (top left pixel of 128x128 image) to 111 1111 11 11111 (bottom right pixel of 128x128 image)
     Calculation package added with a function for all the log2 calculations -> now "log2ceil(x)" is used instead of "natural(ceil(log2(real(x))))"
     calc_pkg.vhd:  Calculation package with log2ceil() function
     ctrl.vhd:      Code cleaned up
     matrix.vhd:    UART receiver and PLL code received -> new toplevel was created, matrix.vhd can now be used for other designs which either directly write to the RAM interface or use SPI, I2C, ...
     toplevel.vhd:  New toplevel entity which instantiates a UART receiver, the matrix entity, the PLL for clock generation and a process which builds valid RGB packets out of the received UART bytes and drives the RAM interface of the matrix entity with the correct data (x, y, R, G, B)
```
```
V12: Input address format of matrix entity changed from TTT-RRRR-PP-XXXXX to A-TTT-RRRR-PP-XXXXX -> the new MSB is used to fill all framebuffers (all ram blocks) with the same color (s_wdata_i)
     matrix.vhd:    s_waddr_i width increased by 1 Bit -> adaptions were necessary, and mechanism implemented which fills all framebuffers with the same data once a write attempt to an address with MSB=1 (s_waddr_i) is done
     toplevel.vhd:  s_waddr_i width increased by 1 Bit -> adaptions were necessary,
```
```    
V13: BCM bit counter counted 1 step too much -> e.g. for 8 bit colour depth it counted from 0 to 255(and shifted-in and latched data for 256 times) -> the bit 0 was driven 2 times instead of 1 time
     To get 8 bit resolution (256 different levels) the data have to be shifted-in only 255 times -> so the counter has to count from 0 to 254
     Additionally, the 180° delayed clock input of the matrix entity was removed (at V12 the matrix entity had 2 clock inputs) 
     -> this clock, used as the output clock for the displays, is exchanged by the negated input clock of the matrix entity   
     toplevel.vhd:  Remove s_clk1 and c1 of the PLL
     matrix.vhd:    Remove s_clk180_i input, set s_clk_o outputs to "not s_clk_i" 
     ctrl.vhd:      Change BCM bit counter (formerly overflow counter was used that counted from 0 to 255 at 8bit colordepth, now one counter signal is compared to the endvalue and counting goes from 0 to 254)
                    Change generation of s_sel signal which determines which bit of the RGB data is used for the RGB0/1 outputs -> "if (((2**i) - 1) <= s_cnt_bit) then" -> "<=" instead of "<" in order to write bit 0 only 1 times instead of 2 times
```
```
V14: Width of write data signal of RGB data interface changed from 3x8 bits to 3xCOLORDEPTH bits.
     Global brightness control implemented - the global brightness of the panels can be reduced by the s_brightscale_i signal. Currently the switches SW0 to SW4 are utilized in order to change the brightness with 5 bit resolution.
     Testbenches for matrix entity updated - one testbench to test RGB data interface, one testbench to test the panel control signals
     toplevel.vhd:  New input signal s_brightscale_i added, which is synchronized and sampled with 10kHz
                    UART decode process adapted because RGB data interface write data input width is changed from 3x8 bits to 3xCOLORDEPTH bits
      matrix.vhd:   Global brightness control input s_brightscale_i added
                    Framebuffer decode process adapted because width of write data changed, and reset values for write s_waddr and s_ramindex added
                    Code cleaned up -> commented out code lines/blocks deleted
      ctrl.vhd:     Global brightness control input s_brightscale_i added
                    Code cleaned up -> commented out code line/blocks deleted, comments updated
                    Control signal generation process p_ctrl adapted -> at 100% brightness (s_brightscale_i = 0) the panels get now blanked only during the time were data is latched
                                                                        at lower brightnesses the panels get partly blanked within the time needed to shift in the RGB data for one panel (32 clock cycles)
      matrix_panel_control_tb.vhd:  Testbench to simulate the panel control signals -> modelsim -> cd to sim folder -> do compile.do -> do sim_panel_control.do
      matrix_RGB_interface_tb.vhd:  Testbench to simulate the RGB data interface -> modelsim -> cd to sim folder -> do compile.do -> do sim_RGB_interface.do
```                    
## LAST MODIFIED:
```
V01: 30.03.2016
V02: 31.03.2016
V03: 01.04.2016
V04: 01.04.2016
V05: 12.04.2016
V06: 15.04.2016
V06a: 17.04.2016
V07: 18.04.2016
V08: 19.04.2016
V09: 20.04.2016
V10: 21.04.2016
V11: 28.04.2016
V12: 29.04.2016
V13: 19.05.2016
V14: 03.06.2016
```
