module max_pooling(
input clk,
input rst_n,
input logic signed [31:0] i_data [0:3],
output logic o_pool_data
);

logic max01, max23;
assign max01 = (i_data[0] > i_data[1]) ? i_data[0] : i_data[1];
assign max23 = (i_data[2] > i_data[3]) ? i_data[2] : i_data[3];
assign o_pool_data  = (max01 > max23) ? max01 : max23;

endmodule