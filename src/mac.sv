module mac(
input clk,
input rst_n,
input [7:0] i_weight [0:24], //5*5 weight
input [7:0] i_fmap [0:24],   //5*5 feature map
input i_mac_enable,
input i_last_col,
output logic signed [19:0] o_mac, //MAC output
output logic o_mac_done
);

always_ff @(posedge clk or negedge rst_n)
begin
	if(!rst_n) begin
		o_mac <= 20'b0;
		o_mac_done <= 0;
	end
	else begin
		if(i_mac_enable == 1'b1) begin
			o_mac <= i_weight[0]*i_fmap[0] + i_weight[1]*i_fmap[1] +
                 i_weight[2]*i_fmap[2] + i_weight[3]*i_fmap[3] +
                 i_weight[4]*i_fmap[4] + i_weight[5]*i_fmap[5] +
                 i_weight[6]*i_fmap[6] + i_weight[7]*i_fmap[7] +
                 i_weight[8]*i_fmap[8] + i_weight[9]*i_fmap[9] +
                 i_weight[10]*i_fmap[10] + i_weight[11]*i_fmap[11] +
                 i_weight[12]*i_fmap[12] + i_weight[13]*i_fmap[13] +
                 i_weight[14]*i_fmap[14] + i_weight[15]*i_fmap[15] +
                 i_weight[16]*i_fmap[16] + i_weight[17]*i_fmap[17] +
                 i_weight[18]*i_fmap[18] + i_weight[19]*i_fmap[19] +
                 i_weight[20]*i_fmap[20] + i_weight[21]*i_fmap[21] +
                 i_weight[22]*i_fmap[22] + i_weight[23]*i_fmap[23] +
                 i_weight[24]*i_fmap[24];
		   o_mac_done <= i_last_col;
		end
		else begin
			o_mac <= 0; 
			o_mac_done <= 0;
		end
		
	end
end

endmodule