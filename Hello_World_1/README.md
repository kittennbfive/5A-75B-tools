**VALID ONLY FOR 5A-75B V7.0 ECP5 CABGA256**  
  
**PROVIDED WITHOUT ANY WARRANTY!**  

This is a REALLY basic example just to check the toolchain and the programming and get started.  

It is basically a direct connection (trough the FPGA) of the button and the (second) LED.  
The LED will light as long as you press the button.  
Current consumption of the board is about 100mA.  

The actual Verilog code is in `top.v`.  

## Prerequisites
### Making the toolchain
https://github.com/YosysHQ/prjtrellis  
https://github.com/YosysHQ/yosys  
https://github.com/YosysHQ/nextpnr - make sure to choose the right architecture!  

## Compiling
### Synthesize  
`yosys -p "read_verilog -pwires top.v; synth_ecp5 -json out.json -top top.v"`  
The command is quite verbose, you can add `-q` to reduce this.  

### Place and route  
`nextpnr-ecp5 --json out.json --25k --package CABGA256 --lpf constraints.lpf --textcfg out.cfg`  
Same as above concerning verbosity.  

### Create programming file
`ecppack --svf bitstream.svf out.cfg`  
  
The result `bitstream.svf` is a big text file (just like `out.json` and `out.cfg`, look at them if you are curious) that contains JTAG-instructions to flash the FPGA (not the FLASH-IC, so it will only last until power cycling the board).  

## Programming
I first tried with a *Bus Pirate* and openocd but it did not work and was really slow, like over 2 minutes.  

I then tried with a **FT232H-board** (not FT2232) from China and openocd and it works great and takes one second.  
  
**Before connecting check that your programmer uses 3.3V!**

Connections:  

| Pin_5A | Signal | Pin_FT232H |
|--------|--------|------------|
| J27    | TCK    | AD0        |
| J31    | TMS    | AD3        |
| J32    | TDI    | AD1        |
| J30    | TDO    | AD2        |
| J34    | GND    | GND        |

If everything including GND is connected and powered up run `openocd -f /usr/share/openocd/scripts/interface/ftdi/um232h.cfg -f prog_openocd.cfg`. This should be really quick.  

Beware that the bitstream is only stored inside the FPGA-RAM, so it will be lost if you unplug power.  
  
  
  
  
  
(c) 2020-22 by kittennbfive - AGPLv3+ - NO WARRANTY!
