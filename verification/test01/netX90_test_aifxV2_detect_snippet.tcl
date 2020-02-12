# exec command
# C:\project\com.hilscher.hw.util.netx90.aifxV2_detect_mod\v3\openocd_scripts\read_decode_netX90_rev1_rom_trace_message>read_netx90_romcode_trace.bat
# used by romcode : https://kb.hilscher.com/x/nis1BQ
telnet_port 4444

proc read_data32 {addr} {
  set value(0) 0
  mem2array value 32 $addr 1
  return $value(0)
}

proc read_data16 {addr} {
  set value(0) 0
  mem2array value 16 $addr 1
  return $value(0)
}


proc read_data8 {addr} {
  set value(0) 0
  mem2array value 8 $addr 1
  return $value(0)
}

proc s_ok {} {
    echo ""
    echo " ##  #  # "       
    echo "#  # # #  "
    echo "#  # ###  "
    echo " ##  #  # "
    echo ""
}

proc s_err {} {
echo "                         "
echo " ###  ##   ##    #   ##  "
echo " #    # #  # #  # #  # # "
echo " ##   ##   ##   # #  ##  "
echo " #    # #  # #  # #  # # "
echo " ###  # #  # #   #   # # "
echo "                         "
}

proc s_train {} {
  echo ""
  echo "    ooOOOO"
  echo "   oo      _____"
  echo "  _I__n_n__||_|| ________"
  echo ">(_________|_7_|-|______|"
  echo " /o ()() ()() o   oo  oo"
  echo ""
}


set debug 0
set bp_netx90_rev1_first_romloader 0x170a2
# build snippet with `python2.7 mbs/mbs`
set path_snippet_bin "../../targets/netx90_com_intram/aifxv2_detect_snippet_netx90_com_intram.bin"
set hboot_image_with_exec_wait_for_event "./bin/top_while1.bin"
set cmd_rec_jump_loop 0xBF00E7FE
# ruecksprung aus snippet auf andere adresse. 
set intram1_start_addr 0x00040000
#at internal RAM INTRAM3_S at location 0x2008 0000
set intram3_start_addr 0x20080000

set handoveraddr_mnetx90 0x0002024a

#--- Reset function
# \brief reset netX 90 
# \details procedure according to: https://kb.hilscher.com/x/GylbBg
proc reset_device {} {
    global bp_netx90_rev1_first_romloader
    global intram1_start_addr
    global cmd_rec_jump_loop
    global intram3_start_addr
    global hboot_image_with_exec_wait_for_event
    halt

	  echo "########"
	  echo "run: reset_device"
	  echo "########"


    # bp address from : https://kb.hilscher.com/x/ghMWBg (netX90 rev1)
    # bp 0x170a2 4 hw
    # bp ... 2 -> for 16buit thumb code ( assumption )
    bp $bp_netx90_rev1_first_romloader 2 hw

    #---

    # set romcode_look_up_addr 0x20080000
    echo "load hboot image with jump to wait-for-event-loop: $hboot_image_with_exec_wait_for_event"
    load_image $hboot_image_with_exec_wait_for_event $intram3_start_addr bin
    
    # reset temporary ROM loader parameter inside register asic_ctrl.only_porn_rom 0xff0016b8
    # Modify access key protected register
    # read write access control
    # data.set ASD:0xff4012c0 %LONG data.long(ASD:0xff4012c0)
    # data.set ASD:0xff0016b8 %LONG (0x0)
    mww 0xff4012c0 [read_data32 0xff4012c0]
    mww 0xff0016b8 0x0
    
    # Idea, set the controller into a endless loop, so it may run
    # controller will not be tempted to exec other chunks.
    # We do need a running CPU for a successful reset/restart
    

    ## following programm rec jump + nop ...
    # Does not work over the reset! also probably a boot sequence is active.
    # Place the while loop during the test
    # mww $intram1_start_addr $cmd_rec_jump_loop


    ## set PC into endless loop
    echo "Set pc to start of intram1 where endless loop resides"
    reg pc $intram1_start_addr

    ## Some CPU super mode (a internal mode, may be priviledged mode)
    # set register to reset value, Coretex Program Status Register
    # https://developer.arm.com/docs/dui0553/a/the-cortex-m4-processor/programmers-model/core-registers#CHDDIAFA
    reg xPSR 0x01000000
    
    echo "Show registers"
    reg
    #// reset is only allowed, if CPU is running
    #go

    resume

    # restart netX by reset via internal reset initiated by external signal of COM CM4
    reset

    echo "*** wait 0.5 second for reset to take action"
    sleep 500

    echo "expect to be at $bp_netx90_rev1_first_romloader"
    reg pc

    # device is now in defined state at the first possible pc, where to hold
}



# \brief run a single test.
# \details test expects to have a netX90 waiting. netX90 should not have executed any chunks.
#  it is expected to run the reset_device function before the first test
#  After execution the netX90 returns to the prepared endlessloop, where a breakpoint is also set.
#  this method allows the wrapper run_test to call this function several times.
#  Test depends on the testbinary compiled with the mbs.
# \param addr_result 32bit target address to write to the 16bit hardware assembly option
proc testcase_for_single_state { value_to_set addr_result  } {
    global debug
    global intram1_start_addr
    global path_snippet_bin
    global cmd_rec_jump_loop

    echo "start snippet"

    # addr from linker skript
    set snippet_load_address 0x000200C0
    # addr from snippet.xml (or elf file)


    # the snippet exec address is in the flashed snipped. It differs from the flash addr of the snippet.
    #   fint the correct address in the disassembly.txt of the snippet
    set snippet_exec_address 0x000200dc
    
    # download snippet to netX
    load_image $path_snippet_bin $snippet_load_address bin
    
    # stack decreases when advancing decreased by some bytes for the endless-loop
    set start_of_stack 0x3FFF0
	
    # set mode of xcpr to default, telling spu to execute thumbcode. See arm arm manual for more details.
    reg xPSR 0x01000000
    # set stack pointer to the start of the stack, to give the snippet a valid stack.
    reg sp $start_of_stack 

    # init a small endlessloop recjump + nop
    mww $intram1_start_addr $cmd_rec_jump_loop  
    # set return address, where breakpoint waits for return of snippet
      # the +1 indicates thumb code
    reg lr [expr {$intram1_start_addr + 1}]
    
    # Set breakpoint, Current Program Status Register(cpsr), Stack Pointer and Link Register
    # set brekpoint to the loop. After test lr returns to this loop, chought by breakpoint and openOCD is returned to
    # execute the new test. The execution has to stop for openOCD to take control again.
    bp $intram1_start_addr 2 hw
    
    reg pc
    if { $debug } { bp }
    if { $debug } { reg }
    
    # ## begin with test
    # write something into the result register. If you can read this after test, the test might have stuck in a exception or a breakpoint.
    mwh $addr_result 0xaffe
    
    echo ""
	  echo "########"
	  echo "Set value $value_to_set to input pins Bit 2:XM0_IO1, 1:COM_IO1, 0:COM_IO0"
	  echo "########"
	  
	  echo "Applied? input any key"
    set data [gets stdin]

	  # Set config register: ro => address where to store the result.
	  reg r0 $addr_result
  
	  reg pc $snippet_exec_address
    # execute the prepared snipped, return to lr addr. into endlessloop!

    resume

    # wait until controller halts, until the snipped returns, to intram1_start_addr, where bp is
	  sleep 10
    
    # todo: double check position
    if { $debug } { echo "expect to be at $intram1_start_addr pc:" }
    if { $debug } { reg pc }
    echo ""
    echo "########"
    echo "### finished snippet !!!"
    echo "########"
}

proc run_test { } {
  global handoveraddr_mnetx90

  # iteration over this array may not
  # input expected
  # XM0_IO1  COM_IO1  COM_IO0
  array set input_reference {
    0x000 0x80
    0x001 0x80
    0x010 0x80
    0x011 0x80
    0x100 0x30
    0x101 0x50
    0x110 0x40
    0x111 0x70
  }
  
  set i 0
  set num_errors 0
  set num_ok 0
  foreach exp_input [array names input_reference] {
    # reset geister
    set i [expr {$i + 1}]
    # reset the register
    mwh $handoveraddr_mnetx90 0xE5E1
    # init loop var for readabilety
    set exp_outcome $input_reference($exp_input)
    puts "\($i of 8\) ... $exp_input is $exp_outcome"
    # run single test
    testcase_for_single_state $exp_input $handoveraddr_mnetx90

    # retrieve return value of single test
    set real_outcome [read_data16 $handoveraddr_mnetx90]
    echo "user input $exp_input exp. result: $exp_outcome, outcome: $real_outcome"
    # compare the returnvalue with expected result
    if { $exp_outcome == $real_outcome } { \
      echo "user input $exp_input OK!"
      set num_ok [expr {$num_ok + 1}]
      s_ok
    } else {
      set num_errors [expr {$num_errors + 1}]
      echo "nope! missmatch of return value"
      s_err
    }
  }
  echo "------------------------------------------------------------"
  echo "total result:"
  if { $num_errors == 0 } { \
    echo "All test passed!"
    echo "failed: \($num_errors\) passed:\($num_ok\)"
    s_train  
  } else {
    s_err
    echo "Test failed! failed: \($num_errors\) passed:\($num_ok\)"
  }
  
}


# \brief Testfunction for arrays
# \details Note, that the order is not the same as input in the array.
proc play_with_arrays { } {
  array set colors {
    0x000 0x80
    0x001 0x80
    0x010 0x80
    0x011 0x80
    0x100 0x30
    0x101 0x50
    0x110 0x40
    0x111 0x70
  }
  foreach name [array names colors] {
      puts "$name is $colors($name)"
  }
}

# \brief run a single test case with default parameters
proc run_single_test { } {
  # bp at end of snippet
  # bp 0x201fe 2 hw
  global handoveraddr_mnetx90
  testcase_for_single_state 0x2 $handoveraddr_mnetx90
  mdh $handoveraddr_mnetx90
}



# Attach to to the COM CPU on an NXHX90-JTAG (netX90) board using the onboard USB-JTAG interface.

source [find interface/hilscher_nxjtag_usb.cfg]
# source [find interface/hilscher_nxhx90-jtag.cfg]
# source [find interface/hilscher_nrpeb_h90-re.cfg]

source [find target/hilscher_netx90_com.cfg]
init

# ARB:
reset_device

# run_test
# todo: wrap into loop for iteration over all 8 test cases

# single test
#testcase_for_single_state 0x2 $handoveraddr_mnetx90
# run_single_test
run_test
shutdown
# echo "Please connect over telnet..."
