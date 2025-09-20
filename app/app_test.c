#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#define AHB_RAM_BASE    0x80000000
#define AHB_PIO_BASE    0xF0000000

typedef void (*p_func)(void);

void delay(unsigned int t)
{
	volatile uint32_t i, j;
	for(i = 0; i < t; i++)
		for(j = 0; j < 1024; j++);
}

int main(void)
{
    volatile uint32_t x = 0;
    volatile uint32_t num[10];
    uint32_t len = sizeof(num)/sizeof(num[0]);

    for (x = 0; x < len; x++) {
        num[x] = 0x80 + x;
        *((uint32_t *)(AHB_RAM_BASE + x*4)) = 0x80000000 + x;
        *((uint32_t *)(AHB_PIO_BASE + x*4)) = 0xdead8000 + x;
    }

    for (x = 0; x < len; x++) {
        num[x] = *((uint32_t *)(AHB_RAM_BASE + x*4));
        *((uint32_t *)(AHB_PIO_BASE + x*4)) = 0xbeef8000 + x;
    }

	return 0;
}
