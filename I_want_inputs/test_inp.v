module test_inputs(input wire J6_1, input wire J6_2, output wire led);

assign led=!(J6_1!=J6_2);

endmodule
