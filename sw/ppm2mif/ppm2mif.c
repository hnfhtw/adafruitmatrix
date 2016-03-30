/*
 * ADAFRUITMATRIX -- FPGA design to drive a chain of 32x32 RGB LED Matrices
 *
 * Copyright (C) 2016  Christian Fibich
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http: *www.gnu.org/licenses/>.
 */

#include <stdio.h>
#include <stdlib.h>
#include <pam.h>

#define MIF_HEADER "ADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\n\nCONTENT BEGIN\n"
#define MIF_FOOTER "END;\n"

int main(int argc, char *argv[])
{

    struct pam inpam;
    tuple * tuplerow;
    int row;
    unsigned int bpc;
    char *end;
    unsigned int pxl = 0;

    if (argc < 2) {
        fprintf(stderr,"Usage: %s [bits-per-color]\n",argv[0]);
        return EXIT_FAILURE;
    }

    bpc = strtoul(argv[1],&end,0);

    if (*end != '\0' ) {
        fprintf(stderr,"bits-per-color is not numeric.\n");
        return EXIT_FAILURE;
    }

    pm_init(argv[0], 0);

    pnm_readpaminit(stdin, &inpam, sizeof(inpam));

    if (inpam.format != RPPM_FORMAT && inpam.format != PPM_FORMAT) {
        fprintf(stderr,"Only PPM files are accepted\n");
        return EXIT_FAILURE;
    }

    printf("WIDTH=%d;\nDEPTH=%d;\n\n",bpc*3,inpam.height*inpam.width);

    puts(MIF_HEADER);

    tuplerow = pnm_allocpamrow(&inpam);
    tuple t = pnm_allocpamtuple(&inpam);
    
    
    for (row = 0; row < inpam.height; ++row) {
        int column;
        pnm_readpamrow(&inpam, tuplerow);
        for (column = 0; column < inpam.width; ++column) {
            unsigned int plane;
            pnm_scaletuple(&inpam,t,tuplerow[column],(1 << bpc) - 1);
            for (plane = 0; plane < inpam.depth; ++plane) {
                pxl |= t[plane] << (bpc*plane);
            }
            printf("    %X : %03X;\n", row*inpam.width+column, pxl);
            pxl = 0;
        }
    }
    pnm_freepamrow(tuplerow);
    pnm_freepamrow(t);
    
    puts(MIF_FOOTER);
    return EXIT_SUCCESS;
}