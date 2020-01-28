#include "netx_io_areas.h"
#include "rdy_run.h"
#include "header.h"


unsigned char getMmioValue(unsigned char mmioIndex)
{
  HOSTDEF(ptMmioCtrlArea);

  unsigned char ucRegisterIndex;
  unsigned char ucIndexInRegister;
  unsigned char ucBitResult;
  unsigned long ulTemp;

  /* Extract Register Index 0-3*/
  ucRegisterIndex = (unsigned char) ((mmioIndex & 0xe0) >> 5);

  /* Extract Index in register 0-31*/
  ucIndexInRegister = (unsigned char) (mmioIndex & 0x1f);

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

/**
 * @brief The next command may change a protected register
 * @details Rewrite the same value of the register inti itselve. this tells
 * the controller to allow a change of the configuration section.
 */
inline void activateLock( void ){
  *asic_ctrl_access_key = *asic_ctrl_access_key;
}

void __attribute__ ((section (".init_code"))) start(unsigned char *pucResult, unsigned long ulIndexRotaryMmios)
{
  unsigned char ucResult;
  ucResult = 0;

  #if ASIC_TYP==ASIC_TYP_NETX90

  #elif ASIC_TYP==ASIC_TYP_NETX4000

  #endif

  // enable pull downs of sense pins
  activateLock();
  *pul_pad_ctrl_com_io1   |= 1 << uc_pull_down_enable;
  activateLock();
  *pul_pad_ctrl_com_io2   |= 1 << uc_pull_down_enable;
  activateLock();
  *pul_pad_ctrl_mii0_txd1 |= 1 << uc_pull_down_enable;

  // switch on group clock and enable pass clock to unit
  unsigned long enableValueClocks = ( bit_xc_misc | bit_xc_misc_wm ) | ( bit_clock_xMAC0 | bit_clock_xMAC0_wm );
  // just set the write mask, all other values are 0 so bothe bits will flip back to 0
  unsigned long disableValueClocks = bit_xc_misc_wm | bit_clock_xMAC0_wm;
  activateLock();
  *pul_clock_enable0 = enableValueClocks;

  ucResult = pul_xmac_status_shared0;
  // read IO-Pins, to select the type of the bus peripheral

  activateLock();
  *pul_clock_enable0 = disableValueClocks;
  volatile int a = 0;
  if( ucResult && 1 << pin_gpio0_in){
    a += 1;
  }
  if( usResult && 1 << pin_gpio4_in_phy_led2){
    a += 2;
  }
  if( usResult && 1 << pin_gpio5_in_phy_led3){
    a += 4;
  }





  /* Write the value to the pointer. */
  *pucResult = ucResult;
}
