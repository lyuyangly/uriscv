#include <stdint.h>
#include <stdlib.h>
#include <string.h>

extern int xmodemReceive(unsigned char*, int);

typedef void (*p_func)(void);

void delay(unsigned int t)
{
	volatile uint32_t i, j;
	for(i = 0; i < t; i++)
		for(j = 0; j < 1024; j++);
}

int main(void)
{
    //// UART 115200 8N1
    //uart_init(6944);
    //uart_puts("CPU Boot ...\r\n");
    //uart_puts("Receive Program by Xmodem in 10s ...\r\n");
    //delay(10000);

    //st = xmodemReceive((unsigned char *)(LOAD_BASE), 8192);

    volatile uint32_t x = 0;
    volatile uint8_t  num[10];

    for (x = 0; x < 10; x++) {
        num[x] = 0x80 + x;
    }

	return 0;
}
