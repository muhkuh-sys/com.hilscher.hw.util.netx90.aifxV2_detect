#include "netx_io_areas.h"
#include "rdy_run.h"
#include "header.h"




void start(unsigned char *pucResult, unsigned long ulIndexRotaryMmios);

/**
 * @brief The next command may change a protected register
 * @details Rewrite the same value of the register inti itselve. this tells
 * the controller to allow a change of the configuration section.
 */
inline void activateLock( void ){
  //*asic_ctrl_access_key = *asic_ctrl_access_key;
  NX90_DEF_ptAsicCtrlArea
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
}

void __attribute__ ((section (".init_code"))) start(unsigned char *pucResult, unsigned long ulIndexRotaryMmios)
{
  unsigned char ucResult;
  ucResult = 0;

  #if ASIC_TYP==ASIC_TYP_NETX90

  #elif ASIC_TYP==ASIC_TYP_NETX4000

  #endif

  // enable pull downs of sense pins
  NX90_DEF_ptAsicCtrlArea // variablen deklaration
  NX90_DEF_ptPadCtrlArea
  NX90_DEF_ptXc0Xmac0RegsArea

  


  activateLock();
  ptPadCtrlArea->aulPad_ctrl_com_io[1] = MSK_NX90_pad_ctrl_com_io1_pe;
  activateLock();
  ptPadCtrlArea->aulPad_ctrl_com_io[2] = MSK_NX90_pad_ctrl_com_io2_pe;
  activateLock();
  ptPadCtrlArea->aulPad_ctrl_mii0_txd[1] = MSK_NX90_pad_ctrl_mii0_rxd1_pe;

  // switch on group clock and enable pass clock to unit
  
  unsigned long enableValueClocks = ( MSK_NX90_clock_enable0_xc_misc | MSK_NX90_clock_enable0_xc_misc_wm ) | ( MSK_NX90_clock_enable0_xmac0 | MSK_NX90_clock_enable0_xmac0_wm );
  unsigned long disableValueClocks = MSK_NX90_clock_enable0_xc_misc_wm | MSK_NX90_clock_enable0_xmac0_wm;

  activateLock();
  ptAsicCtrlArea->asClock_enable[0].ulEnable = enableValueClocks;
  // just set the write mask, all other values are 0 so bothe bits will flip back to 0


  // *pul_clock_enable0 = enableValueClocks;

  unsigned long ulResult = ptXc0Xmac0RegsArea->ulXmac_status_shared0;

  // read IO-Pins, to select the type of the bus peripheral

  activateLock();
  ptAsicCtrlArea->asClock_enable[0].ulEnable = disableValueClocks;

  if( ulResult && 1 << pin_gpio0_in){
    ucResult |= 1<<0;
  }
  if( ulResult && 1 << pin_gpio4_in_phy_led2){
    ucResult |= (unsigned char) (1<<1 );
  }
  if( ulResult && 1 << pin_gpio5_in_phy_led3){
    ucResult |= (unsigned char)1<<2 & 0xff;
  }

  /* Write the value to the pointer. */
  *pucResult = ucResult;
}
