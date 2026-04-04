`timescale 1ns/1ps

module cov1_tb;

    // --------------------
    // Signals
    // --------------------
    logic clk;
    logic rst_n;
    logic [7:0] i_data;
    logic i_data_valid;
    logic o_buffer_full;
    logic o_buffer_empty;

    // DUT
    cov1 dut(
        .clk(clk),
        .rst_n(rst_n),
        .i_data(i_data),
        .i_data_valid(i_data_valid),
        .o_buffer_full(o_buffer_full),
        .o_buffer_empty(o_buffer_empty)
    );

    // --------------------
    // Clock generation
    // --------------------
    always #5 clk = ~clk; // 10ns period

    // --------------------
    // Golden model arrays (same size as DUT)
    // --------------------
    logic signed [7:0] golden_weight_1 [0:24];
    logic signed [7:0] golden_weight_2 [0:24];
    logic signed [7:0] golden_weight_3 [0:24];
    logic signed [7:0] golden_bias [0:2];
    // Load weights/bias
//`ifdef TESTBENCH
initial begin
    // declare loop vars first
    int a, b, c, d;

    $readmemh("E:\\mnist\\weight\\conv1_weight_1.txt", golden_weight_1);
    $readmemh("E:\\mnist\\weight\\conv1_weight_2.txt", golden_weight_2);
    $readmemh("E:\\mnist\\weight\\conv1_weight_3.txt", golden_weight_3);
    $readmemh("E:\\mnist\\weight\\conv1_bias.txt", golden_bias);

    // Print weights
    $display("=== Weight 1 ===");
    for (a = 0; a < 25; a++) $display("weight_1[%0d] = %0d", a, golden_weight_1[a]);

    $display("=== Weight 2 ===");
    for (b = 0; b < 25; b++) $display("weight_2[%0d] = %0d", b, golden_weight_2[b]);

    $display("=== Weight 3 ===");
    for (c = 0; c < 25; c++) $display("weight_3[%0d] = %0d", c, golden_weight_3[c]);

    // Print bias
    $display("=== Bias ===");
    for (d = 0; d < 3; d++) $display("bias[%0d] = %0d", d, golden_bias[d]);
end
//`endif

    // --------------------
    // Golden model function
    // --------------------
    function automatic int calc_golden(int base, int ch);
        int sum;
        int idx;
        int pixel;
        int i;
        sum = 0;
        for (i = 0; i < 25; i++) begin
            idx = i;
            pixel = base + (i/5)*28 + (i%5); // same addressing as DUT
            case(ch)
                0: sum += pixel * golden_weight_1[idx];
                1: sum += pixel * golden_weight_2[idx];
                2: sum += pixel * golden_weight_3[idx];
            endcase
        end
        sum += golden_bias[ch];
        return sum;
    endfunction

    // --------------------
    // Stimulus
    // --------------------
    initial begin
        clk = 0;
        rst_n = 0;
        i_data = 0;
        i_data_valid = 0;
        // Apply reset
        #20;
        rst_n = 1;

        // Give DUT a moment to init
        #1;

        for (int i = 0; i < 140; i++) begin
            i_data_valid <= 1;
            i_data <= i; // just use 0..139 as pixel values
            @(posedge clk);
        end

        i_data_valid <= 0;
        // Wait some cycles for MAC to finish
        repeat(200) @(posedge clk);

        $display("===== TEST FINISHED =====");
        $finish;
    end

    // --------------------
    // Golden model check
    // --------------------
    int window_id = 0;
    int golden1, golden2, golden3;

    always @(posedge clk) begin
        if(window_id == 24) begin 
            repeat(2) @(posedge clk); 
            $finish;
        end

        if (rst_n && dut.mac_enable) begin
            if(dut.o_valid_1 && dut.o_valid_2 && dut.o_valid_3) begin
                // Compute golden results for this window
                golden1 = calc_golden(window_id, 0);
                golden2 = calc_golden(window_id, 1);
                golden3 = calc_golden(window_id, 2);

                #1; // allow DUT o_cov_result to update

                if (dut.o_cov_result_1 !== golden1 ||
                    dut.o_cov_result_2 !== golden2 ||
                    dut.o_cov_result_3 !== golden3) begin
                    $display("❌ ERROR at window %0d", window_id);
                    $display("CH1 exp=%0d got=%0d", golden1, dut.o_cov_result_1);
                    $display("CH2 exp=%0d got=%0d", golden2, dut.o_cov_result_2);
                    $display("CH3 exp=%0d got=%0d", golden3, dut.o_cov_result_3);
                    $stop;
                end else begin
                    $display("✅ PASS window %0d | CH1=%0d CH2=%0d CH3=%0d",
                             window_id,
                             dut.o_cov_result_1,
                             dut.o_cov_result_2,
                             dut.o_cov_result_3);
                end

                window_id++;
            end
            
        end
    end

   //always @(posedge clk) begin
   //if (o_buffer_full) begin
   //    for (int i = 0; i < 140; i++) begin
   //        $display("buffer[%0d] = %0d", i, dut.buffer[i]);
   //    end
   //end
   //end
endmodule