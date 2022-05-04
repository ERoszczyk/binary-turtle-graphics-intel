#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#pragma pack(1)

typedef unsigned long DWORD;
typedef long int LONG;
typedef unsigned short WORD;
typedef unsigned char BYTE;

typedef struct{
	WORD bfType;
    DWORD bfSize;
    WORD bfReserved1;
    WORD bfReserved2;
    DWORD bfOffBits;
	DWORD biSize;
    LONG biWidth;
    LONG biHeight;
    WORD biPlanes;
    WORD biBitCount;
    DWORD biCompression;
    DWORD biSizeImage;
    LONG biXPelsPerMeter;
    LONG biYPelsPerMeter;
    DWORD biClrUsed;
    DWORD biClrImportant;
} bmpHeader;

typedef struct TurtleContextStruct{
	int x_pos;
	int y_pos;
	int direction;
	int pen_state;
	int color;
	int distance;
} TurtleContextStruct;

void createHeader(bmpHeader *bmp)
{
	bmp->biSize = 40;
    bmp->biPlanes = 1;
    bmp->biBitCount = 24;
    bmp->biCompression = 0;
    bmp->biXPelsPerMeter = 2835;
    bmp->biYPelsPerMeter = 2835;
    bmp->biClrUsed = 0;
    bmp->biClrImportant = 0;
	bmp->bfType = 0x4D42;
    bmp->bfReserved1 = 0;
    bmp->bfReserved2 = 0;
    bmp->bfOffBits = sizeof(bmpHeader);
}

unsigned char *createBitmap(int width, int height, size_t *size)
{
	unsigned int rowSize = (width * 3 + 3) & ~3;
	*size = rowSize * height + sizeof(bmpHeader);
	unsigned char *bitmap = (unsigned char *) malloc(*size);
	bmpHeader bitmapHeader;
	int i;
	
	createHeader(&bitmapHeader);
	bitmapHeader.bfSize = *size;
	bitmapHeader.biWidth = width;
	bitmapHeader.biHeight = height;
	
	memcpy(bitmap, &bitmapHeader, sizeof(bmpHeader));
	for(i = sizeof(bmpHeader); i < *size; ++i)
	{
		bitmap[i] = 0xff;	//white bitmap
	}
	return bitmap;
}

void createBmpFile(unsigned char *bitmapBuffer, size_t size, const char* fname)
{
	FILE *bmpFile;
	bmpFile = fopen(fname, "wb");
	
	if(bmpFile == NULL)
	{
		printf("Output file can not be open.\n");
		exit(-1);
	}
	
	fwrite(bitmapBuffer, 1, size, bmpFile);	//write bitmapBuffer to bmpFile
	fclose(bmpFile);
}

extern int* exec_turtle_cmd(unsigned char *dest_bitmap, unsigned char *command, TurtleContextStruct *tc);

int main(int argc, char const *argv[])
{
	FILE *bmpFile, *txtFile, *binFile;
	unsigned char *buffer;
	int width, height;
	size_t size;
	
	txtFile = fopen("config.txt","rt");
	if(txtFile == NULL)
	{
		//check if file opens correctly
		printf("config.txt can not be open.\n");
		return 0;
	}
	
	if(fscanf (txtFile, "%d", &width) != 1 || fscanf (txtFile, "%d", &height) != 1 || width <= 0 || height <= 0)
	{
		//check if file size is correct
		printf("Wrong file size in config.txt \n");
		return 0;
	}
	fclose(txtFile);
	unsigned char *bitmapBuffer = createBitmap(width, height, &size);

	TurtleContextStruct tc = 
	{
		0,	//x_pos
		0,	//y_pos
		0,	//direction
		0,	//pen_state
		0xFFFFFF,	//color
		0	//distance
	};
	
	binFile = fopen("input.bin", "rb");
	if(binFile == NULL)
	{
		//check if file opens correctly
		printf("input.bin can not be open.\n");
		return 0;
	}
	fseek(binFile, 0L, SEEK_END);
	int binSize = ftell(binFile);	//get bin file size
	rewind(binFile);
	
	buffer = (unsigned char *)malloc(4);	//4 bytes, because of 16-/32-bits commands
	
	while(fread(buffer, 2, 1, binFile) == 1)	//read commands from file
	{
		if((buffer[1] & 0x3) == 3)	//if set position command, which needs 32-bits
		{
			fseek(binFile, -2, SEEK_CUR);
			if(fread(buffer, 4, 1, binFile) != 1)	//load 32-bits command
			{
				//if load filed
				printf("Command error \n");
				fclose(binFile);
				return 0;
			}
		} 
		if(exec_turtle_cmd(bitmapBuffer, buffer, *tc) != 0)
		{
			printf("Command error \n");
			fclose(binFile);
			return 0;
		}
	}
	createBmpFile(bitmapBuffer, size, "output.bmp");
	
	fclose(binFile);
    return 0;
}