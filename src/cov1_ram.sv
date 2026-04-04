module cov1_ram(
input clk,
input rst_n,
input signed [31:0] i_cov_result,
input i_valid,
output logic signed [31:0] o_pool_data [0:3],
output logic o_pool_en
);

localparam RAM_SIZE = 18432; //32*24*24
localparam POOLING_NUM = 144; //12*12
localparam RAM_WIDTH = $clog2(RAM_SIZE);
localparam POOLING_COUNTER_WIDTH = $clog2(POOLING_NUM);
//logic [POOLING_COUNTER_WIDTH - 1 : 0] ram_rdaddress, ram_wraddress;
logic [9 : 0] ram_rdaddress, ram_wraddress;

logic [POOLING_COUNTER_WIDTH - 1 : 0] pooling_counter;
logic [1:0] sub_counter; //to count o_pool_data index
logic rd_en;
logic finished;
logic [POOLING_COUNTER_WIDTH - 1 : 0] base_0, base_1, base_2, base_3;
logic [3:0] pool_col;   // 0~11
logic signed [31:0] ram_data;

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin 
		ram_wraddress <= 0;
		finished <= 0;
	end
	else if (ram_rdaddress == POOLING_NUM - 1) begin
		finished <= 0;
	end
	else if(i_valid) begin
		if( ram_wraddress == POOLING_NUM - 1 ) begin
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
    if (!rst_n) begin
        pooling_counter <= 0;
        pool_col        <= 0;
        base_0          <= 0;
        base_1          <= 1;
        base_2          <= 24;
        base_3          <= 25;
    end
    else if (o_pool_en) begin
        if (pool_col < 11) begin
            pool_col <= pool_col + 1;
            base_0   <= base_0 + 2;
            base_1   <= base_1 + 2;
            base_2   <= base_2 + 2;
            base_3   <= base_3 + 2;
        end
        else begin
            pool_col <= 0;
            base_0   <= base_0 + 26;
            base_1   <= base_1 + 26;
            base_2   <= base_2 + 26;
            base_3   <= base_3 + 26;
        end

        if (pooling_counter < 143) pooling_counter <= pooling_counter + 1;
		  else pooling_counter <= 0;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		ram_rdaddress   <= 0;
		rd_en 			  <= 0;
	end
	else begin
			case(sub_counter)
				2'b00: begin
					if(finished || (ram_wraddress > base_0)) begin
						rd_en <= 1;
						ram_rdaddress <= base_0;
					end
					else begin
						rd_en <= 0;
					end
				end
				
				2'b01:begin
					if(finished || (ram_wraddress > base_1)) begin
						rd_en <= 1;
						ram_rdaddress <= base_1;
					end
					else begin
						rd_en <= 0;
					end
				end

				2'b10:begin
					if(finished || (ram_wraddress > base_2)) begin
						rd_en <= 1;
						ram_rdaddress <= base_2;
					end
					else begin
						rd_en <= 0;
					end
				end
				
				2'b11:begin
					if(finished || (ram_wraddress > base_3)) begin
						rd_en <= 1;
						ram_rdaddress <= base_3;
					end
					else begin
						rd_en <= 0;
					end
				end
				default: begin
					ram_rdaddress   <= 0;
					rd_en 			 <= 0;
				end
			endcase
	end
end


always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		sub_counter <= 0;
		o_pool_en   <= 0;
		for(int i = 0; i<4; i= i+1) begin
			o_pool_data[i] <= 0;
		end
	end
	else if(rd_en) begin
		o_pool_data[sub_counter] <= ram_data;
		sub_counter <= sub_counter + 1; //overflow go back to 0
	end
	if (sub_counter == 2'b11) o_pool_en <= 1;
	else o_pool_en   <= 0;
end

RAM_1 u_ram_1(
	.clock(clk),
	.data(i_cov_result),
	.rdaddress(ram_rdaddress),
	.rden(rd_en),
	.wraddress(ram_wraddress),
	.wren(i_valid),
	.q(ram_data)
);

endmodule