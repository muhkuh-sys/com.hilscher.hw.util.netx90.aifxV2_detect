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
# snippet with a endless wait loop executed from romloader core
set hboot_chunk_snippet_endless_loop "../../targets/verification/test02/test02_netx90_snippet_hbootimage.bin"
set cmd_rec_jump_loop 0xBF00E7FE
# ruecksprung aus snippet auf andere adresse. 
set intram1_start_addr 0x00040000
#at internal RAM INTRAM3_S at location 0x2008 0000
set intram3_start_addr 0x20080000

#--- Reset function
# \brief reset netX 90 
# \details procedure according to: https://kb.hilscher.com/x/GylbBg
proc run_test_02 {} {
    global bp_netx90_rev1_first_romloader
    global intram1_start_addr
    global cmd_rec_jump_loop
    global intram3_start_addr
    global hboot_chunk_snippet_endless_loop
    global path_snippet_bin
    halt

	  echo "########"
	  echo "run: reset_device"
	  echo "########"


    # for debugging purpose, stop before execution of exec chunk
    # bp address from : https://kb.hilscher.com/x/ghMWBg (netX90 rev1)
    # bp 0x170a2 2 hw
    # bp ... 2 -> for 16buit thumb code ( assumption )
    # bp $bp_netx90_rev1_first_romloader 2 hw
    
    # --------------------------------- configure test -----------------------------------------------------
    # addr from linker skript
    set snippet_load_address 0x000200C0
    # addr from snippet.xml (or elf file)
    # set romcode_look_up_addr 0x20080000
    set invalid_word 0xAFFEE5E1 
    echo "load hboot image with jump to wait-for-event-loop: $hboot_chunk_snippet_endless_loop"
    # invalidate a image at this position
    mww $snippet_load_address $invalid_word
    mww $intram3_start_addr $invalid_word
    # load new image
    load_image $hboot_chunk_snippet_endless_loop $intram3_start_addr bin
    
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
    

    # Position of hard coded while1_loop in netX90rev0/1 romcode
    # see e.g. https://github.com/muhkuh-sys/mbs/blob/master/site_scons/hboot_netx90_patch_table.xml
    set addr_romloader_while1_loop 0x1FC
    # just an other loop, here wait for event. One has a breakpoint, one not. This runs for expectation of reset
    set addr_romloader_WFE_loop 0x1F6
    # set breakpoint to addr to catch this execution. Is also the last exec-command(chunk) from the end of the loaded hboot image.
    bp $addr_romloader_while1_loop 2 hw
    # use existing while loop, to let controller run and expect reset taking effect
    reg pc $addr_romloader_WFE_loop

    ## set PC into endless loop
    echo "Set pc to start of intram1 where endless loop resides"
    # mww $intram1_start_addr $cmd_rec_jump_loop

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

    set err 0
    echo "expect to be at $addr_romloader_while1_loop"
    # dose not work: set reg_pc [ reg pc ] (remains empty
    # todo: compare position

    # ---------------------------------- execute test--------------------------------------------------------    
    # download snippet to netX
    # todo: replace by a verify
    verify_image $path_snippet_bin $snippet_load_address bin
    
    echo "Verification succeeded!"
    	
    echo ""
    echo "########"
    echo "### finished test 02 !!!"
    echo "########"

    # device is now in defined state at the first possible pc, where to hold
}





# Attach to to the COM CPU on an NXHX90-JTAG (netX90) board using the onboard USB-JTAG interface.

# import config of JTAG dongle (NXJTAG-USB)
source [find interface/hilscher_nxjtag_usb.cfg]
# import config of netX90-com-CPU
source [find target/hilscher_netx90_com.cfg]
init

run_test_02

# the erify fails and returns script with 1. So if we've reached here, verify passed!
s_ok
s_train

echo "remove '-c shutdown' - command in *.bat, if you want to connect to debugging session via telnet. (127.0.0.1:4444)"
