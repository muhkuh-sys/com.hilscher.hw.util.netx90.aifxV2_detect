This is the test description for testing the aifxV2_detect snippet

# Purpose of snipped
This snipped is desigened to tell a firmware via hand-over-parameters, which
type of interface is connected to the netX. To determine this,
the signals at checked pins are evaluated. The reult is stored iin the hand over parameter.

# Hardware Setup
For this test a PCIe Card with a mounted netX90rev1 PCIe card was used.
The PCIe card is mounted on the PapaSchlumpf to have pover. any other PCIe Power supply over PCIe 
would be sufficent enough. The tested card has a additionally attached JTAG-Connector. This is mandatory to
execute this test. 
The content of the netX flash is empty.
The pinns XM0_IO1  COM_IO1  COM_IO0, and Vcc are provided via a flat cable to a breadboard.
Vcc is connected to three paralell 1Rk Resistors. The IO-Pinns may be connected to the Resistors or not.
Per default all pinns are pulled down via internal resistors. This is archived by the loaded snippet.
Connect the Pins to the resistors and thy are pulled up. Pulled up pins are logical 1 and pulled
down pins are logical 2.

# The test
Open OCD opens the testscript, establishes a connection to the NXHX-JTAG USB Jtag Adapter (nöxus).
The netX is resetted. The test stsarts and the user is asked to input the correct level through the
3 I-pins to be tested. After the final of 8 iterations the testresult is presented.

# Preparations:
- start the test.bat, check if configured rotaryswitch position is displayed.
- follow the commands displayed on screen


# Selction Matrix

    XM0_IO1 | COM_IO1 | COM_IO0
    ------------------------------
     0      | x       | x        | => RTE connector (0x80)
    ------------------------------
     1      | 0       | 0        | => CAN open (0x30)
    ------------------------------
     1      | 0       | 1        | => Profibus (0x50)
    ------------------------------
     1      | 1       | 0        | => DeviceNet (0x40)
    ------------------------------
     1      | 1       | 1        | => CC-Link   (0x70)

# links
issue can be found at:
    
    https://ticket.hilscher.com/browse/NXTHWCONFI-133