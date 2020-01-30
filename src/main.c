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
  NX90_DEF_ptI2c0ComArea

  // # enable Padcontrol, takes care that the pysical pad is actually ready.
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptPadCtrlArea->aulPad_ctrl_com_io[0] = MSK_NX90_pad_ctrl_com_io0_pe | MSK_NX90_pad_ctrl_com_io0_ie; // also enable the INPUT!!!
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptPadCtrlArea->aulPad_ctrl_com_io[1] = MSK_NX90_pad_ctrl_com_io1_pe | MSK_NX90_pad_ctrl_com_io1_ie;
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptPadCtrlArea->aulPad_ctrl_mii0_txd[1] = MSK_NX90_pad_ctrl_mii0_txd1_pe | MSK_NX90_pad_ctrl_mii0_txd1_ie;

  // ## MMIO2 (working, as a test for pin toggeling.)
  /*
  // ### config
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptPadCtrlArea->aulPad_ctrl_mmio[2] = MSK_NX90_pad_ctrl_mmio2_pe | MSK_NX90_pad_ctrl_mmio2_ie;
  // ### read
  volatile unsigned long ulResultMMIO = (unsigned long *) Adr_NX90_mmio_ctrl_mmio2_cfg; // do it more nicely
  */

  //io_config0 activate PY-LED (xm0_io1 - working :)
  // here the internal phy is selected!
  unsigned long config_asic_ctrl_mux = 2 << SRT_NX90_io_config0_sel_xm0_io; // enable mux xm0_io1 (working)
  unsigned long config_asic_ctrl_mux_wm = config_asic_ctrl_mux | config_asic_ctrl_mux << 16;  // todo: komplete mask from regdef from 3 to 8
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptAsicCtrlArea->asIo_config[0].ulConfig = config_asic_ctrl_mux_wm;


  // # I2C unit: io_config2  0xff401210 sel_i2c0_com_wm, sel_i2c0_com MUXen
  unsigned long io_config2_sel_i2c0_com_wm = MSK_NX90_io_config2_sel_i2c0_com | MSK_NX90_io_config2_sel_i2c0_com_wm;
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptAsicCtrlArea->asIo_config[2].ulConfig = io_config2_sel_i2c0_com_wm;
  // read I2C pio
  unsigned long ulResultI2C = ptI2cArea->ulI2c_pio;
  volatile unsigned long ulResultI2C_sda = (MSK_NX90_i2c_pio_sda_in_ro & ulResultI2C) && ulResultI2C; // && makes it true or false.
  volatile unsigned long ulResultI2C_scl = (MSK_NX90_i2c_pio_scl_in_ro & ulResultI2C) && ulResultI2C;



  // # clock
  // ## Setup clock commands, disable/enable  
  unsigned long enableValueClocks = ( MSK_NX90_clock_enable0_xc_misc | MSK_NX90_clock_enable0_xc_misc_wm ) | ( MSK_NX90_clock_enable0_xmac0 | MSK_NX90_clock_enable0_xmac0_wm );
  unsigned long disableValueClocks = MSK_NX90_clock_enable0_xc_misc_wm | MSK_NX90_clock_enable0_xmac0_wm;
  // ## Switch on clock enable power (connected in asic to clock lane)
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptAsicCtrlArea->asClock_enable[0].ulEnable = enableValueClocks;
  
  // # Retrieve values
  volatile unsigned long ulResult = ( ptXc0Xmac0RegsArea->ulXmac_status_shared0 & 0x2 ) >> 1; // to get the first.
  

  // # shutdown clock
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptAsicCtrlArea->asClock_enable[0].ulEnable = disableValueClocks;

  // # do some evaluation, later edvanced matrix. 
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
