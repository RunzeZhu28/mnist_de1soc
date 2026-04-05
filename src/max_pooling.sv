module max_pooling(
input  signed [31:0] i_data [0:3],
input  i_pool_en,
output logic signed [31:0] o_pool_data
);

logic signed [31:0] max01, max23;

assign max01       = (i_data[0] > i_data[1]) ? i_data[0] : i_data[1];
assign max23       = (i_data[2] > i_data[3]) ? i_data[2] : i_data[3];
assign o_pool_data = i_pool_en ? ((max01 > max23) ? max01 : max23) : 0;

endmodule