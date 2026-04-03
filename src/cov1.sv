module cov1(
input clk,
input rst_n,
input [7:0] i_data,
output logic o_buffer_full,
output logic o_buffer_empty
);

`ifndef TESTBENCH
localparam BUFFER_SIZE=140;
`else
localparam BUFFER_SIZE=10;
`endif
localparam BUFFER_LENGTH     = 28; //5*28
localparam BUFFER_DATA_WIDTH = $clog2(BUFFER_SIZE);
logic [7:0] buffer [0:BUFFER_SIZE-1] ;//each pixel 8 bits, 5*28 buffer 
logic [BUFFER_DATA_WIDTH - 1 :0] wr_buffer_addr ; //trace the current buffer writing place
logic [BUFFER_DATA_WIDTH - 1 :0] r_buffer_addr ; //trace the current buffer reading
logic [BUFFER_DATA_WIDTH - 1 :0] r_buffer_addr_2 ; //trace the current buffer reading
logic [BUFFER_DATA_WIDTH - 1 :0] r_buffer_addr_3 ; //trace the current buffer reading
logic [BUFFER_DATA_WIDTH - 1 :0] r_buffer_addr_4 ; //trace the current buffer reading
logic [BUFFER_DATA_WIDTH - 1 :0] r_buffer_addr_5 ; //trace the current buffer reading
logic signed [7:0] weight_1 [0:24];
logic signed [7:0] weight_2 [0:24];
logic signed [7:0] weight_3 [0:24];
logic signed [7:0] feature_map [0:24];
logic signed [19:0] cov_result_1;
logic signed [19:0] cov_result_2;
logic signed [19:0] cov_result_3;
logic mac_enable;
logic last_col;

typedef enum logic {
	BUFFER_UPDATE = 0,
	CAL = 1
} cov_state_t;
cov_state_t cov_state, cov_state_nxt;
/* -----------------------------------------buffer_update------------------------------------- */
always_ff@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(int i = 0; i < BUFFER_SIZE; i = i+1) begin
			buffer[i] <= 0;
		end
		wr_buffer_addr <= 0;
		o_buffer_full <= 0;
	end
	else begin
		buffer[wr_buffer_addr] <= i_data;
		if(wr_buffer_addr == BUFFER_SIZE - 1) begin
			wr_buffer_addr <= 0;
			o_buffer_full <= 1;
		end
		else begin
			wr_buffer_addr <= wr_buffer_addr + 1;
			o_buffer_full <= 0;
		end
	end
end

/* -----------------------------------------state_machine------------------------------------- */
always_comb  begin
	cov_state_nxt = cov_state;
	if(!rst_n) cov_state_nxt = BUFFER_UPDATE;
	else begin
		case(cov_state)
			BUFFER_UPDATE: cov_state_nxt = (wr_buffer_addr == BUFFER_SIZE-1) ? CAL: BUFFER_UPDATE;
			CAL : cov_state_nxt = o_buffer_empty ? BUFFER_UPDATE : CAL;
			default: cov_state_nxt = BUFFER_UPDATE;
		endcase
	end
end

always_ff@(posedge clk or negedge rst_n) begin
	if(!rst_n) cov_state <= BUFFER_UPDATE;
	else cov_state <= cov_state_nxt;
end

assign mac_enable = (cov_state == CAL);
/* -----------------------------------------mac calculation------------------------------------- */
always_comb begin //reduce resource, use this way, not multiplication
    r_buffer_addr_2 = r_buffer_addr + BUFFER_LENGTH;
    r_buffer_addr_3 = r_buffer_addr_2 + BUFFER_LENGTH;
    r_buffer_addr_4 = r_buffer_addr_3 + BUFFER_LENGTH;
	 r_buffer_addr_5 = r_buffer_addr_4 + BUFFER_LENGTH;
end

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		r_buffer_addr <= 0;
		last_col <= 0;
		for(int i = 0; i<25; i = i+1) begin
			feature_map[i] <= 0;
		end
	end
	else begin
		if(mac_enable) begin  
			feature_map[0] <= buffer[r_buffer_addr];
			feature_map[1] <= buffer[r_buffer_addr+1];
			feature_map[2] <= buffer[r_buffer_addr+2];
			feature_map[3] <= buffer[r_buffer_addr+3];
			feature_map[4] <= buffer[r_buffer_addr+4];
			feature_map[5] <= buffer[r_buffer_addr_2];
			feature_map[6] <= buffer[r_buffer_addr_2+1];
			feature_map[7] <= buffer[r_buffer_addr_2+2];
			feature_map[8] <= buffer[r_buffer_addr_2+3];
			feature_map[9] <= buffer[r_buffer_addr_2+4];
			feature_map[10] <= buffer[r_buffer_addr_3];
			feature_map[11] <= buffer[r_buffer_addr_3+1];
			feature_map[12] <= buffer[r_buffer_addr_3+2];
			feature_map[13] <= buffer[r_buffer_addr_3+3];
			feature_map[14] <= buffer[r_buffer_addr_3+4];
			feature_map[15] <= buffer[r_buffer_addr_4];
			feature_map[16] <= buffer[r_buffer_addr_4+1];
			feature_map[17] <= buffer[r_buffer_addr_4+2];
			feature_map[18] <= buffer[r_buffer_addr_4+3];
			feature_map[19] <= buffer[r_buffer_addr_4+4];
			if(r_buffer_addr != BUFFER_LENGTH - 5) begin 
				r_buffer_addr <= r_buffer_addr + 1;
				last_col <= 0;
			end
			else begin
				r_buffer_addr <= 0;
				last_col <= 1;
			end
		end
	end
end

mac u_mac1(
	.clk(clk),
	.rst_n(rst_n),
	.i_weight(weight_1),
	.i_fmap(feature_map),
	.i_mac_enable(mac_enable),
	.i_last_col(last_col),
	.o_mac(cov_result_1),
	.o_mac_done(o_buffer_empty)
);

mac u_mac2(
	.clk(clk),
	.rst_n(rst_n),
	.i_weight(weight_2),
	.i_fmap(feature_map),
	.i_mac_enable(mac_enable),
	.i_last_col(last_col),
	.o_mac(cov_result_2)
);

mac u_mac3(
	.clk(clk),
	.rst_n(rst_n),
	.i_weight(weight_3),
	.i_fmap(feature_map),
	.i_mac_enable(mac_enable),
	.i_last_col(last_col),
	.o_mac(cov_result_3)
);

endmodule