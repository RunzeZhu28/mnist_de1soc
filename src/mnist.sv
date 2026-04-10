module mnist(
input clk,
input rst_n,
output logic [3:0] decision,
output logic decision_valid
);


localparam RAM2_SIZE = 4608;  //32*12*12

logic [7:0] i_data [0:783];
logic [7:0] data;
logic data_valid, data_finish;
logic buffer_full, buffer_empty;
logic signed [31:0] conv_result_1, conv_result_2, conv_result_3;
logic signed [31:0] conv2_result_1, conv2_result_2, conv2_result_3;
logic valid_1,valid_2,valid_3;
logic frame_start; //pulse
logic frame_started;
logic signed [31:0] pool_data_1 [0:3];
logic signed [31:0] pool_data_2 [0:3];
logic signed [31:0] pool_data_3 [0:3];
logic signed [31:0] conv2_pool_data_1 [0:3];
logic signed [31:0] conv2_pool_data_2 [0:3];
logic signed [31:0] conv2_pool_data_3 [0:3];
logic pool_en_1, pool_en_2, pool_en_3;
logic conv2_pool_en_1, conv2_pool_en_2, conv2_pool_en_3;
logic signed [31:0] max_pool_data_1, max_pool_data_2, max_pool_data_3;
logic signed [31:0] max_pool_ram_data_1, max_pool_ram_data_2, max_pool_ram_data_3;
logic signed [31:0] conv2_max_pool_data_1, conv2_max_pool_data_2, conv2_max_pool_data_3;
logic pool_ram_almost_full_1, pool_ram_almost_full_2, pool_ram_almost_full_3;
logic pool_ram_rd_valid_1, pool_ram_rd_valid_2, pool_ram_rd_valid_3;
logic conv2_valid_1, conv2_valid_2, conv2_valid_3;
logic conv2_buffer_empty_1, conv2_buffer_empty_2, conv2_buffer_empty_3;
logic conv2_buffer_full_1, conv2_buffer_full_2, conv2_buffer_full_3;
logic conv2_in_ready_1, conv2_in_ready_2, conv2_in_ready_3;
logic ch1_full, ch2_full, ch3_full;

initial begin
	$readmemh("E:\\mnist\\mnist_data.txt", i_data); //5
	$readmemh("E:\\mnist\\2.txt", i_data); //2
	$readmemh("E:\\mnist\\1.txt", i_data); //1
	$readmemh("E:\\mnist\\3.txt", i_data); //3
end

always_ff @(posedge clk or negedge rst_n) begin //will change this part later to send different data
    if (!rst_n) begin
        frame_start   <= 1'b0;
        frame_started <= 1'b0;
    end
    else if (!frame_started) begin
        frame_start   <= 1'b1;
        frame_started <= 1'b1;
    end
    else begin
        frame_start   <= 1'b0;
    end
end

data_seg u_data_seg(
	.clk(clk),
	.rst_n(rst_n),
	.i_frame_start(frame_start),
	.i_data(i_data), 
	.i_buffer_full(buffer_full), 
	.i_buffer_empty(buffer_empty),
	.o_data(data),
	.o_data_valid(data_valid),
	.o_data_finish(data_finish) // will be used later
);

conv1 u_conv1(
	.clk(clk),
	.rst_n(rst_n),
	.i_data(data),
	.i_data_valid(data_valid),
	.o_buffer_full(buffer_full),
	.o_buffer_empty(buffer_empty),
	.o_conv_result_1(conv_result_1), 
	.o_conv_result_2(conv_result_2), 
	.o_conv_result_3(conv_result_3),
	.o_valid_1(valid_1),
	.o_valid_2(valid_2), 
	.o_valid_3(valid_3)
);

conv1_ram	u_conv1_ram_1(
	.clk(clk),
	.rst_n(rst_n),
	.i_conv_result(conv_result_1),
	.i_valid(valid_1),  // may need to add !pool_ram_almost_full_1, fix it later
	.o_pool_data(pool_data_1),
	.o_pool_en(pool_en_1)
);

max_pooling u_max_pooling_1(
	.i_data(pool_data_1),
	.i_pool_en(pool_en_1),
	.o_pool_data(max_pool_data_1)
);

conv1_ram	u_conv1_ram_2(
	.clk(clk),
	.rst_n(rst_n),
	.i_conv_result(conv_result_2),
	.i_valid(valid_2),
	.o_pool_data(pool_data_2),
	.o_pool_en(pool_en_2)
);

max_pooling u_max_pooling_2(
	.i_data(pool_data_2),
	.i_pool_en(pool_en_2),
	.o_pool_data(max_pool_data_2)
);

conv1_ram	u_conv1_ram_3(
	.clk(clk),
	.rst_n(rst_n),
	.i_conv_result(conv_result_3),
	.i_valid(valid_3),
	.o_pool_data(pool_data_3),
	.o_pool_en(pool_en_3)
);

max_pooling u_max_pooling_3(
	.i_data(pool_data_3),
	.i_pool_en(pool_en_3),
	.o_pool_data(max_pool_data_3)
);


pooling_ram u_pooling_ram_1(
	.clk(clk),
	.rst_n(rst_n),
	.i_pool_data(max_pool_data_1),
	.i_wr_valid(pool_en_1), 
	.i_rd_ready(conv2_in_ready_1),
	.i_buffer_full(conv2_buffer_full_1),
	.o_ram_data(max_pool_ram_data_1),
	.o_ram_rd_data_valid(pool_ram_rd_valid_1),
	.o_ram_almost_full(pool_ram_almost_full_1)
);

conv2 #(.CHANNEL(0))
u_conv2_1
(
	.clk(clk),
	.rst_n(rst_n),
	.i_data(max_pool_ram_data_1),
	.i_data_valid(pool_ram_rd_valid_1),
	.o_buffer_full(conv2_buffer_full_1),
	.o_buffer_empty(conv2_buffer_empty_1),
	.o_conv_result(conv2_result_1),
	.o_valid(conv2_valid_1),
	.o_in_ready(conv2_in_ready_1)
);

pooling_ram u_pooling_ram_2(
	.clk(clk),
	.rst_n(rst_n),
	.i_pool_data(max_pool_data_2),
	.i_wr_valid(pool_en_2), 
	.i_rd_ready(conv2_in_ready_2),
	.i_buffer_full(conv2_buffer_full_2),
	.o_ram_data(max_pool_ram_data_2),
	.o_ram_rd_data_valid(pool_ram_rd_valid_2),
	.o_ram_almost_full(pool_ram_almost_full_2)
);

conv2 #(.CHANNEL(1))
u_conv2_2
(
	.clk(clk),
	.rst_n(rst_n),
	.i_data(max_pool_ram_data_2),
	.i_data_valid(pool_ram_rd_valid_2),
	.o_buffer_full(conv2_buffer_full_2),
	.o_buffer_empty(conv2_buffer_empty_2),
	.o_conv_result(conv2_result_2),
	.o_valid(conv2_valid_2),
	.o_in_ready(conv2_in_ready_2)
);

pooling_ram u_pooling_ram_3(
	.clk(clk),
	.rst_n(rst_n),
	.i_pool_data(max_pool_data_3),
	.i_wr_valid(pool_en_3), 
	.i_rd_ready(conv2_in_ready_3),
	.i_buffer_full(conv2_buffer_full_3),
	.o_ram_data(max_pool_ram_data_3),
	.o_ram_rd_data_valid(pool_ram_rd_valid_3),
	.o_ram_almost_full(pool_ram_almost_full_3)
);

conv2 #(.CHANNEL(2))
u_conv2_3
(
	.clk(clk),
	.rst_n(rst_n),
	.i_data(max_pool_ram_data_3),
	.i_data_valid(pool_ram_rd_valid_3),
	.o_buffer_full(conv2_buffer_full_3),
	.o_buffer_empty(conv2_buffer_empty_3),
	.o_conv_result(conv2_result_3),
	.o_valid(conv2_valid_3),
	.o_in_ready(conv2_in_ready_3)
);

conv2_ram	u_conv2_ram_1(
	.clk(clk),
	.rst_n(rst_n),
	.i_conv_result(conv2_result_1),
	.i_valid(conv2_valid_1),  // may need to add !pool_ram_almost_full_1, fix it later
	.o_pool_data(conv2_pool_data_1),
	.o_pool_en(conv2_pool_en_1)
);

max_pooling u_conv2_max_pooling_1(
	.i_data(conv2_pool_data_1),
	.i_pool_en(conv2_pool_en_1),
	.o_pool_data(conv2_max_pool_data_1)
);

conv2_ram	u_conv2_ram_2(
	.clk(clk),
	.rst_n(rst_n),
	.i_conv_result(conv2_result_2),
	.i_valid(conv2_valid_2),  // may need to add !pool_ram_almost_full_1, fix it later
	.o_pool_data(conv2_pool_data_2),
	.o_pool_en(conv2_pool_en_2)
);

max_pooling u_conv2_max_pooling_2(
	.i_data(conv2_pool_data_2),
	.i_pool_en(conv2_pool_en_2),
	.o_pool_data(conv2_max_pool_data_2)
);

conv2_ram	u_conv2_ram_3(
	.clk(clk),
	.rst_n(rst_n),
	.i_conv_result(conv2_result_3),
	.i_valid(conv2_valid_3),  // may need to add !pool_ram_almost_full_1, fix it later
	.o_pool_data(conv2_pool_data_3),
	.o_pool_en(conv2_pool_en_3)
);

max_pooling u_conv2_max_pooling_3(
	.i_data(conv2_pool_data_3),
	.i_pool_en(conv2_pool_en_3),
	.o_pool_data(conv2_max_pool_data_3)
);

fc u_fc(
	.clk(clk),
	.rst_n(rst_n),
   .i_pool_data_1(conv2_max_pool_data_1),
   .i_wr_valid_1(conv2_pool_en_1),
   .i_pool_data_2(conv2_max_pool_data_2),
   .i_wr_valid_2(conv2_pool_en_2),
   .i_pool_data_3(conv2_max_pool_data_3),
   .i_wr_valid_3(conv2_pool_en_3),
   .o_decision_valid(decision_valid),
   .decision(decision),
   .o_ch1_full(ch1_full),
   .o_ch2_full(ch2_full),
   .o_ch3_full(ch3_full)
);
endmodule