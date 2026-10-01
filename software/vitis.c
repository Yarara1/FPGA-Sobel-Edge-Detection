
#include "platform.h"
#include "xil_io.h"

#define CSR_BASE 0x44A00000U

int main(void)
{
    init_platform();

    // Clear start first
    Xil_Out32(CSR_BASE + 4U, 0U);
    for (volatile int i = 0; i < 10000; i++);

    // Send start pulse
    Xil_Out32(CSR_BASE + 4U, 1U);
   

    for (volatile int i = 0; i < 100000; i++);

    Xil_Out32(CSR_BASE + 4U, 0U);

    while ((Xil_In32(CSR_BASE) & 0x1U) == 0U); 

    while (1);
    cleanup_platform();
    return 0;
}
