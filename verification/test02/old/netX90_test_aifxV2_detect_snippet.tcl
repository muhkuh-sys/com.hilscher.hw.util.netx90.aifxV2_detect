set hboot_image_with_exec_wait_for_event mein/pfad/zum/setzen.bin


# procedere
# set brekpoint in romcode,
# reset controller, will hold at breakpoint ( retrieve from lauterbach script)
# Flash image
# where to set return address? -> xml
# Ask user to set pinns accordingly
# proceed execution
# retrieve returnvalue



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




# \brief Init/probe for JTAG interfaces
# \details Attache to netX90 via NXJTAG-USB
proc probe {} {
  set RESULT -1
  global using_hla

  # Setup the interface.
#---
  interface ftdi
  ftdi_device_desc "NXJTAG-USB"
  ftdi_vid_pid 0x1939 0x0023

  ftdi_layout_init 0x0308 0x030b
  ftdi_layout_signal nTRST -data 0x0100 -oe 0x0100
  ftdi_layout_signal nSRST -data 0x0200 -oe 0x0200

  adapter_khz 6000
#___

  
  # todo alter!

# from source [find target/swj-dp.tcl] ::
#---
# ARM Debug Interface V5 (ADI_V5) utility
# ... Mostly for SWJ-DP (not SW-DP or JTAG-DP, since
# SW-DP and JTAG-DP targets don't need to switch based
# on which transport is active.
#
# declare a JTAG or SWD Debug Access Point (DAP)
# based on the transport in use with this session.
# You can't access JTAG ops when SWD is active, etc.

# params are currently what "jtag newtap" uses
# because OpenOCD internals are still strongly biased
# to JTAG ....  but for SWD, "irlen" etc are ignored,
# and the internals work differently

# for now, ignore non-JTAG and non-SWD transports
# (e.g. initial flash programming via SPI or UART)

# split out "chip" and "tag" so we can someday handle
# them more uniformly irlen too...)


  if [catch {transport select}] {
    echo "Error: unable to select a session transport. Can't continue."
    shutdown
  }

  proc swj_newdap {chip tag args} {
  # try to distinguish between SWD and JTAG
    if [using_hla] {
      eval hla newtap $chip $tag $args
    } elseif [using_jtag] {
      eval jtag newtap $chip $tag $args
    } elseif [using_swd] {
      eval swd newdap $chip $tag $args
    }
  }

  #___

  if { [info exists CHIPNAME] } {
    set  _CHIPNAME $CHIPNAME
  } else {
    set  _CHIPNAME netx90
  }

  #
  # Main DAP
  #
  if { [info exists DAP_TAPID] } {
    set _DAP_TAPID $DAP_TAPID
  } else {
    set _DAP_TAPID 0x6ba00477
  }

  swj_newdap $_CHIPNAME dap -expected-id $_DAP_TAPID -irlen 4
  if { [using_jtag] } {
    swj_newdap $_CHIPNAME tap -expected-id 0x10a046ad -irlen 4
  }


  if {![using_hla]} {
    # if srst is not fitted use SYSRESETREQ to
    # perform a soft reset
    cortex_m reset_config sysresetreq
  }

  #
  # Communication Cortex M4 target
  #
  set _TARGETNAME_COMM $_CHIPNAME.comm
  target create $_TARGETNAME_COMM cortex_m -chain-position $_CHIPNAME.dap -coreid 0 -ap-num 2

  $_TARGETNAME_COMM configure -work-area-phys 0x00040000 -work-area-size 0x4000 -work-area-backup 1

  # establish connection to chip, but don't stop CPU
  init
}


# \brief reset netX 90 
# \details procedure according to: https://kb.hilscher.com/x/GylbBg
proc reset_device {} {

  halt
  # bp address from : https://kb.hilscher.com/x/ghMWBg (netX90 rev1)
  # bp 0x170a2 4 hw
  # bp ... 2 -> for 16buit thumb code ( assumption )
  bp 0x170a2 2 hw

  #---

  set romcode_look_up_addr 0x20080000
  # load hboot image with jump to "wait-for-event-loop"
  load_image $hboot_image_with_exec_wait_for_event $romcode_look_up_addr bin
 
# reset temporary ROM loader parameter inside register asic_ctrl.only_porn_rom 0xff0016b8
# Modify access key protected register
# read write access control
# data.set ASD:0xff4012c0 %LONG data.long(ASD:0xff4012c0)
# data.set ASD:0xff0016b8 %LONG (0x0)
mww 0xff4012c0 [read_data32 0xff4012c0]
mww 0xff0016b8 0x0
 
# set PC into endless loop
#d.set 0x20080000++3 %Long 0xBF00E7FE
set intram1_start_addr 0x00040000
mww $intram1_start_addr 0xBF00E7FE

# set pc: ... reg [  ]

#R.S PC R:0x20080000
#R.S XPSR 0x01000000
 
#// reset is only allowed, if CPU is running
#go
 
#// reset netX90
#SYStem.RESetOut
 
#wait !STATE.RUN() 1s
 
#IF !STATE.RUN()

#(
#  IF Register(PC)==0x1ff00
#  (
#    // remove breakpoint
#    break.Delete 0x1ff00
# 
#    PRINT "netX 90 (COM CPU) STOPPED at breakpoint 0x1ff00 (typically end of HWC)"
#    ENDDO
#  )
#    ELSE
#    (
#      DIALOG.OK "FAILED to stop at breakpoint 0x1ff00 (typically end of HWC)"
#    )
#)
#ELSE
#(
#    DIALOG.OK "Breakpoint not reached" "" "Still running."
#)
 
#ENDDO
  #___
  
}


#-x-x-x-x-x----

proc old_prog {} {




  # Try to initialize the JTAG layer.
  if {[ catch {jtag init} ]==0 } {
    if { $SC_CFG_RESULT=={OK} } {
      

	   
      init

      # Try to stop the CPU.
      halt

	  
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
    echo "Test OK"
	  echo ""
	  
	  set RESULT 0
	  }
    }
  }

  return $RESULT
}

echo "probe"
probe
echo "reset_device"
reset_device
echo "shutdown =)"
shutdown
