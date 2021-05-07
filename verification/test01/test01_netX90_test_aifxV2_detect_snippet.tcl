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
  echo "  "
  echo "      ooOOOO"
  echo "     oo      _____"
  echo "    _I__n_n__||_|| ________"
  echo "  >(_________|_7_|-|______|"
  echo "   /o ()() ()() o   oo  oo"
  echo ""
}


set debug 0
set bp_netx90_rev1_first_romloader 0x170a2
# build snippet with `python2.7 mbs/mbs`
set path_snippet_bin "../../targets/netx90_com_intram/aifxv2_detect_snippet_netx90_com_intram.bin"
set hboot_image_with_exec_wait_for_event "../comon/bin/top_while1.bin"
set cmd_rec_jump_loop 0xBF00E7FE
# ruecksprung aus snippet auf andere adresse. 
set intram1_start_addr 0x00040000
#at internal RAM INTRAM3_S at location 0x2008 0000
set intram3_start_addr 0x20080000

# There are two interfaces on each netX, so we need two hand over params
set handoveraddr_netx90_0 0x0002024a
set handoveraddr_netx90_before  [expr {$handoveraddr_netx90_0 - 2}]
set handoveraddr_netx90_1 [expr {$handoveraddr_netx90_0 + 2}]
set handoveraddr_netx90_after [expr {$handoveraddr_netx90_0 + 4}]

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
    # Effect: clear history of romloader. Kind of a "next job register"
    # Modify access key protected register
    # read write access control
    mww 0xff4012c0 [read_data32 0xff4012c0]
    # Romloader is resetted, will start from very begin e.g. start like power on reset (PORN)
    mww 0xff0016b8 0x0
    
    # Idea, set the controller into a endless loop, so it may run
    # controller will not be tempted to exec other chunks.
    # We do need a running CPU for a successful reset/restart
    

    ## following programm rec jump + nop ...
    # Does not work over the reset! also probably a boot sequence is active.
    # Place the while loop during the test
    mww $intram1_start_addr $cmd_rec_jump_loop


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
    resume
    # should now run in the endless loop at intram1_start_addr expecting the reset

    # restart netX by reset via internal reset initiated by external signal of COM CM4
    reset

    echo "*** wait 0.5 second for reset to take action"
    sleep 500

    
    echo "expect to be at $bp_netx90_rev1_first_romloader"
    reg pc
    # todo: compare position


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

    # ---------------------------------- configure test -----------------------------------------------------
    # addr from linker skript
    set snippet_load_address 0x000200C0
    # addr from snippet.xml (or elf file)

    # the snippet exec address is in the flashed snipped. It differs from the flash addr of the snippet.
    #   fint the correct address in the disassembly.txt of the snippet
    set snippet_exec_address 0x000200dc

    # stack decreases when advancing decreased by some bytes for the endless-loop
    set start_of_stack 0x3FFF0

    # ---------------------------------- execute test--------------------------------------------------------    
    # download snippet to netX
    load_image $path_snippet_bin $snippet_load_address bin
    
	
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
	  # sleep 10
    wait_halt
    
    # todo: double check position
    if { $debug } { echo "expect to be at $intram1_start_addr pc:" }
    if { $debug } { reg pc }
    echo ""
    echo "########"
    echo "### finished snippet !!!"
    echo "########"
}



# \brief Test the snippet if it does the correct work
# \details two tests are applied
# 1. 8 times a input is demanded and the input is controlled
#    The snippet set's two consecutive half words ( 2 Bytes ) at provided
#     Address via r0. half words before and after are after all snippets compared with
#     the default value. For this test the controlled bytes will be overwritten and not
#     restored.
# 2. The output from test is written to a place in memory. It's controlled
#    that the space in memory before and after is not overwritten.
#    a default value is written to two bytes before and after the 
#    handover address.
# \todo: The test loads the image at every run from new. You could probably ommit this step.
proc run_test { } {
  global handoveraddr_netx90_0
  global handoveraddr_netx90_1
  global handoveraddr_netx90_before
  global handoveraddr_netx90_after
  # this value will be written before and after the result value
  set control_value 0x55aa
  # write the control value in the bytes before and after the transfare area,
  # this will control the write acces from the snippet.
  mwh $handoveraddr_netx90_before $control_value
  mwh $handoveraddr_netx90_after  $control_value

  # iteration over this array may not
  # input expected
  # XM0_IO1  COM_IO1  COM_IO0
array set input_reference0 {
    0x000 0x0080
    0x001 0x0080
    0x010 0x0080
    0x011 0x0080
    0x100 0x0030
    0x101 0x0050
    0x110 0x0040
    0x111 0x0070
  }
  array set input_reference1 {
    0x000 0x0080
    0x001 0x0080
    0x010 0x0080
    0x011 0x0080
    0x100 0x0000
    0x101 0x0000
    0x110 0x0000
    0x111 0x0000
  }
  
  set addr_asic_ctrl_access_key 0xff4012c0
  set addr_reset_ctrl 0xff0016b0
  set msk_reset_out 0x06000000
  array set ref_reset_ctrl {
    0x000 0x00000000
    0x001 0x00000000
    0x010 0x00000000
    0x011 0x00000000
    0x100 0x06000000 # CAN
    0x101 0x00000000
    0x110 0x06000000 # DeviceNet
    0x111 0x00000000
  }
  
  set i 0
  set num_errors 0
  set num_ok 0
  foreach exp_input [lsort [array names input_reference0]] {
    # inc loop counter for convinience
    set i [expr {$i + 1}]
    # reset the register
    mwh $handoveraddr_netx90_0 0xE5E1
    mwh $handoveraddr_netx90_1 0xE5E1
    # init loop var for readabilety
    set exp_outcome0 $input_reference0($exp_input)
    set exp_outcome1 $input_reference1($exp_input)
    set exp_reset_out $ref_reset_ctrl($exp_input)
    puts "\($i of 8\) ... $exp_input is $exp_outcome0 and $exp_outcome1"
    
    # Disable reset_out_n in case the previous test has enabled it.
    mww $addr_asic_ctrl_access_key [read_data32 $addr_asic_ctrl_access_key] 
    mww $addr_reset_ctrl 0x0
    
    # run single test
    testcase_for_single_state $exp_input $handoveraddr_netx90_0

    # retrieve return value of single test
    set real_outcome0 [read_data16 $handoveraddr_netx90_0]
    set real_outcome1 [read_data16 $handoveraddr_netx90_1]
    set real_reset_ctrl [read_data32 $addr_reset_ctrl]
    set real_reset_out [expr $real_reset_ctrl & $msk_reset_out]
    
    echo "user input $exp_input exp. result: $exp_outcome0 / $exp_outcome1 / $exp_reset_out, outcome: $real_outcome0 / $real_outcome1 / $real_reset_out"
    # compare the returnvalue with expected result
    if { $exp_outcome0 == $real_outcome0 && $exp_outcome1 == $real_outcome1 && $exp_reset_out == $real_reset_out} { \
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
  set err 0
  echo "All test summary:"
  # evaluate, if the boarders have been touched:
  set real_before [read_data16 $handoveraddr_netx90_before]
  set real_after [read_data16 $handoveraddr_netx90_after]
  if { $control_value == $real_before } { \
    echo "Posttest-befor ok!"
  } else {
    echo "ERROR: Reference area before the handover section has been altred during test!"
    set err [expr {$err + 1}]
  }
  if { $control_value == $real_after } { \
    echo "Posttest-after ok!"
  } else {
    echo "ERROR: Reference area after the handover section has been altred during test!"
    set err [expr {$err + 1}]
  }

  # evaluate batch result
  if { $num_errors == 0 } { \
    echo "Main test group: All test passed!"
    echo "failed: \($num_errors\) passed:\($num_ok\)"
    s_ok
    s_train
  } else {
    echo "ERROR: Main test group: Tests failed! passed:\($num_ok\) failed: \($num_errors\)"
    set err [expr {$err + 1}]
  }

  if { $err != 0} { \
    echo "Return with error cause $err tests have failed."
    s_err
    shutdown error
  }
}


# \brief Testfunction for arrays
# \details Note, that the order is not the same as input in the array.
# basically here are two arrays, actually dictionaries with a both the same
# primary key. What is done here is 3 things:
# 1. take the first array, order it for the primary keys which leads to 0x000 0x010 0x011...
# 2. take the first primary key, and retrive with it the value from the second array.
# 3. Have both values from bote array and you can be sure thy are the correct onse. 
proc play_with_arrays { } {
  echo "start"
  array set colors {
    0x000 0x0080a
    0x001 0x0080b
    0x010 0x0080c
    0x011 0x0080d
    0x100 0x0030e
    0x101 0x0050f
    0x110 0x0040g
    0x111 0x0070h
  }
  array set colors2 {
    0x000 0x0080a
    0x001 0x0080b
    0x010 0x0080c
    0x011 0x0080d
    0x100 0x0000e
    0x101 0x0000f
    0x110 0x0000g
    0x111 0x0000h
  }
  foreach name [lsort [array names colors]] {
      puts "-----------------------"
      puts "$name is $colors($name)"
      puts "$colors2($name)"
  }
  echo "end"
}

# this has not worked as expected and is the explanation for the more complicated
# way abouve
proc play_with_arrays2 { } {
  echo "start"
  array set colors {
    0x000 [ array 0x0080a 0x89a ]
    0x001 [ array 0x0080b 0x89b ]
    0x010 [ array 0x0080b 0x89b ]
  }
  foreach name [lsort [array names colors]] {
      puts "-----------------------"
      puts "$name is $colors($name)"
      
  }
  echo "end"
}

# \brief run a single test case with default parameters
proc run_single_test { } {
  # bp at end of snippet
  # bp 0x201fe 2 hw
  global handoveraddr_netx90
  testcase_for_single_state 0x2 $handoveraddr_netx90
  mdh $handoveraddr_netx90
}


proc test_odd { } {
  set err 1
  if { $err == 0 } { \
    echo "Return with error cause $err tests have failed."
  }
  set err 2
  if { $err != 0 } { \
    echo "Return with error cause $err tests have failed."
  }
  set err 0
  if { $err != 0 } { \
    echo "Return with error cause $err tests have failed."
  }
}


# Attach to to the COM CPU on an NXHX90-JTAG (netX90) board using the onboard USB-JTAG interface.

# import config of JTAG dongle (NXJTAG-USB)
source [find interface/hilscher_nxjtag_usb.cfg]
# import config of netX90-com-CPU
source [find target/hilscher_netx90_com.cfg]
init
reset_device
run_test

# single test
# testcase_for_single_state 0x2 $handoveraddr_netx90
#test_odd
#play_with_arrays2


echo "remove '-c shutdown' - command in *.bat, if you want to connect to debugging session via telnet. (127.0.0.1:4444)"
