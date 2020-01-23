# \file netX4000_test_read_rotary_snippet.tcl 
# \brief Script to test the functionality of the  netX4000 read rotaryswitch snippet
# \author NW

proc read_data32 {addr} {
  set value(0) 0
  mem2array value 32 $addr 1
  return $value(0)
}

proc read_data8 {addr} {
  set value(0) 0
  mem2array value 8 $addr 1
  return $value(0)
}


# \brief Initialise the TCM memory (Tightly-Coupled Memory)
# enable ITCM+DTCM and set reset vector at start of ITCM
# TRM chapter 4.3.13
# 
# MRC    p15,    0,   <Rd>, c9,  c1,  0
# MRC coproc,  op1, <Rd>, CRn, CRm, op2
# -> arm mrc coproc op1 CRn CRm op2
#
# MCR p15,      0, <Rd>, c9,  c1,  0
# MCR coproc, op1, <Rd>, CRn, CRm, op2
# -> arm mcr coproc op1 CRn CRm op2 value
#
# http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.ddi0458c/CHDEFBFI.html

proc netx4000_enable_tcm {} {
  set __ITCM_START_ADDRESS__         0x00000000
  set __DTCM_START_ADDRESS__         0x00020000
  		
  set MSK_CR7_CP15_ITCMRR_Enable     0x00000001
  set SRT_CR7_CP15_ITCMRR_Enable     0
  
  set MSK_CR7_CP15_ITCMRR_Size        0x0000003c
  set SRT_CR7_CP15_ITCMRR_Size        2
  set VAL_CR7_CP15_ITCMRR_Size_128KB  8
  
  set MSK_CR7_CP15_DTCMRR_Enable     0x00000001
  set SRT_CR7_CP15_DTCMRR_Enable     0
  
  set MSK_CR7_CP15_DTCMRR_Size       0x0000003c
  set SRT_CR7_CP15_DTCMRR_Size       2
  set VAL_CR7_CP15_DTCMRR_Size_128KB 8
  
  set ulItcm [expr $__ITCM_START_ADDRESS__  | $MSK_CR7_CP15_ITCMRR_Enable | ( $VAL_CR7_CP15_ITCMRR_Size_128KB << $SRT_CR7_CP15_ITCMRR_Size ) ]
  set ulDtcm [expr $__DTCM_START_ADDRESS__  | $MSK_CR7_CP15_DTCMRR_Enable | ( $VAL_CR7_CP15_DTCMRR_Size_128KB << $SRT_CR7_CP15_DTCMRR_Size ) ]
  
  puts "netx 4000 Enable ITCM/DTCM"
  puts [ format "ulItcm: %08x" $ulItcm ]
  puts [ format "ulDtcm: %08x" $ulDtcm ]
  
  arm mcr 15 0 9 1 1 $ulItcm
  arm mcr 15 0 9 1 0 $ulDtcm
  
  puts "Set reset vector in ITCM"
  mww 0 0xE59FF00C
  mdw 0
}

# \brief Init/probe for JTAG interfaces
proc probe {} {
  global SC_CFG_RESULT
  set SC_CFG_RESULT 0
  set RESULT -1

  # Setup the interface.
  interface ftdi
  transport select jtag
  ftdi_device_desc "NXJTAG-4000-USB"
  ftdi_vid_pid 0x1939 0x0301
  adapter_khz 1000
  
  ftdi_layout_init 0x1B08 0x1F0B
  ftdi_layout_signal nTRST -data 0x0100 -oe 0x0100
  ftdi_layout_signal nSRST -data 0x0200 -oe 0x0200
  ftdi_layout_signal JSEL1 -data 0x0400 -oe 0x0400
  ftdi_layout_signal VODIS -data 0x0800 -oe 0x0800
  ftdi_layout_signal VOSWI -data 0x1000 -oe 0x1000

  # Expect a netX4000 scan chain.
  jtag newtap netx4000 dap -expected-id 0x4ba00477 -irlen 4
  jtag configure netx4000.dap -event setup { global SC_CFG_RESULT ; echo {Yay} ; set SC_CFG_RESULT {OK} }
		
  # Expect working SRST and TRST lines.
  reset_config trst_and_srst

  # Try to initialize the JTAG layer.
  if {[ catch {jtag init} ]==0 } {
    if { $SC_CFG_RESULT=={OK} } {
	  target create netx4000.r7 cortex_r4 -chain-position netx4000.dap -coreid 0 -dbgbase 0x80130000
	  netx4000.r7 configure -work-area-phys 0x05080000 -work-area-size 0x4000 -work-area-backup 1
	  netx4000.r7 configure -event reset-assert-post "cortex_r4 dbginit"
	   
      init

      # Try to stop the CPU.
      halt

	  # Enable the tcm
      netx4000_enable_tcm	
	  
      # Declare the portcontrol registers
	  set PORTCONTROL_P5_11 0xfb10016c
      set PORTCONTROL_P5_12 0xfb100170
      set PORTCONTROL_P6_0  0xfb100180
      set PORTCONTROL_P6_1  0xfb100184

	  # Set snippet file name, start adress and execution adress
      set filename_snippet_read_rotaryswitch_netx4000_bin ../../targets/netx4000/read_rotaryswitch_snippet_netx4000.bin
	  set snippet_load_address 0x04020000
      set snippet_exec_address 0x0402001d

	  # Set the portcontrol ports to pull downs
      mww $PORTCONTROL_P5_11 0x00000003
      sleep 500
      mww $PORTCONTROL_P5_12 0x00000003
      sleep 500
      mww $PORTCONTROL_P6_0  0x00000003
      sleep 500
	  mww $PORTCONTROL_P6_1  0x00000003
      sleep 500

	  # Set breakpoint, Current Program Status Register(cpsr), Stack Pointer and Link Register
      bp 0x04100000 4 hw
      reg cpsr 0xf3
      reg sp_svc 0x0003ffec
      reg lr_svc 0x04100000
	
      # Download the snippet.
      load_image $filename_snippet_read_rotaryswitch_netx4000_bin $snippet_load_address bin
	  
	  # Set the handover registers r0 and r1
	  reg r0 0x05080000 
	  reg r1 0x31302c2b
	  
	  # Start snippet
	  echo "Resume $snippet_exec_address"
	  resume $snippet_exec_address
	  
	  wait_halt
	  
	  
	  # Check if rotary switch can be read
	  set result_rotary [read_data8 0x05080000]
	  
	  echo ""
	  echo "########"
	  echo "Check the rotaryswitch position, it should be: $result_rotary"
	  echo "########"
	  
	  echo "True? y/n"
	  set data [gets stdin]
	  set result_check y
	  
	  if {$data == "y"} then {
	  echo ""
	  echo " #######  ##    ## "
	  echo "##     ## ##   ##  "
	  echo "##     ## ##  ##   "
	  echo "##     ## #####    "
	  echo "##     ## ##  ##   "
	  echo "##     ## ##   ##  "
	  echo " #######  ##    ## "
	  echo ""
	  
	  set RESULT 0
	  }
    }
  }

  return $RESULT
}

probe
shutdown
