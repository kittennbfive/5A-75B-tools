## A collection of tools and notes made while messing with the Colorlight 5A-75B V7.0 using the FOSS [Yosys](https://github.com/YosysHQ)-toolchain.

(c) 2020-23 by kittennbfive - AGPLv3+ unless otherwise specified

EVERYTHING IS PROVIDED WITHOUT ANY WARRANTY!

This stuff was written by a FPGA-beginner, please be nice and constructive.

### specific to 5A-75B V7.0

`FPGA_Pin_Viewer/` contains a collection of scripts to make a graphical representation (HTML+JS) of the FPGA and show what is connected where.

`Connector_Viewer/` contains some other scripts to make a graphical representation of the Connectors J1-J8, the buffers and the FPGA.

`pin_listing_scripts/` contains some scripts to print various lists of IO (useful for hardware-hacking).

`I_want_inputs/` contains a hardware-modification for getting 5V-tolerant inputs. 

`buffer_overview/` contains some informations about how the IO and buffers are wired (useful for hardware-hacking).

`SDRAM/` will - hopefully one day - contain Verilogcode for the SDRAM (x2) on the board. For now there is only a constraints-file for Yosys/nextpnr...

General informations about the board can be found here: https://github.com/q3k/chubby75

### not (so) specific

`Hello_World_1/` contains a really basic but complete example, from the Verilog-code to the actual programming of the bitstream.

`Geeknotes/` contains informations on how to use the embedded block RAM (EBR) of the ECP5 with Yosys. Some other stuff might be added later.

`ecp5_bb_sanitizer.pl` is useful for generating a wrapper around the ECP5-modules defined in Yosys' `cells_bb.v` where multiple same pins are grouped in buses as Lattice should have done.

`HOWTO_Update.txt` contains the needed commands to update the toolchain (for ECP5).  

**NEW** `beautify-timing-report.pl` somewhat beautifies the critical timing report from nextpnr. Early release, to be improved. Based on an idea from https://github.com/YosysHQ/nextpnr/issues/551
