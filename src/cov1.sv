module cov1(
input clk,
input rst_n,
input [7:0] i_data,
input i_data_valid,
output logic o_buffer_full,
output logic o_buffer_empty,
output logic signed [31:0] o_cov_result_1, 
output logic signed [31:0] o_cov_result_2, 
output logic signed [31:0] o_cov_result_3,
output logic o_valid_1,
output logic o_valid_2, 
output logic o_valid_3
);

//`ifndef TESTBENCH
localparam BUFFER_SIZE=140;  //5*28
//`else
//localparam BUFFER_SIZE=10;
//`endif
localparam BUFFER_LENGTH     = 28; 
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
logic signed [8:0] feature_map [0:24];
logic signed [31:0] mac_result_1, mac_result_2, mac_result_3;
logic signed [7:0] bias [0:2];

logic mac_enable;
logic last_col;
logic done_1, done_2, done_3;

typedef enum logic {
	BUFFER_UPDATE = 1'b0,
	CAL = 1'b1
} cov_state_t;
cov_state_t cov_state, cov_state_nxt;

/* -----------------------------------------load weight------------------------------------- */
`ifdef TESTBENCH
initial begin
	$readmemh("E:\\mnist\\weight\\conv1_weight_1.txt", weight_1);
	$readmemh("E:\\mnist\\weight\\conv1_weight_2.txt", weight_2);
	$readmemh("E:\\mnist\\weight\\conv1_weight_3.txt", weight_3);
	$readmemh("E:\\mnist\\weight\\conv1_bias.txt", bias);
end
`else  //update with ROM later
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
		if(i_data_valid) begin
			o_buffer_empty <= 0;
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
		else o_buffer_empty <= (done_1 & done_2 & done_3) ? 1'b1 : o_buffer_empty;
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


always_comb begin
	 if(!rst_n) begin
		for(int i = 0; i<25; i = i+1) begin
			feature_map[i] <= 0;
		end  // //convert to signed for MAC calculation
	 end
    feature_map[0]  = {1'b0, buffer[r_buffer_addr]    };
    feature_map[1]  = {1'b0, buffer[r_buffer_addr+1]  };
    feature_map[2]  = {1'b0, buffer[r_buffer_addr+2]  };
    feature_map[3]  = {1'b0, buffer[r_buffer_addr+3]  };
    feature_map[4]  = {1'b0, buffer[r_buffer_addr+4]  };
    feature_map[5]  = {1'b0, buffer[r_buffer_addr_2]  };
    feature_map[6]  = {1'b0, buffer[r_buffer_addr_2+1]};
    feature_map[7]  = {1'b0, buffer[r_buffer_addr_2+2]};
    feature_map[8]  = {1'b0, buffer[r_buffer_addr_2+3]};
    feature_map[9]  = {1'b0, buffer[r_buffer_addr_2+4]};
    feature_map[10] = {1'b0, buffer[r_buffer_addr_3]  };
    feature_map[11] = {1'b0, buffer[r_buffer_addr_3+1]};
    feature_map[12] = {1'b0, buffer[r_buffer_addr_3+2]};
    feature_map[13] = {1'b0, buffer[r_buffer_addr_3+3]};
    feature_map[14] = {1'b0, buffer[r_buffer_addr_3+4]};
    feature_map[15] = {1'b0, buffer[r_buffer_addr_4]  };
    feature_map[16] = {1'b0, buffer[r_buffer_addr_4+1]};
    feature_map[17] = {1'b0, buffer[r_buffer_addr_4+2]};
    feature_map[18] = {1'b0, buffer[r_buffer_addr_4+3]};
    feature_map[19] = {1'b0, buffer[r_buffer_addr_4+4]};
    feature_map[20] = {1'b0, buffer[r_buffer_addr_5]  };
    feature_map[21] = {1'b0, buffer[r_buffer_addr_5+1]};
    feature_map[22] = {1'b0, buffer[r_buffer_addr_5+2]};
    feature_map[23] = {1'b0, buffer[r_buffer_addr_5+3]};
    feature_map[24] = {1'b0, buffer[r_buffer_addr_5+4]};
end

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        r_buffer_addr <= 0;
        last_col      <= 0;
    end
    else if(mac_enable) begin
        if((r_buffer_addr != BUFFER_LENGTH - 5) && !last_col ) begin
            r_buffer_addr <= r_buffer_addr + 1;
            last_col      <= 0;
        end
        else begin
            r_buffer_addr <= 0;
            last_col      <= 1;
        end
    end 
	 else begin
		last_col  <= 0;
		r_buffer_addr <= 0;
	 end
end


mac u_mac1(
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

mac u_mac2(
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

mac u_mac3(
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


assign o_cov_result_1 = mac_result_1 + bias[0];
assign o_cov_result_2 = mac_result_2 + bias[1];
assign o_cov_result_3 = mac_result_3 + bias[2];
endmodule