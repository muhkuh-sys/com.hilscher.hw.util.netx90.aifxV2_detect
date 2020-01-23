#include "netx_io_areas.h"
#include "rdy_run.h"

unsigned char getMmioValue(unsigned char mmioIndex)
{
	HOSTDEF(ptMmioCtrlArea);

	unsigned char ucRegisterIndex;
	unsigned char ucIndexInRegister;
	unsigned char ucBitResult;
	unsigned long ulTemp;

	/* Extract Register Index 0-3*/
	ucRegisterIndex = (unsigned char)((mmioIndex & 0xe0) >> 5);

	/* Extract Index in register 0-31*/
	ucIndexInRegister = (unsigned char)(mmioIndex & 0x1f);

	/* Look in extracted register after Index stored in mmioIndex*/
#if ASIC_TYP==ASIC_TYP_NETX90
	ulTemp = ptMmioCtrlArea->ulMmio_in_line_status0;
#elif ASIC_TYP==ASIC_TYP_NETX4000
	ulTemp = ptMmioCtrlArea->aulMmio_in_line_status[ucRegisterIndex];
#endif
	ucBitResult = (ulTemp >> ucIndexInRegister) & 0x1;

	return ucBitResult;
}

void start(unsigned char *pucResult, unsigned long ulIndexRotaryMmios);

void __attribute__ ((section (".init_code"))) start(unsigned char *pucResult, unsigned long ulIndexRotaryMmios)
{
	int i;
	int iEnd;
	unsigned char ucIdx;
	unsigned char ucBitValue;
	unsigned char ucResult;

	ucResult = 0;

#if ASIC_TYP==ASIC_TYP_NETX90
	iEnd = 1;
#elif ASIC_TYP==ASIC_TYP_NETX4000
	iEnd = 4;
#endif

	for(i=0; i<iEnd; i++) {
		/* Extract MMIO index of R1 */
		ucIdx = (unsigned char)((ulIndexRotaryMmios >> (24-(8*i) )) & 0xff);

		/* Check if MMIO is used */
		if (ucIdx != 0xff)
		{
			ucBitValue = getMmioValue(ucIdx);
			ucResult = (ucResult << 1) | ucBitValue;
		}
	}

	/* Write the value to the pointer. */
	*pucResult = ucResult;
}
