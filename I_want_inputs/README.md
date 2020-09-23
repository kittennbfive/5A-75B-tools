**VALID ONLY FOR 5A-75B V7.0 ECP5 CABGA256**  

**PROVIDED WITHOUT ANY WARRANTY!**

The 5A-75B lacks inputs but has lots of outputs buffered with `74HC245T` *powered by 5V*, ie these things are buffers *and level-shifters* together. They are bidirectional but the FPGA does **not** support 5V, so we can't just rewire the DIR-pin.

A solution is to remove the buffers and use small custom made PCBs to bridge the right pins. This way we get direct access (well, almost, there are 33 Ohm resistors in series) to the FPGA pins that can be configured as input or output, but this solution is strictly 3,3V only (at least without external level-shifters).

I decided to use `SN74LVC245APWR` (full name for ordering some, i bought mine at RS). These things are very similar to the 74**HC**245 but they are 3,3V only(!!) *but* can tolerate up to 5,5V on the inputs. Of course we can't just solder them directly in place of the old buffers because the supply voltage is wrong (5V instead of 3,3V) and the DIR-pin must be grounded instead of connected to Vcc.

Luckely these two pins (DIR and Vcc, 1 and 20) are on the most left side of the IC which means we can do a little surgery: I removed the old buffer, put some polyimide tape over the 2 pins that must be connected elsewhere and soldered a 74LVC245 on the remaining pins. Then i used some fine wire to connect DIR (pin 1) to GND (on a capacitor nearby) and Vcc (pin 20) to **3,3V**.

I tested with a very simple bitstream that is just an XOR of 2 inputs and it seems to work.

**IMPORTANT:** You need to make sure that the pins of the FPGA that are used as inputs are configured properly, ie as INPUTS and not as OUTPUTS as in the default bitstream. Otherwise you will have the FPGA fighting against the buffer, thats not good... To do this you could programm a bitstream that uses the FPGA-pins as inputs into the FLASH or - as i did - remove the FLASH so the FPGA will power up unconfigured. Of course removing the FLASH means you need to reprogramm the FPGA after each power cycle, but for me this is just fine (I use this as a devboard to learn Verilog.). This also reduces the current consumption from 250-300mA (configured with default bitstream) to about 80mA unconfigured.

If you want to add more inputs you can use my tool in Connector_Viewer/ to visualize which buffer is connected where, what pins are connected together and so on.

Happy hacking!
