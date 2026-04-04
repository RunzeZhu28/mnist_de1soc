`timescale 1ns/1ps

module mnist_tb;

    localparam int IMG_W         = 28;
    localparam int IMG_H         = 28;
    localparam int K             = 5;
    localparam int OUT_W         = IMG_W - K + 1;   // 24
    localparam int OUT_H         = IMG_H - K + 1;   // 24
    localparam int TOTAL_WINDOWS = OUT_W * OUT_H;   // 576

    logic clk;
    logic rst_n;
    logic decision;

    mnist dut(
        .clk     (clk),
        .rst_n   (rst_n),
        .decision(decision)
    );

    always #5 clk = ~clk;

    logic signed [7:0] golden_weight_1 [0:24];
    logic signed [7:0] golden_weight_2 [0:24];
    logic signed [7:0] golden_weight_3 [0:24];
    logic signed [7:0] golden_bias     [0:2];
    logic        [7:0] golden_data     [0:783];

    int cur_row;
    int cur_col;
    int total_pass;
    int golden1, golden2, golden3;
    int buff_num;

    logic prev_mac_enable;
    logic skip_first_valid;

    initial begin
        $readmemh("E:\\mnist\\weight\\conv1_weight_1.txt", golden_weight_1);
        $readmemh("E:\\mnist\\weight\\conv1_weight_2.txt", golden_weight_2);
        $readmemh("E:\\mnist\\weight\\conv1_weight_3.txt", golden_weight_3);
        $readmemh("E:\\mnist\\weight\\conv1_bias.txt",     golden_bias);
        $readmemh("E:\\mnist\\mnist_data.txt",             golden_data);
    end

    function automatic int calc_golden(input int row, input int col, input int ch);
        int sum;
        int base;
        int pixel;
        int i;
        begin
            base = row * 28 + col;
            sum  = 0;
            for (i = 0; i < 25; i++) begin
                pixel = golden_data[base + (i/5)*28 + (i%5)];
                case (ch)
                    0: sum += pixel * golden_weight_1[i];
                    1: sum += pixel * golden_weight_2[i];
                    2: sum += pixel * golden_weight_3[i];
                    default: sum += 0;
                endcase
            end
            sum += golden_bias[ch];
            return sum;
        end
    endfunction

    initial begin
        clk            = 0;
        rst_n          = 0;
        cur_row        = -1;
        cur_col        = 0;
        total_pass     = 0;
        golden1        = 0;
        golden2        = 0;
        golden3        = 0;
        buff_num       = 0;
        prev_mac_enable= 0;
        skip_first_valid = 0;

        #20;
        rst_n = 1;
    end

    initial begin
        repeat (20000) @(posedge clk);
        $display("===== TIMEOUT =====");
        $finish;
    end

    int out_col;
    logic prev_valid;

always @(posedge clk) begin
    #1;

    if (!rst_n) begin
        cur_row     = -1;
        out_col     = 0;
        total_pass  = 0;
        prev_mac_enable = 0;
        prev_valid  = 0;
    end
    else begin
        if (cur_row == 24) begin
            $display("===== All success =====");
            $finish;
        end
        if (dut.u_cov1.mac_enable && !prev_mac_enable) begin
            cur_row  = cur_row + 1;
            out_col  = 0;
            $display("===== START ROW %0d =====", cur_row);
        end


        if (dut.valid_1 && dut.valid_2 && dut.valid_3) begin
            if (cur_row >= 0 && cur_row < OUT_H && out_col < OUT_W) begin
                golden1 = calc_golden(cur_row, out_col, 0);
                golden2 = calc_golden(cur_row, out_col, 1);
                golden3 = calc_golden(cur_row, out_col, 2);

                if (dut.cov_result_1 !== golden1 ||
                        dut.cov_result_2 !== golden2 ||
                        dut.cov_result_3 !== golden3) begin
                        $display("ERROR at row=%0d col=%0d", cur_row, out_col);
                        $display("CH1 exp=%0d got=%0d", golden1, dut.cov_result_1);
                        $display("CH2 exp=%0d got=%0d", golden2, dut.cov_result_2);
                        $display("CH3 exp=%0d got=%0d", golden3, dut.cov_result_3);
                        $stop;
                    end
                    else begin
                        $display("PASS row=%0d col=%0d | CH1=%0d CH2=%0d CH3=%0d",
                                 cur_row, out_col,
                                 dut.cov_result_1,
                                 dut.cov_result_2,
                                 dut.cov_result_3);
                    end


                out_col = out_col + 1;
                total_pass = total_pass + 1;
            end
        end

        prev_mac_enable = dut.u_cov1.mac_enable;
    end
end

    //always @(posedge clk) begin
    //    #1;
    //    if (dut.buffer_full) begin
    //        $display("===== BUFFER FULL : buff_num = %0d =====", buff_num);
    //        for (int i = 0; i < 140; i++) begin
    //            $display("buffer[%0d] = %0d", i, dut.u_cov1.buffer[i]);
    //        end
    //        buff_num = buff_num + 1;
    //    end
    //end

endmodule