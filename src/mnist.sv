module mnist(
input clk,
input rst_n,
output decision
);


localparam RAM2_SIZE = 4608;  //32*12*12

logic [7:0] i_data [0:783];
logic [7:0] data;
logic data_valid;
logic buffer_full, buffer_empty;
logic signed [31:0] cov_result_1, cov_result_2, cov_result_3;
logic valid_1,valid_2,valid_3;
logic frame_start; //pulse
logic frame_started;


initial begin
	$readmemh("E:\\mnist\\mnist_data.txt", i_data); //5
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
	.o_data_valid(data_valid)
);

cov1 u_cov1(
	.clk(clk),
	.rst_n(rst_n),
	.i_data(data),
	.i_data_valid(data_valid),
	.o_buffer_full(buffer_full),
	.o_buffer_empty(buffer_empty),
	.o_cov_result_1(cov_result_1), 
	.o_cov_result_2(cov_result_2), 
	.o_cov_result_3(cov_result_3),
	.o_valid_1(valid_1),
	.o_valid_2(valid_2), 
	.o_valid_3(valid_3)
);





endmodule