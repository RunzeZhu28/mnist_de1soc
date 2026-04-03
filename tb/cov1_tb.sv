`timescale 1ns/1ps

module cov1_tb;

    logic clk;
    logic rst_n;
    logic [7:0] i_data;
    logic o_buffer_full;
    logic o_buffer_empty;
    parameter BUFFER_SIZE = 10;
    // DUT
    cov1 dut(
        .clk(clk),
        .rst_n(rst_n),
        .i_data(i_data),
        .o_buffer_full(o_buffer_full),
        .o_buffer_empty(o_buffer_empty)
    );

    // clock: 10ns period
    always #5 clk = ~clk;

    // stimulus
    initial begin
        clk = 0;
        rst_n = 0;
        i_data = 0;

        // reset
        #20;
        rst_n = 1;

        // data_in 0,1,2,3...
        repeat (10) begin
            @(posedge clk);
            i_data <= i_data + 1;
        end

        // 
        repeat (10) @(posedge clk);
        $finish;
    end

    // monitor
    always @(posedge clk) begin
        if (rst_n) begin
            $display("time=%0t | addr=%0d | data_in=%0d | full=%0d",
                     $time,
                     dut.buffer_addr,
                     i_data,
                     o_buffer_full);
        end
    end

    // Output buffer when full
    always @(posedge clk) begin
        if (o_buffer_full) begin
            $display("---- BUFFER FULL ----");
            for (int i = 0; i < BUFFER_SIZE; i++) begin
                $display("buffer[%0d] = %0d", i, dut.buffer[i]);
            end
            $display("---------------------");
        end
    end

endmodule