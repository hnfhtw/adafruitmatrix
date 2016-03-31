// HN 31.03.2016 - Convert *.PNM image (width x 32) to two Quartus MIF files (memory addressing PP RRRR XXXXX, PP = Panel Number, RRRR = Pixel Row Address A-D, XXXXX = Pixel Column Number (0 to 31))
// Usage: ./pnm2mif [width] [height] [0 or 1 (for upper or lower halfimage)] < inputfilename.pnm > outputfilename.mif
// Example for a 128x32 upper halfimage: ./pnm2mif 128 32 0 < testimage_128x32.pnm > testimage_128x32_upper.mif
// Example for a 128x32 lower halfimage: ./pnm2mif 128 32 1 < testimage_128x32.pnm > testimage_128x32_lower.mif

#include <stdio.h>
#include <stdlib.h>

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
	
	if (argc < 4) {
        fprintf(stderr,"Usage: %s [image width] [image height] [0 or 1 (upper half or lower halfimage)] < inputfilename.pnm > outputfilename.mif\n",argv[0]);
        return EXIT_FAILURE;
    }
	
	width = atoi(argv[1]);
	height = atoi(argv[2]);
	divide = atoi(argv[3]);
	
	
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
	
	printf("WIDTH=24;\nDEPTH=%d;\n\n", width*height/2);
	
	puts(MIF_HEADER);
	
	if(divide == 1)
		offset = 0;
	else
		offset = width*height/2;
	
	for(i = 0; i < width*height/2; i++)
	{
		if((i/32)%4 == 0)
		{
			printf("%X : %1X%1X%1X;\n", addrprint, array[offset+i][2], array[offset+i][1], array[offset+i][0]);
			addrprint++;
		}
	}
	for(i = 0; i < width*height/2; i++)
	{
		if((i/32)%4 == 1)
		{
			printf("%X : %1X%1X%1X;\n", addrprint, array[offset+i][2], array[offset+i][1], array[offset+i][0]);
			addrprint++;
		}
	}
	for(i = 0; i < width*height/2; i++)
	{
		if((i/32)%4 == 2)
		{
			printf("%X : %1X%1X%1X;\n", addrprint, array[offset+i][2], array[offset+i][1], array[offset+i][0]);
			addrprint++;
		}
	}
	for(i = 0; i < width*height/2; i++)
	{
		if((i/32)%4 == 3)
		{
			printf("%X : %1X%1X%1X;\n", addrprint, array[offset+i][2], array[offset+i][1], array[offset+i][0]);
			addrprint++;
		}
	}
	
	puts(MIF_FOOTER);
	
	return 0;
}