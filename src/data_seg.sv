module data_seg(
input clk,
input rst_n,
input i_frame_start,  //new frame comes
input [7:0] i_data [0:783], //28*28 raw data
input i_buffer_full, //stop sending when buffer_full
input i_buffer_empty,// start sending when buffer_empty
output logic [7:0] o_data,
output logic o_data_valid,
output logic o_data_finish
);

localparam ADDR_WIDTH = $clog2(784);
logic [ADDR_WIDTH - 1 : 0] addr;
logic started;

always_ff @(posedge clk or negedge rst_n) begin
	if(!rst_n) begin
		addr <= 0;
		o_data <= 0;
		o_data_valid <= 0;
		//o_data_finish <= 0;
		started <= 0;
	end
	else if (i_frame_start) begin //pulse
		addr <= 1;
		started <= 1;
		o_data <= i_data[0];
		o_data_valid <= 1'b1;
		//o_data_finish <= 0;
	end
	else if(started && !o_data_finish && (i_buffer_empty || (o_data_valid && !i_buffer_full))) begin
		o_data_valid <= 1'b1;
		o_data <= i_data[addr];
		addr <= (addr == 783) ? 0 : (addr + 1);
		started <= (addr == 0) ? 0 : 1;
	end
	else if(i_buffer_full) begin
		o_data_valid <= 0;
		//addr <= addr;
		addr <= (addr == 0) ? 0 : (addr - 112); //move by one line each time, 28*4=112
		//o_data_finish <= (addr == 0) ? 1 : 0;
		started <= (addr == 0) ? 0 : 1;
	end
	else begin
        o_data_valid <= 0;
   end
end

assign o_data_finish = ~started;
endmodule