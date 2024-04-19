These is the complete ComScope source code, which supports four traces, 
and multiple signals per trace with width 1,2,4,8 and 16-bit.

The top level is comscope.vhd.

In order to accelerate the synthesis, we recommend that 

a) the unused signals/traces be commented out 
in the INPUT_MUX_TRACE multiplexer within the comscope.vhd code.

b) the unused components be commented out in 
TRACE_x_CAPTURE_y_BIT_WORDS_00z within the comscope.vhd code.


