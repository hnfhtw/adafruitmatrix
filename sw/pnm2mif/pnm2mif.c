// HN 31.03.2016 - Convert *.PNM image (width x 32) to two Quartus MIF files (memory addressing PP RRRR XXXXX, PP = Panel Number, RRRR = Pixel Row Address A-D, XXXXX = Pixel Column Number (0 to 31))
// Usage: ./pnm2mif [width] [height] [0 or 1 (for upper or lower halfimage)] optional: [output color depth per color] < inputfilename.pnm > outputfilename.mif
// Example for a 128x32 upper halfimage and 8 Bit color depth: ./pnm2mif 128 32 0 < testimage_128x32.pnm > testimage_128x32_upper.mif
// Example for a 128x32 lower halfimage and 8 Bit color depth: ./pnm2mif 128 32 1 < testimage_128x32.pnm > testimage_128x32_lower.mif
// Example for a 128x32 upper halfimage and 6 Bit color depth: ./pnm2mif 128 32 0 6 < testimage_128x32.pnm > testimage_128x32_upper_6Bit.mif
// Example for a 128x32 lower halfimage and 6 Bit color depth: ./pnm2mif 128 32 1 6 < testimage_128x32.pnm > testimage_128x32_lower_6Bit.mif

// Changelog: 15.04.2016 -> output data format changed from GBR to RGB
//            17.04.2016 -> Optional parameter to reduce color depth introduced - input color depth is always 8 Bit per color, output color depth can be adjusted by command line parameter (8 Bit per color is default)
//            18.04.2016 -> Bugs fixed (command line parameter setting of color depth didn't work properly, parameters 0 and 1 for upper/lower framebuffer were switched)
//            19.04.2016 -> Bug fixed -> output of MIF file RAM content was not 2 digit per color wide -> e.g. the color C1DF00 (RGB) was put out to the MIF file as C1DF0 which lead to an error as the driver used 0C, 1D and F0 instead of C1, DF and 00.

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <ctype.h>

#define MIF_HEADER "ADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\nCONTENT BEGIN\n"
#define MIF_FOOTER "END;\n"

int main(int argc, char *argv[])
{
	char ch;
	int count = 0;
	int addr = 0;
	int addrprint = 0;
	int i = 0;
	int x, y;
	int divide;
	int width, height;
	int headerdone = 0;
	int offset = 0;
	int colordepth = 8;
	int temp = 0;
	
	if (argc < 4) {
        fprintf(stderr,"Usage: %s [image width] [image height] [0 or 1 (upper half or lower halfimage)] optional: [output color depth per color] < inputfilename.pnm > outputfilename.mif\n",argv[0]);
        return EXIT_FAILURE;
    }
	
	width = atoi(argv[1]);
	height = atoi(argv[2]);
	divide = atoi(argv[3]);
	
	if(argc > 4 && (atoi(argv[4]) != 0))
		colordepth = atoi(argv[4]);
		
	int array[width*height][3];
	
	for(x = 0; x<(width*height); x++)
		for(y = 0; y<3; y++)
			array[x][y] = 0;
							
	while(count < 3*width*height - 4)
	{	
		if(count < 4)
		{
			while(((ch = getchar()) != EOF) && headerdone == 0)
			{
				if(ch == '\n')
					count++;
				if(count == 4)
				{
					headerdone = 1;
					break;
				}	
			}
		}
		
		else
		{
			if(count%3 == 1)
			{
				scanf("%d", &array[addr][0]);	
			}
			if(count%3 == 2)
			{
				scanf("%d", &array[addr][1]);
			}

			if(count%3 == 0) 
			{
				scanf("%d", &array[addr][2]);
				addr++;
			}
			count++;
		}
		
	}
	
	printf("WIDTH=%d;\nDEPTH=%d;\n\n", colordepth*3, width*height/2);
	
	puts(MIF_HEADER);
	
	if(divide == 0)
		offset = 0;
	else
		offset = width*height/2;
	
	for(i = 0; i < width*height/2; i++)
	{
		if((i/32)%4 == 0)
		{
			printf("%X : %02X%02X%02X;\n", addrprint, (array[offset+i][0]*((int)pow(2,colordepth)-1))/255, (array[offset+i][1]*((int)pow(2,colordepth)-1))/255, (array[offset+i][2]*((int)pow(2,colordepth)-1))/255);
			addrprint++;
		}
	}
	for(i = 0; i < width*height/2; i++)
	{
		if((i/32)%4 == 1)
		{
			printf("%X : %02X%02X%02X;\n", addrprint, (array[offset+i][0]*((int)pow(2,colordepth)-1))/255, (array[offset+i][1]*((int)pow(2,colordepth)-1))/255, (array[offset+i][2]*((int)pow(2,colordepth)-1))/255);
			addrprint++;
		}
	}
	for(i = 0; i < width*height/2; i++)
	{
		if((i/32)%4 == 2)
		{
			printf("%X : %02X%02X%02X;\n", addrprint, (array[offset+i][0]*((int)pow(2,colordepth)-1))/255, (array[offset+i][1]*((int)pow(2,colordepth)-1))/255, (array[offset+i][2]*((int)pow(2,colordepth)-1))/255);
			addrprint++;
		}
	}
	for(i = 0; i < width*height/2; i++)
	{
		if((i/32)%4 == 3)
		{
			printf("%X : %02X%02X%02X;\n", addrprint, (array[offset+i][0]*((int)pow(2,colordepth)-1))/255, (array[offset+i][1]*((int)pow(2,colordepth)-1))/255, (array[offset+i][2]*((int)pow(2,colordepth)-1))/255);
			addrprint++;
		}
	}
	
	puts(MIF_FOOTER);
	
	return 0;
}