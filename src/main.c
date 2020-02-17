#include "netx_io_areas.h"
#include "rdy_run.h"
#include "header.h"




void start(uint16_t * pusResult0);

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

void __attribute__ ((section (".init_code"))) start( uint16_t * pusResult)
{
  uint16_t usResult0 = 0x55aa;
  uint16_t usResult1 = 0x2222;
  

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

  // # I2C unit: io_config2  0xff401210 sel_i2c0_com_wm, sel_i2c0_com MUXen
  unsigned long io_config2_sel_i2c0_com_wm = MSK_NX90_io_config2_sel_i2c0_com | MSK_NX90_io_config2_sel_i2c0_com_wm;
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptAsicCtrlArea->asIo_config[2].ulConfig = io_config2_sel_i2c0_com_wm;
  // read I2C pio
  unsigned long ulResultI2C = ptI2cArea->ulI2c_pio;
  volatile unsigned long ulResult_COM_IO1 = (MSK_NX90_i2c_pio_sda_in_ro & ulResultI2C) >> SRT_NX90_i2c_pio_sda_in_ro; // i2c_com_sda, 0x40
  volatile unsigned long ulResult_COM_IO0 = (MSK_NX90_i2c_pio_scl_in_ro & ulResultI2C) >> SRT_NX90_i2c_pio_scl_in_ro; // i2c_com_scl, scl, 0x04


  //io_config0 activate PY-LED (xm0_io1 - working :)
  // here the internal phy is selected!
  unsigned long config_asic_ctrl_mux = 2 << SRT_NX90_io_config0_sel_xm0_io; // enable mux xm0_io1 (working)
  unsigned long config_asic_ctrl_mux_wm = config_asic_ctrl_mux | config_asic_ctrl_mux << 16;  // todo: komplete mask from regdef from 3 to 8
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptAsicCtrlArea->asIo_config[0].ulConfig = config_asic_ctrl_mux_wm;

  // # clock
  // ## Setup clock commands, disable/enable  
  unsigned long enableValueClocks = ( MSK_NX90_clock_enable0_xc_misc | MSK_NX90_clock_enable0_xc_misc_wm ) | ( MSK_NX90_clock_enable0_xmac0 | MSK_NX90_clock_enable0_xmac0_wm );
  unsigned long disableValueClocks = MSK_NX90_clock_enable0_xc_misc_wm | MSK_NX90_clock_enable0_xmac0_wm;
  // ## Switch on clock enable power (connected in asic to clock lane)
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptAsicCtrlArea->asClock_enable[0].ulEnable = enableValueClocks;
  
  /**
   * ARB: 17.02.2020
   * Following single line is mandatory. It is necessary if you compile the release.
   * During test, it was not possible to read in the next cycle from this unit the correct value.
   * This unit is developed by hilscher internal and undocumented. Retrive more infos from group netX Design.
   * For now, it's unclear, how long it's actually to wait. but rereading the value written, should give enough time.
   * If you want to save this cycle, you can suffel some bitshifts in between. Say, first calculate confogbits for the
   * unit, activate it, calculate the remaining bits for the unit and then assume that the unit is running and retrive the
   * values.
   */
  volatile unsigned long buy_time_until_Xc_is_really_enabled = ptAsicCtrlArea->asClock_enable[0].ulEnable;
  
  // # Retrieve values
  volatile unsigned long ulResult_XM0_IO1 = ( ptXc0Xmac0RegsArea->ulXmac_status_shared0 & MSK_NX90_xmac_status_shared0_gpio1_in ) >> SRT_NX90_xmac_status_shared0_gpio1_in; // to get the first.
  

  // # shutdown clock
  ptAsicCtrlArea->ulAsic_ctrl_access_key = ptAsicCtrlArea->ulAsic_ctrl_access_key;
  ptAsicCtrlArea->asClock_enable[0].ulEnable = disableValueClocks;


  /*
  Output ist two interfaces, only RealTimeethernet has two ports. 
  XM0_IO1 | COM_IO1 | COM_IO0    => (unit16_t * r0 , unit16_t * (r0 + 2) )
  ------------------------------
  0      | x       | x        | => RTE connector (0x0080, 0x0080)
  ------------------------------
  1      | 0       | 0        | => CAN open (0x0030, 0x0000)
  ------------------------------
  1      | 0       | 1        | => Profibus (0x0050, 0x0000)
  ------------------------------
  1      | 1       | 0        | => DeviceNet (0x0040, 0x0000)
  ------------------------------
  1      | 1       | 1        | => CC-Link   (0x0070, 0x0000)
  ------------------------------
  0 pin low
  1 ping high
  x pin state does not matter
  */

  // # do some evaluation, later edvanced matrix. 
  if(ulResult_XM0_IO1){
    if(ulResult_COM_IO1){
      if(ulResult_COM_IO0){
        // => CC-Link   (0x70)
        usResult0 = 0x0070;
        usResult1 = 0x0000;
      }else{
        // => DeviceNet (0x40)
        usResult0 = 0x0040;
        usResult1 = 0x0000;
      }
    }else{
      if(ulResult_COM_IO0){
        // => Profibus (0x50)
        usResult0 = 0x0050;
        usResult1 = 0x0000;
      }else{
        // => CAN open (0x30)
        usResult0 = 0x0030;
        usResult1 = 0x0000;
      }
    }
  }else{
    // NOT XM0_IO1
    // usResult0 = 0x80;
    usResult0 = 0x0080;
    usResult1 = 0x0080;
  }

  /* Write the value to the pointer. */
  *pusResult = usResult0;
  pusResult ++;
  *pusResult = usResult1;
  //*pusResult0 = 0x55aa;
}
