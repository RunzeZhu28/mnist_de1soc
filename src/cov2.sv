module conv2 #(parameter CHANNEL = 0)(
input clk,
input rst_n,
input [31:0] i_data,
input i_data_valid,
output logic o_buffer_full,
output logic o_buffer_empty,
output logic signed [31:0] o_conv_result,
output logic o_valid,
output logic o_in_ready
);
logic signed [31:0] o_conv_result_1;
logic signed [31:0] o_conv_result_2; 
logic signed [31:0] o_conv_result_3;
localparam BUFFER_SIZE=60;  //5*12

localparam BUFFER_LENGTH     = 12; 
localparam BUFFER_DATA_WIDTH = $clog2(BUFFER_SIZE);
logic signed [31:0] buffer [0:BUFFER_SIZE-1] ;//each 32 bits, 5*12 buffer 
logic [BUFFER_DATA_WIDTH - 1 :0] wr_buffer_addr ; //trace the current buffer writing place
logic [BUFFER_DATA_WIDTH - 1 :0] r_buffer_addr ; //trace the current buffer reading
logic [BUFFER_DATA_WIDTH - 1 :0] r_buffer_addr_2 ; //trace the current buffer reading
logic [BUFFER_DATA_WIDTH - 1 :0] r_buffer_addr_3 ; //trace the current buffer reading
logic [BUFFER_DATA_WIDTH - 1 :0] r_buffer_addr_4 ; //trace the current buffer reading
logic [BUFFER_DATA_WIDTH - 1 :0] r_buffer_addr_5 ; //trace the current buffer reading
logic signed [7:0] weight_1 [0:24];
logic signed [7:0] weight_2 [0:24];
logic signed [7:0] weight_3 [0:24];
logic signed [31:0] feature_map [0:24];
logic signed [31:0] mac_result_1, mac_result_2, mac_result_3;
logic signed [7:0] bias [0:2];
logic mac_enable;
logic last_col;
logic done, done_1, done_2, done_3;
logic o_valid_1, o_valid_2, o_valid_3;
assign done = done_1 && done_2 && done_3;

typedef enum logic {
	BUFFER_UPDATE = 1'b0,
	CAL = 1'b1
} conv_state_t;
conv_state_t conv_state, conv_state_nxt;
//assign o_in_ready = (conv_state == 1'b0);
assign o_in_ready = ~o_buffer_full || o_buffer_empty;
/* -----------------------------------------load weight------------------------------------- */
`ifdef TESTBENCH
initial begin
	$readmemh("E:\\mnist\\weight\\conv2_bias.txt", bias);
if(CHANNEL == 0) begin
	$readmemh("E:\\mnist\\weight\\conv2_weight_11.txt", weight_1);
	$readmemh("E:\\mnist\\weight\\conv2_weight_12.txt", weight_2);
	$readmemh("E:\\mnist\\weight\\conv2_weight_13.txt", weight_3);
end
else if(CHANNEL == 1) begin
	$readmemh("E:\\mnist\\weight\\conv2_weight_21.txt", weight_1);
	$readmemh("E:\\mnist\\weight\\conv2_weight_22.txt", weight_2);
	$readmemh("E:\\mnist\\weight\\conv2_weight_23.txt", weight_3);
end
else begin
	$readmemh("E:\\mnist\\weight\\conv2_weight_31.txt", weight_1);
	$readmemh("E:\\mnist\\weight\\conv2_weight_32.txt", weight_2);
	$readmemh("E:\\mnist\\weight\\conv2_weight_33.txt", weight_3);
end
end
`else  //update with ROM later
`endif

`ifdef TESTBENCH
always_ff @(posedge clk) begin
    if (i_data_valid) begin
        if ($isunknown(i_data)) begin
            $display("[%0t] CHANNEL=%0d i_data is X when valid, wr_addr=%0d, i_data=%h",
                     $time, CHANNEL, wr_buffer_addr, i_data);
        end
    end
end

always_ff @(posedge clk) begin
    if (mac_enable) begin
        if ($isunknown(buffer[r_buffer_addr])) begin
            $display("[%0t] CHANNEL=%0d buffer X at r_buffer_addr=%0d, data=%h",
                     $time, CHANNEL, r_buffer_addr, buffer[r_buffer_addr]);
        end
    end
end
`else
`endif
/* -----------------------------------------buffer_update------------------------------------- */
always_ff@(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		for(int i = 0; i < BUFFER_SIZE; i = i+1) begin
			buffer[i] <= 0;
		end
		wr_buffer_addr <= 0;
		o_buffer_full <= 0;
		o_buffer_empty <= 1;
	end
	else begin
		o_buffer_full <= 0;
		if(i_data_valid) begin
			o_buffer_empty <= 0;
			$display("[%0t] CH=%0d WRITE buffer[%0d] = %h", $time, CHANNEL, wr_buffer_addr, i_data);
			buffer[wr_buffer_addr] <= i_data;
			if(wr_buffer_addr == BUFFER_SIZE - 1) begin
				$display("\n[%0t] ===== BUFFER FULL (CH=%0d) =====", $time, CHANNEL);
				for(int i = 0; i < BUFFER_SIZE; i++) begin
					$display("buffer[%0d] = %h", i, buffer[i]);
				end
				$display("====================================\n");
				wr_buffer_addr <= 0;
				o_buffer_full <= 1;
			end
			else begin
				wr_buffer_addr <= wr_buffer_addr + 1;
				o_buffer_full <= 0;
			end
		end
		else o_buffer_empty <= done ? 1'b1 : o_buffer_empty;
	end
end

/* -----------------------------------------state_machine------------------------------------- */
always_comb  begin
	conv_state_nxt = conv_state;
	if(!rst_n) conv_state_nxt = BUFFER_UPDATE;
	else begin
		case(conv_state)
			BUFFER_UPDATE: conv_state_nxt = (wr_buffer_addr == BUFFER_SIZE-1) ? CAL: BUFFER_UPDATE;
			CAL : conv_state_nxt = (r_buffer_addr == BUFFER_LENGTH - 5) ? BUFFER_UPDATE : CAL;
			default: conv_state_nxt = BUFFER_UPDATE;
		endcase
	end
end

always_ff@(posedge clk or negedge rst_n) begin
	if(!rst_n) conv_state <= BUFFER_UPDATE;
	else conv_state <= conv_state_nxt;
end

assign mac_enable = (conv_state == CAL);
/* -----------------------------------------mac calculation------------------------------------- */
always_comb begin //reduce resource, use this way, not multiplication
    r_buffer_addr_2 = r_buffer_addr + BUFFER_LENGTH;
    r_buffer_addr_3 = r_buffer_addr_2 + BUFFER_LENGTH;
    r_buffer_addr_4 = r_buffer_addr_3 + BUFFER_LENGTH;
	 r_buffer_addr_5 = r_buffer_addr_4 + BUFFER_LENGTH;
end


always_comb begin
	 if(!rst_n) begin
		for(int i = 0; i<25; i = i+1) begin
			feature_map[i] <= 0;
		end  // //convert to signed for MAC calculation
	 end
	 else if(mac_enable) begin
    	feature_map[0]  = buffer[r_buffer_addr]    ;
    	feature_map[1]  = buffer[r_buffer_addr+1]  ;
    	feature_map[2]  = buffer[r_buffer_addr+2]  ;
    	feature_map[3]  = buffer[r_buffer_addr+3]  ;
    	feature_map[4]  = buffer[r_buffer_addr+4]  ;
    	feature_map[5]  = buffer[r_buffer_addr_2]  ;
    	feature_map[6]  = buffer[r_buffer_addr_2+1];
    	feature_map[7]  = buffer[r_buffer_addr_2+2];
    	feature_map[8]  = buffer[r_buffer_addr_2+3];
    	feature_map[9]  = buffer[r_buffer_addr_2+4];
    	feature_map[10] = buffer[r_buffer_addr_3]  ;
    	feature_map[11] = buffer[r_buffer_addr_3+1];
    	feature_map[12] = buffer[r_buffer_addr_3+2];
    	feature_map[13] = buffer[r_buffer_addr_3+3];
    	feature_map[14] = buffer[r_buffer_addr_3+4];
    	feature_map[15] = buffer[r_buffer_addr_4]  ;
    	feature_map[16] = buffer[r_buffer_addr_4+1];
    	feature_map[17] = buffer[r_buffer_addr_4+2];
    	feature_map[18] = buffer[r_buffer_addr_4+3];
    	feature_map[19] = buffer[r_buffer_addr_4+4];
    	feature_map[20] = buffer[r_buffer_addr_5]  ;
    	feature_map[21] = buffer[r_buffer_addr_5+1];
    	feature_map[22] = buffer[r_buffer_addr_5+2];
    	feature_map[23] = buffer[r_buffer_addr_5+3];
    	feature_map[24] = buffer[r_buffer_addr_5+4];
	 end
end

assign last_col = (r_buffer_addr == BUFFER_LENGTH - 5);

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_buffer_addr <= 0;
    end
    else if(mac_enable) begin
        if((r_buffer_addr != BUFFER_LENGTH - 5) && !last_col ) begin
            r_buffer_addr <= r_buffer_addr + 1;
        end
        else begin
            r_buffer_addr <= 0;
        end
    end 
	 else begin
		r_buffer_addr <= 0;
	 end
end


mac #(.FMAP_WIDTH(31))
u_mac1(
	.clk(clk),
	.rst_n(rst_n),
	.i_weight(weight_1),
	.i_fmap(feature_map),
	.i_mac_enable(mac_enable),
	.i_last_col(last_col),
	.o_mac(mac_result_1),
	.o_mac_done(done_1),
	.o_valid(o_valid_1)
);

mac #(.FMAP_WIDTH(31))  
u_mac2(
	.clk(clk),
	.rst_n(rst_n),
	.i_weight(weight_2),
	.i_fmap(feature_map),
	.i_mac_enable(mac_enable),
	.i_last_col(last_col),
	.o_mac(mac_result_2),
	.o_mac_done(done_2),
	.o_valid(o_valid_2)
);
mac #(.FMAP_WIDTH(31))
u_mac3(
	.clk(clk),
	.rst_n(rst_n),
	.i_weight(weight_3),
	.i_fmap(feature_map),
	.i_mac_enable(mac_enable),
	.i_last_col(last_col),
	.o_mac(mac_result_3),
	.o_mac_done(done_3),
	.o_valid(o_valid_3)
);


assign o_conv_result = mac_result_1 + mac_result_2 + mac_result_3 + bias[CHANNEL];
assign o_valid = o_valid_1 && o_valid_2 && o_valid_3;
endmodule