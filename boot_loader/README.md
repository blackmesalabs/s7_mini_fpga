This is the USB bootloader design for the S7-Mini FPGA board it allows changing
the FPGA firmware without a JTAG programmer and Xilinx Vivado software.
Unfortunately it still requires a JTAG programmer and Xilinx Vivado SW to load
the 1st time, much like an Arduino bootloader. Once it is loaded, firmware
can be updated JTAG and Xilinx Vivado free.

It has two functions:
  1) Act as a Slot-0 Bootloader which either:
     a) Immediately reconfigures FPGA with a Slot-1 user image.
     b) Stays resident and facilitates programming a new PROM image
        either into Slot-0 or Slot-1.
  2) Slot-1 template design allowing Slot-1 design to update Slot-1 image.

  By default, the Slot-0 design looks for a jumper on J1. If the jumper is in
  place, the Slot-0 design stays resident and provides a 921,600 baud MesaBus
  USB serial interface to a PC using a $20 FTDI TTL-232R-3V3 cable. 
  Note: The S7-Mini has a number of test point SMT pads that could be used
  instead of the J1 0.100" jumper. The test point only needs a soft-pullup
  and to be grounded to force the Slot-0 design to stay resident.

  Typical use scenario is I load the Slot-0 design only once and use it only
  in the event I make and load a Slot-1 design that is totally borked by an i
  internal local bus issue. For infrequent scenarios like this, it might make
  sense to free up the J1 jumper and use a hard to access test point pad.

  WARNING: The top.v input parameter i_am_slot0 must be assigned appropriately
  or else the FPGA may loop indefinitely reconfiguring itself.

  About the MesaBus :
    MesaBus is an open source serial protocol from Black Mesa Labs that 
    provides a virtual 32bit PCI like bus interface over either UART or SPI
    serial links. It isn't designed to be a high speed bus, but a slow control
    bus for writing and reading to FPGA local bus registers and also updating
    firmware stored in PROM.
    The MesaBus supports 254 slots per physical link where a slot is a single
    FPGA. Within each slot are 15 subslots.  BML has arbitrarily assigned 
    subslot-0x0 for user Local Bus access and subslot-0xE for PROM access.
    More info here:
      https://blackmesalabs.wordpress.com/2016/03/04/mesa-bus/ 
      https://github.com/blackmesalabs/MesaBusProtocol

  Software :
    bd_shell ( "Back door shell" ) is a UNIX shell like command line tool that
    speaks MesaBus protocol and has built in functions for loading PROMs.
    Example: bd>prom_load top.bin slot1
    More info here:
      https://github.com/blackmesalabs/bd_shell

  How to get started:
    Step-1) Build a Slot-0 design with parameter i_am_slot0 == 1;
    Step-2) Build a Slot-1 design with parameter i_am_slot0 == 0;
    Step-3) Use Xilinx Vivado + HS2 JTAG programmer to program Slot-0 design.
    Step-4) Place J1 jumper in place.
    Step-5) Boot the board. LEDs should flash rapidly.
    Step-6) Using FTDI cable and bd_shell, load slot-1 design via the command:
      prom_load slot1.bin slot1
    Step-7) Power off board. Remove J1 Jumper. 
    Step-8) Power on board. LEDs should flash slowly indicating Slot-1 design.

EOF khubbard 2019.05.25
