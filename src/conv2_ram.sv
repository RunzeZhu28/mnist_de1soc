module conv2_ram(
input clk,
input rst_n,
input signed [31:0] i_conv_result,
input i_valid,
output logic signed [31:0] o_pool_data [0:3],
output logic o_pool_en
);

localparam RAM_SIZE = 64; //8*8
localparam RAM_WIDTH = $clog2(RAM_SIZE);
logic [9 : 0] ram_rdaddress, ram_wraddress;
logic [1:0] sub_counter,pix_counter; //to count o_pool_data index
logic rd_en;
logic finished;
logic [RAM_WIDTH - 1 : 0] base_0, base_1, base_2, base_3;
logic [3:0] pool_col;   // 0~11
logic signed [31:0] ram_data;
logic ram_en;


always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		ram_wraddress <= 0;
		finished <= 0;
	end
	else if (ram_rdaddress == RAM_SIZE - 1) begin
		finished <= 0;
	end
	else if(i_valid) begin
		if( ram_wraddress == RAM_SIZE - 1 ) begin
			ram_wraddress <= 0;
			finished <= 1;
		end
		else begin
			ram_wraddress <= ram_wraddress + 1;
			finished <= finished;
		end
	end
	else begin
		ram_wraddress <= ram_wraddress;
		finished <= finished;
	end
end

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		ram_rdaddress   <= 0;
		sub_counter <= 0;
		rd_en 			  <= 0;
      pool_col        <= 0;
      base_0          <= 0;
      base_1          <= 1;
      base_2          <= 8;
      base_3          <= 9;
		pool_col			 <= 0;
	end
	else begin
			
			case(sub_counter)
				2'b00: begin
					if(finished || (ram_wraddress > base_0)) begin
						rd_en <= 1;
						ram_rdaddress <= base_0;
						sub_counter <= sub_counter + 1; //overflow go back to 0
						base_0   <= (pool_col < 3)  ? (base_0 + 2) :  (((base_0 + 10) > RAM_SIZE - 1) ? 0 : (base_0 + 10));
					end
					else begin
						rd_en <= 0;
					end
				end
				
				2'b01:begin
					if(finished || (ram_wraddress > base_1)) begin
						rd_en <= 1;
						ram_rdaddress <= base_1;
						sub_counter <= sub_counter + 1; //overflow go back to 0
						base_1   <= (pool_col < 3)  ? (base_1 + 2) :  (((base_1 + 10) > RAM_SIZE - 1) ? 1 : (base_1 + 10));
					end
					else begin
						rd_en <= 0;
					end
				end

				2'b10:begin
					if(finished || (ram_wraddress > base_2)) begin
						rd_en <= 1;
						ram_rdaddress <= base_2;
						sub_counter <= sub_counter + 1; //overflow go back to 0
						base_2   <= (pool_col < 3)  ? (base_2 + 2) :  (((base_2 + 10) > RAM_SIZE - 1) ? 8 : (base_2 + 10));
					end
					else begin
						rd_en <= 0;
					end
				end
				
				2'b11:begin
					if(finished || (ram_wraddress > base_3)) begin
						rd_en <= 1;
						ram_rdaddress <= base_3;
						sub_counter <= sub_counter + 1; //overflow go back to 0
						base_3   <= (pool_col < 3)  ? (base_3 + 2) :  (((base_3 + 10) > RAM_SIZE - 1) ? 9 : (base_3 + 10));
						pool_col <= (pool_col == 3)  ?  0 : (pool_col + 1);
					end
					else begin
						rd_en <= 0;
					end
				end
				default: begin
					ram_rdaddress   <= 0;
					rd_en 			 <= 0;
					sub_counter 	 <= 0; //overflow go back to 0
					base_0          <= 0;
					base_1          <= 1;
					base_2          <= 8;
					base_3          <= 9;
					pool_col        <= 0;
				end
			endcase
	end
end

always_ff @(posedge clk or negedge rst_n) begin // trace which of four is sending out
	if(!rst_n) pix_counter <= 0;
	else if(ram_en) pix_counter <= pix_counter + 1;
	else pix_counter <= pix_counter;
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for (int i=0; i<4; i=i+1) o_pool_data[i] <= 0;
				o_pool_en <= 0;
    end
    else begin
        o_pool_en <= 0;
        if (ram_en) begin
            o_pool_data[pix_counter] <= ram_data;
            if (pix_counter == 2'b11)
                o_pool_en <= 1;
        end
    end
end

always_ff @(posedge clk or negedge rst_n) begin  //RAM has 1 cycle delay to read data
	if(!rst_n) begin
		ram_en <= 1'b0;
	end
	else ram_en <= rd_en;
end

RAM_1 u_ram_1(
	.clock(clk),
	.data(i_conv_result),
	.rdaddress(ram_rdaddress),
	.rden(rd_en),
	.wraddress(ram_wraddress),
	.wren(i_valid),
	.q(ram_data)
);

endmodule