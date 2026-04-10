`timescale 1ns/1ps

module mnist_tb;

    localparam int IMG_W         = 28;
    localparam int IMG_H         = 28;
    localparam int K             = 5;

    localparam int OUT_W         = IMG_W - K + 1;   // 24
    localparam int OUT_H         = IMG_H - K + 1;   // 24
    localparam int TOTAL_WINDOWS = OUT_W * OUT_H;   // 576

    localparam int POOL_W        = OUT_W / 2;       // 12
    localparam int POOL_H        = OUT_H / 2;       // 12
    localparam int POOL_NUM      = POOL_W * POOL_H; // 144

    localparam int CONV2_W       = POOL_W - K + 1;  // 8
    localparam int CONV2_H       = POOL_H - K + 1;  // 8
    localparam int CONV2_NUM     = CONV2_W * CONV2_H; // 64

    localparam int CONV2_POOL_W   = CONV2_W / 2;      // 4
    localparam int CONV2_POOL_H   = CONV2_H / 2;      // 4
    localparam int CONV2_POOL_NUM = CONV2_POOL_W * CONV2_POOL_H; //16

    localparam int FC_IN_NUM      = 48;
    localparam int FC_OUT_NUM     = 10;

    logic clk;
    logic rst_n;
    logic [3:0] decision;
    logic       decision_valid;

    mnist dut(
        .clk           (clk),
        .rst_n         (rst_n),
        .decision      (decision),
        .decision_valid(decision_valid)
    );

    // -----------------------------
    // Golden data for conv1
    // -----------------------------
    logic signed [7:0] golden_weight_1 [0:24];
    logic signed [7:0] golden_weight_2 [0:24];
    logic signed [7:0] golden_weight_3 [0:24];
    logic signed [7:0] golden_bias     [0:2];
    logic        [7:0] golden_data     [0:783];

    // Save conv1 outputs in scan order
    logic signed [31:0] conv_seen_mem_1 [0:TOTAL_WINDOWS-1];
    logic signed [31:0] conv_seen_mem_2 [0:TOTAL_WINDOWS-1];
    logic signed [31:0] conv_seen_mem_3 [0:TOTAL_WINDOWS-1];

    // -----------------------------
    // Golden data for conv2
    // -----------------------------
    logic signed [7:0] golden_conv2_w11 [0:24];
    logic signed [7:0] golden_conv2_w12 [0:24];
    logic signed [7:0] golden_conv2_w13 [0:24];

    logic signed [7:0] golden_conv2_w21 [0:24];
    logic signed [7:0] golden_conv2_w22 [0:24];
    logic signed [7:0] golden_conv2_w23 [0:24];

    logic signed [7:0] golden_conv2_w31 [0:24];
    logic signed [7:0] golden_conv2_w32 [0:24];
    logic signed [7:0] golden_conv2_w33 [0:24];

    logic signed [7:0] golden_conv2_bias [0:2];

    // Save maxpool outputs in scan order for conv2 golden
    logic signed [31:0] maxpool_seen_mem_1 [0:POOL_NUM-1];
    logic signed [31:0] maxpool_seen_mem_2 [0:POOL_NUM-1];
    logic signed [31:0] maxpool_seen_mem_3 [0:POOL_NUM-1];

    // Save conv2 outputs for conv2_pool golden
    logic signed [31:0] conv2_seen_mem_1 [0:CONV2_NUM-1];
    logic signed [31:0] conv2_seen_mem_2 [0:CONV2_NUM-1];
    logic signed [31:0] conv2_seen_mem_3 [0:CONV2_NUM-1];

    // -----------------------------
    // Golden data for FC
    // -----------------------------
    logic signed [7:0] golden_fc_bias [0:FC_OUT_NUM-1];
    logic signed [7:0] golden_fc_weight_flat [0:FC_IN_NUM*FC_OUT_NUM-1];
    logic signed [7:0] golden_fc_weight [0:FC_OUT_NUM-1][0:FC_IN_NUM-1];

    logic signed [31:0] fc_seen_data [0:FC_IN_NUM-1];
    logic signed [31:0] fc_golden_data [0:FC_OUT_NUM-1];
    logic [3:0] golden_selected_index;
    logic signed [31:0] golden_fc_max;

    integer conv_idx;
    integer conv_row;
    integer conv_col;
    integer conv_pass;

    logic signed [31:0] golden1, golden2, golden3;

    integer pool_idx_1, pool_idx_2, pool_idx_3;
    integer pool_match_1, pool_match_2, pool_match_3;
    integer pool_err_1,   pool_err_2,   pool_err_3;

    integer maxpool_match_1, maxpool_match_2, maxpool_match_3;
    integer maxpool_err_1,   maxpool_err_2,   maxpool_err_3;

    integer conv2_idx_1, conv2_idx_2, conv2_idx_3;
    integer conv2_match_1, conv2_match_2, conv2_match_3;
    integer conv2_err_1,   conv2_err_2,   conv2_err_3;

    integer conv2_row;
    integer conv2_col;
    logic signed [31:0] conv2_golden;

    integer conv2_pool_idx_1, conv2_pool_idx_2, conv2_pool_idx_3;
    integer conv2_pool_match_1, conv2_pool_match_2, conv2_pool_match_3;
    integer conv2_pool_err_1,   conv2_pool_err_2,   conv2_pool_err_3;

    integer conv2_maxpool_match_1, conv2_maxpool_match_2, conv2_maxpool_match_3;
    integer conv2_maxpool_err_1,   conv2_maxpool_err_2,   conv2_maxpool_err_3;

    integer fc_input_match_cnt, fc_input_err_cnt;
    integer fc_match_cnt, fc_err_cnt;
    integer final_decision_match_cnt, final_decision_err_cnt;

    integer fc_cls, fc_i, gi, gj;
    longint signed fc_sum;

    logic signed [31:0] pool1_data_0, pool1_data_1, pool1_data_2, pool1_data_3;
    logic signed [31:0] pool2_data_0, pool2_data_1, pool2_data_2, pool2_data_3;
    logic signed [31:0] pool3_data_0, pool3_data_1, pool3_data_2, pool3_data_3;

    logic signed [31:0] max_pool_data_1, max_pool_data_2, max_pool_data_3;

    logic signed [31:0] conv2_pool1_data_0, conv2_pool1_data_1, conv2_pool1_data_2, conv2_pool1_data_3;
    logic signed [31:0] conv2_pool2_data_0, conv2_pool2_data_1, conv2_pool2_data_2, conv2_pool2_data_3;
    logic signed [31:0] conv2_pool3_data_0, conv2_pool3_data_1, conv2_pool3_data_2, conv2_pool3_data_3;

    logic signed [31:0] conv2_max_pool_data_1, conv2_max_pool_data_2, conv2_max_pool_data_3;

    assign pool1_data_0 = dut.pool_data_1[0];
    assign pool1_data_1 = dut.pool_data_1[1];
    assign pool1_data_2 = dut.pool_data_1[2];
    assign pool1_data_3 = dut.pool_data_1[3];

    assign pool2_data_0 = dut.pool_data_2[0];
    assign pool2_data_1 = dut.pool_data_2[1];
    assign pool2_data_2 = dut.pool_data_2[2];
    assign pool2_data_3 = dut.pool_data_2[3];

    assign pool3_data_0 = dut.pool_data_3[0];
    assign pool3_data_1 = dut.pool_data_3[1];
    assign pool3_data_2 = dut.pool_data_3[2];
    assign pool3_data_3 = dut.pool_data_3[3];

    assign max_pool_data_1 = dut.max_pool_data_1;
    assign max_pool_data_2 = dut.max_pool_data_2;
    assign max_pool_data_3 = dut.max_pool_data_3;

    assign conv2_pool1_data_0 = dut.conv2_pool_data_1[0];
    assign conv2_pool1_data_1 = dut.conv2_pool_data_1[1];
    assign conv2_pool1_data_2 = dut.conv2_pool_data_1[2];
    assign conv2_pool1_data_3 = dut.conv2_pool_data_1[3];

    assign conv2_pool2_data_0 = dut.conv2_pool_data_2[0];
    assign conv2_pool2_data_1 = dut.conv2_pool_data_2[1];
    assign conv2_pool2_data_2 = dut.conv2_pool_data_2[2];
    assign conv2_pool2_data_3 = dut.conv2_pool_data_2[3];

    assign conv2_pool3_data_0 = dut.conv2_pool_data_3[0];
    assign conv2_pool3_data_1 = dut.conv2_pool_data_3[1];
    assign conv2_pool3_data_2 = dut.conv2_pool_data_3[2];
    assign conv2_pool3_data_3 = dut.conv2_pool_data_3[3];

    assign conv2_max_pool_data_1 = dut.conv2_max_pool_data_1;
    assign conv2_max_pool_data_2 = dut.conv2_max_pool_data_2;
    assign conv2_max_pool_data_3 = dut.conv2_max_pool_data_3;

    initial clk = 0;
    always #5 clk = ~clk;

    // -----------------------------------------
    // Load golden files
    // -----------------------------------------
    initial begin
        $readmemh("E:\\mnist\\weight\\conv1_weight_1.txt", golden_weight_1);
        $readmemh("E:\\mnist\\weight\\conv1_weight_2.txt", golden_weight_2);
        $readmemh("E:\\mnist\\weight\\conv1_weight_3.txt", golden_weight_3);
        $readmemh("E:\\mnist\\weight\\conv1_bias.txt",     golden_bias);
        //$readmemh("E:\\mnist\\mnist_data.txt",             golden_data);
        $readmemh("E:\\mnist\\2.txt",             golden_data);
        $readmemh("E:\\mnist\\1.txt",             golden_data);
        $readmemh("E:\\mnist\\3.txt",             golden_data);
        $readmemh("E:\\mnist\\weight\\conv2_weight_11.txt", golden_conv2_w11);
        $readmemh("E:\\mnist\\weight\\conv2_weight_12.txt", golden_conv2_w12);
        $readmemh("E:\\mnist\\weight\\conv2_weight_13.txt", golden_conv2_w13);

        $readmemh("E:\\mnist\\weight\\conv2_weight_21.txt", golden_conv2_w21);
        $readmemh("E:\\mnist\\weight\\conv2_weight_22.txt", golden_conv2_w22);
        $readmemh("E:\\mnist\\weight\\conv2_weight_23.txt", golden_conv2_w23);

        $readmemh("E:\\mnist\\weight\\conv2_weight_31.txt", golden_conv2_w31);
        $readmemh("E:\\mnist\\weight\\conv2_weight_32.txt", golden_conv2_w32);
        $readmemh("E:\\mnist\\weight\\conv2_weight_33.txt", golden_conv2_w33);

        $readmemh("E:\\mnist\\weight\\conv2_bias.txt",      golden_conv2_bias);

        $readmemh("E:\\mnist\\weight\\fc_bias.txt",         golden_fc_bias);
        $readmemh("E:\\mnist\\weight\\fc_weight.txt",       golden_fc_weight_flat);

        for (gi = 0; gi < FC_OUT_NUM; gi = gi + 1) begin
            for (gj = 0; gj < FC_IN_NUM; gj = gj + 1) begin
                golden_fc_weight[gi][gj] = golden_fc_weight_flat[gi*FC_IN_NUM + gj];
            end
        end
    end

    // -----------------------------------------
    // conv1 golden
    // -----------------------------------------
    function automatic logic signed [31:0] calc_golden(
        input integer row,
        input integer col,
        input integer ch
    );
        longint signed sum;
        integer base;
        integer pixel;
        integer i;
        begin
            base = row * 28 + col;
            sum  = 0;
            for (i = 0; i < 25; i = i + 1) begin
                pixel = golden_data[base + (i/5)*28 + (i%5)];
                case (ch)
                    0: sum = sum + pixel * golden_weight_1[i];
                    1: sum = sum + pixel * golden_weight_2[i];
                    2: sum = sum + pixel * golden_weight_3[i];
                    default: sum = sum;
                endcase
            end
            sum = sum + golden_bias[ch];
            calc_golden = sum[31:0];
        end
    endfunction

    function automatic logic signed [31:0] max4(
        input logic signed [31:0] a,
        input logic signed [31:0] b,
        input logic signed [31:0] c,
        input logic signed [31:0] d
    );
        logic signed [31:0] m01, m23;
        begin
            m01  = (a > b) ? a : b;
            m23  = (c > d) ? c : d;
            max4 = (m01 > m23) ? m01 : m23;
        end
    endfunction

    // -----------------------------------------
    // conv2 golden
    // -----------------------------------------
    function automatic logic signed [31:0] calc_golden_conv2(
        input integer row,
        input integer col,
        input integer ch
    );
        longint signed sum;
        integer base;
        integer addr;
        logic signed [31:0] pix;
        integer i;
        begin
            base = row * POOL_W + col;
            sum  = 0;

            for (i = 0; i < 25; i = i + 1) begin
                addr = base + (i/5)*POOL_W + (i%5);

                case (ch)
                    0: begin
                        pix = maxpool_seen_mem_1[addr];
                        sum = sum
                            + pix * golden_conv2_w11[i]
                            + pix * golden_conv2_w12[i]
                            + pix * golden_conv2_w13[i];
                    end

                    1: begin
                        pix = maxpool_seen_mem_2[addr];
                        sum = sum
                            + pix * golden_conv2_w21[i]
                            + pix * golden_conv2_w22[i]
                            + pix * golden_conv2_w23[i];
                    end

                    2: begin
                        pix = maxpool_seen_mem_3[addr];
                        sum = sum
                            + pix * golden_conv2_w31[i]
                            + pix * golden_conv2_w32[i]
                            + pix * golden_conv2_w33[i];
                    end

                    default: begin
                        sum = sum;
                    end
                endcase
            end

            sum = sum + golden_conv2_bias[ch];
            calc_golden_conv2 = sum[31:0];
        end
    endfunction

    // -----------------------------------------
    // pool + maxpool compare tasks
    // -----------------------------------------
    task automatic compare_pool_and_max_ch1(input integer idx);
        integer pr, pc;
        integer addr0, addr1, addr2, addr3;
        logic signed [31:0] exp0, exp1, exp2, exp3;
        logic signed [31:0] exp_max;
        begin
            pr = idx / POOL_W;
            pc = idx % POOL_W;

            addr0 = (pr * 2)     * OUT_W + (pc * 2);
            addr1 = addr0 + 1;
            addr2 = addr0 + OUT_W;
            addr3 = addr2 + 1;

            exp0 = conv_seen_mem_1[addr0];
            exp1 = conv_seen_mem_1[addr1];
            exp2 = conv_seen_mem_1[addr2];
            exp3 = conv_seen_mem_1[addr3];
            exp_max = max4(exp0, exp1, exp2, exp3);

            if ((pool1_data_0 !== exp0) ||
                (pool1_data_1 !== exp1) ||
                (pool1_data_2 !== exp2) ||
                (pool1_data_3 !== exp3)) begin
                pool_err_1 = pool_err_1 + 1;
                $display("============================================================");
                $display("POOL1 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("addr   = [%0d, %0d, %0d, %0d]", addr0, addr1, addr2, addr3);
                $display("DUT    = [%0d, %0d, %0d, %0d]",
                         pool1_data_0, pool1_data_1, pool1_data_2, pool1_data_3);
                $display("GOLDEN = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("============================================================");
                $stop;
            end
            else begin
                pool_match_1 = pool_match_1 + 1;
                $display("POOL1 PASS idx=%0d -> [%0d, %0d, %0d, %0d]",
                         idx, pool1_data_0, pool1_data_1, pool1_data_2, pool1_data_3);
            end

            if (max_pool_data_1 !== exp_max) begin
                maxpool_err_1 = maxpool_err_1 + 1;
                $display("============================================================");
                $display("MAXPOOL1 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("INPUT4   = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("DUT MAX  = %0d", max_pool_data_1);
                $display("GOLDEN   = %0d", exp_max);
                $display("============================================================");
                $stop;
            end
            else begin
                maxpool_match_1 = maxpool_match_1 + 1;
                $display("MAXPOOL1 PASS idx=%0d -> %0d", idx, max_pool_data_1);
            end
        end
    endtask

    task automatic compare_pool_and_max_ch2(input integer idx);
        integer pr, pc;
        integer addr0, addr1, addr2, addr3;
        logic signed [31:0] exp0, exp1, exp2, exp3;
        logic signed [31:0] exp_max;
        begin
            pr = idx / POOL_W;
            pc = idx % POOL_W;

            addr0 = (pr * 2)     * OUT_W + (pc * 2);
            addr1 = addr0 + 1;
            addr2 = addr0 + OUT_W;
            addr3 = addr2 + 1;

            exp0 = conv_seen_mem_2[addr0];
            exp1 = conv_seen_mem_2[addr1];
            exp2 = conv_seen_mem_2[addr2];
            exp3 = conv_seen_mem_2[addr3];
            exp_max = max4(exp0, exp1, exp2, exp3);

            if ((pool2_data_0 !== exp0) ||
                (pool2_data_1 !== exp1) ||
                (pool2_data_2 !== exp2) ||
                (pool2_data_3 !== exp3)) begin
                pool_err_2 = pool_err_2 + 1;
                $display("============================================================");
                $display("POOL2 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("addr   = [%0d, %0d, %0d, %0d]", addr0, addr1, addr2, addr3);
                $display("DUT    = [%0d, %0d, %0d, %0d]",
                         pool2_data_0, pool2_data_1, pool2_data_2, pool2_data_3);
                $display("GOLDEN = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("============================================================");
                $stop;
            end
            else begin
                pool_match_2 = pool_match_2 + 1;
                $display("POOL2 PASS idx=%0d -> [%0d, %0d, %0d, %0d]",
                         idx, pool2_data_0, pool2_data_1, pool2_data_2, pool2_data_3);
            end

            if (max_pool_data_2 !== exp_max) begin
                maxpool_err_2 = maxpool_err_2 + 1;
                $display("============================================================");
                $display("MAXPOOL2 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("INPUT4   = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("DUT MAX  = %0d", max_pool_data_2);
                $display("GOLDEN   = %0d", exp_max);
                $display("============================================================");
                $stop;
            end
            else begin
                maxpool_match_2 = maxpool_match_2 + 1;
                $display("MAXPOOL2 PASS idx=%0d -> %0d", idx, max_pool_data_2);
            end
        end
    endtask

    task automatic compare_pool_and_max_ch3(input integer idx);
        integer pr, pc;
        integer addr0, addr1, addr2, addr3;
        logic signed [31:0] exp0, exp1, exp2, exp3;
        logic signed [31:0] exp_max;
        begin
            pr = idx / POOL_W;
            pc = idx % POOL_W;

            addr0 = (pr * 2)     * OUT_W + (pc * 2);
            addr1 = addr0 + 1;
            addr2 = addr0 + OUT_W;
            addr3 = addr2 + 1;

            exp0 = conv_seen_mem_3[addr0];
            exp1 = conv_seen_mem_3[addr1];
            exp2 = conv_seen_mem_3[addr2];
            exp3 = conv_seen_mem_3[addr3];
            exp_max = max4(exp0, exp1, exp2, exp3);

            if ((pool3_data_0 !== exp0) ||
                (pool3_data_1 !== exp1) ||
                (pool3_data_2 !== exp2) ||
                (pool3_data_3 !== exp3)) begin
                pool_err_3 = pool_err_3 + 1;
                $display("============================================================");
                $display("POOL3 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("addr   = [%0d, %0d, %0d, %0d]", addr0, addr1, addr2, addr3);
                $display("DUT    = [%0d, %0d, %0d, %0d]",
                         pool3_data_0, pool3_data_1, pool3_data_2, pool3_data_3);
                $display("GOLDEN = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("============================================================");
                $stop;
            end
            else begin
                pool_match_3 = pool_match_3 + 1;
                $display("POOL3 PASS idx=%0d -> [%0d, %0d, %0d, %0d]",
                         idx, pool3_data_0, pool3_data_1, pool3_data_2, pool3_data_3);
            end

            if (max_pool_data_3 !== exp_max) begin
                maxpool_err_3 = maxpool_err_3 + 1;
                $display("============================================================");
                $display("MAXPOOL3 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("INPUT4   = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("DUT MAX  = %0d", max_pool_data_3);
                $display("GOLDEN   = %0d", exp_max);
                $display("============================================================");
                $stop;
            end
            else begin
                maxpool_match_3 = maxpool_match_3 + 1;
                $display("MAXPOOL3 PASS idx=%0d -> %0d", idx, max_pool_data_3);
            end
        end
    endtask

    // -----------------------------------------
    // conv2 pool + maxpool compare tasks
    // -----------------------------------------
    task automatic compare_conv2_pool_and_max_ch1(input integer idx);
        integer pr, pc;
        integer addr0, addr1, addr2, addr3;
        logic signed [31:0] exp0, exp1, exp2, exp3;
        logic signed [31:0] exp_max;
        begin
            pr = idx / CONV2_POOL_W;
            pc = idx % CONV2_POOL_W;

            addr0 = (pr * 2)     * CONV2_W + (pc * 2);
            addr1 = addr0 + 1;
            addr2 = addr0 + CONV2_W;
            addr3 = addr2 + 1;

            exp0 = conv2_seen_mem_1[addr0];
            exp1 = conv2_seen_mem_1[addr1];
            exp2 = conv2_seen_mem_1[addr2];
            exp3 = conv2_seen_mem_1[addr3];
            exp_max = max4(exp0, exp1, exp2, exp3);

            if ((conv2_pool1_data_0 !== exp0) ||
                (conv2_pool1_data_1 !== exp1) ||
                (conv2_pool1_data_2 !== exp2) ||
                (conv2_pool1_data_3 !== exp3)) begin
                conv2_pool_err_1 = conv2_pool_err_1 + 1;
                $display("============================================================");
                $display("CONV2 POOL1 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("addr   = [%0d, %0d, %0d, %0d]", addr0, addr1, addr2, addr3);
                $display("DUT    = [%0d, %0d, %0d, %0d]",
                         conv2_pool1_data_0, conv2_pool1_data_1, conv2_pool1_data_2, conv2_pool1_data_3);
                $display("GOLDEN = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("============================================================");
                $stop;
            end
            else begin
                conv2_pool_match_1 = conv2_pool_match_1 + 1;
                $display("CONV2 POOL1 PASS idx=%0d -> [%0d, %0d, %0d, %0d]",
                         idx, conv2_pool1_data_0, conv2_pool1_data_1, conv2_pool1_data_2, conv2_pool1_data_3);
            end

            if (conv2_max_pool_data_1 !== exp_max) begin
                conv2_maxpool_err_1 = conv2_maxpool_err_1 + 1;
                $display("============================================================");
                $display("CONV2 MAXPOOL1 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("INPUT4   = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("DUT MAX  = %0d", conv2_max_pool_data_1);
                $display("GOLDEN   = %0d", exp_max);
                $display("============================================================");
                $stop;
            end
            else begin
                conv2_maxpool_match_1 = conv2_maxpool_match_1 + 1;
                $display("CONV2 MAXPOOL1 PASS idx=%0d -> %0d", idx, conv2_max_pool_data_1);
            end
        end
    endtask

    task automatic compare_conv2_pool_and_max_ch2(input integer idx);
        integer pr, pc;
        integer addr0, addr1, addr2, addr3;
        logic signed [31:0] exp0, exp1, exp2, exp3;
        logic signed [31:0] exp_max;
        begin
            pr = idx / CONV2_POOL_W;
            pc = idx % CONV2_POOL_W;

            addr0 = (pr * 2)     * CONV2_W + (pc * 2);
            addr1 = addr0 + 1;
            addr2 = addr0 + CONV2_W;
            addr3 = addr2 + 1;

            exp0 = conv2_seen_mem_2[addr0];
            exp1 = conv2_seen_mem_2[addr1];
            exp2 = conv2_seen_mem_2[addr2];
            exp3 = conv2_seen_mem_2[addr3];
            exp_max = max4(exp0, exp1, exp2, exp3);

            if ((conv2_pool2_data_0 !== exp0) ||
                (conv2_pool2_data_1 !== exp1) ||
                (conv2_pool2_data_2 !== exp2) ||
                (conv2_pool2_data_3 !== exp3)) begin
                conv2_pool_err_2 = conv2_pool_err_2 + 1;
                $display("============================================================");
                $display("CONV2 POOL2 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("addr   = [%0d, %0d, %0d, %0d]", addr0, addr1, addr2, addr3);
                $display("DUT    = [%0d, %0d, %0d, %0d]",
                         conv2_pool2_data_0, conv2_pool2_data_1, conv2_pool2_data_2, conv2_pool2_data_3);
                $display("GOLDEN = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("============================================================");
                $stop;
            end
            else begin
                conv2_pool_match_2 = conv2_pool_match_2 + 1;
                $display("CONV2 POOL2 PASS idx=%0d -> [%0d, %0d, %0d, %0d]",
                         idx, conv2_pool2_data_0, conv2_pool2_data_1, conv2_pool2_data_2, conv2_pool2_data_3);
            end

            if (conv2_max_pool_data_2 !== exp_max) begin
                conv2_maxpool_err_2 = conv2_maxpool_err_2 + 1;
                $display("============================================================");
                $display("CONV2 MAXPOOL2 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("INPUT4   = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("DUT MAX  = %0d", conv2_max_pool_data_2);
                $display("GOLDEN   = %0d", exp_max);
                $display("============================================================");
                $stop;
            end
            else begin
                conv2_maxpool_match_2 = conv2_maxpool_match_2 + 1;
                $display("CONV2 MAXPOOL2 PASS idx=%0d -> %0d", idx, conv2_max_pool_data_2);
            end
        end
    endtask

    task automatic compare_conv2_pool_and_max_ch3(input integer idx);
        integer pr, pc;
        integer addr0, addr1, addr2, addr3;
        logic signed [31:0] exp0, exp1, exp2, exp3;
        logic signed [31:0] exp_max;
        begin
            pr = idx / CONV2_POOL_W;
            pc = idx % CONV2_POOL_W;

            addr0 = (pr * 2)     * CONV2_W + (pc * 2);
            addr1 = addr0 + 1;
            addr2 = addr0 + CONV2_W;
            addr3 = addr2 + 1;

            exp0 = conv2_seen_mem_3[addr0];
            exp1 = conv2_seen_mem_3[addr1];
            exp2 = conv2_seen_mem_3[addr2];
            exp3 = conv2_seen_mem_3[addr3];
            exp_max = max4(exp0, exp1, exp2, exp3);

            if ((conv2_pool3_data_0 !== exp0) ||
                (conv2_pool3_data_1 !== exp1) ||
                (conv2_pool3_data_2 !== exp2) ||
                (conv2_pool3_data_3 !== exp3)) begin
                conv2_pool_err_3 = conv2_pool_err_3 + 1;
                $display("============================================================");
                $display("CONV2 POOL3 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("addr   = [%0d, %0d, %0d, %0d]", addr0, addr1, addr2, addr3);
                $display("DUT    = [%0d, %0d, %0d, %0d]",
                         conv2_pool3_data_0, conv2_pool3_data_1, conv2_pool3_data_2, conv2_pool3_data_3);
                $display("GOLDEN = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("============================================================");
                $stop;
            end
            else begin
                conv2_pool_match_3 = conv2_pool_match_3 + 1;
                $display("CONV2 POOL3 PASS idx=%0d -> [%0d, %0d, %0d, %0d]",
                         idx, conv2_pool3_data_0, conv2_pool3_data_1, conv2_pool3_data_2, conv2_pool3_data_3);
            end

            if (conv2_max_pool_data_3 !== exp_max) begin
                conv2_maxpool_err_3 = conv2_maxpool_err_3 + 1;
                $display("============================================================");
                $display("CONV2 MAXPOOL3 ERROR idx=%0d pool(row=%0d,col=%0d)", idx, pr, pc);
                $display("INPUT4   = [%0d, %0d, %0d, %0d]", exp0, exp1, exp2, exp3);
                $display("DUT MAX  = %0d", conv2_max_pool_data_3);
                $display("GOLDEN   = %0d", exp_max);
                $display("============================================================");
                $stop;
            end
            else begin
                conv2_maxpool_match_3 = conv2_maxpool_match_3 + 1;
                $display("CONV2 MAXPOOL3 PASS idx=%0d -> %0d", idx, conv2_max_pool_data_3);
            end
        end
    endtask

    // -----------------------------------------
    // Reset / counters init
    // -----------------------------------------
    initial begin
        rst_n           = 0;
        conv_idx        = 0;
        conv_row        = 0;
        conv_col        = 0;
        conv_pass       = 0;

        golden1         = 0;
        golden2         = 0;
        golden3         = 0;

        pool_idx_1      = 0;
        pool_idx_2      = 0;
        pool_idx_3      = 0;

        pool_match_1    = 0;
        pool_match_2    = 0;
        pool_match_3    = 0;

        pool_err_1      = 0;
        pool_err_2      = 0;
        pool_err_3      = 0;

        maxpool_match_1 = 0;
        maxpool_match_2 = 0;
        maxpool_match_3 = 0;

        maxpool_err_1   = 0;
        maxpool_err_2   = 0;
        maxpool_err_3   = 0;

        conv2_idx_1     = 0;
        conv2_idx_2     = 0;
        conv2_idx_3     = 0;

        conv2_match_1   = 0;
        conv2_match_2   = 0;
        conv2_match_3   = 0;

        conv2_err_1     = 0;
        conv2_err_2     = 0;
        conv2_err_3     = 0;

        conv2_pool_idx_1      = 0;
        conv2_pool_idx_2      = 0;
        conv2_pool_idx_3      = 0;

        conv2_pool_match_1    = 0;
        conv2_pool_match_2    = 0;
        conv2_pool_match_3    = 0;

        conv2_pool_err_1      = 0;
        conv2_pool_err_2      = 0;
        conv2_pool_err_3      = 0;

        conv2_maxpool_match_1 = 0;
        conv2_maxpool_match_2 = 0;
        conv2_maxpool_match_3 = 0;

        conv2_maxpool_err_1   = 0;
        conv2_maxpool_err_2   = 0;
        conv2_maxpool_err_3   = 0;

        fc_input_match_cnt       = 0;
        fc_input_err_cnt         = 0;
        fc_match_cnt             = 0;
        fc_err_cnt               = 0;
        final_decision_match_cnt = 0;
        final_decision_err_cnt   = 0;

        conv2_row       = 0;
        conv2_col       = 0;
        conv2_golden    = 0;

        for (gi = 0; gi < FC_IN_NUM; gi = gi + 1)
            fc_seen_data[gi] = 0;
        for (gi = 0; gi < FC_OUT_NUM; gi = gi + 1)
            fc_golden_data[gi] = 0;

        golden_selected_index = 0;
        golden_fc_max = 0;

        #20;
        rst_n = 1;
    end

    // -----------------------------------------
    // Timeout
    // -----------------------------------------
    initial begin
        repeat (300000) @(posedge clk);
        $display("===== TIMEOUT =====");
        $display("conv         pass = %0d / %0d", conv_pass, TOTAL_WINDOWS);
        $display("pool ch1     pass = %0d / %0d", pool_match_1, POOL_NUM);
        $display("pool ch2     pass = %0d / %0d", pool_match_2, POOL_NUM);
        $display("pool ch3     pass = %0d / %0d", pool_match_3, POOL_NUM);
        $display("max  ch1     pass = %0d / %0d", maxpool_match_1, POOL_NUM);
        $display("max  ch2     pass = %0d / %0d", maxpool_match_2, POOL_NUM);
        $display("max  ch3     pass = %0d / %0d", maxpool_match_3, POOL_NUM);
        $display("conv2 ch1    pass = %0d / %0d", conv2_match_1, CONV2_NUM);
        $display("conv2 ch2    pass = %0d / %0d", conv2_match_2, CONV2_NUM);
        $display("conv2 ch3    pass = %0d / %0d", conv2_match_3, CONV2_NUM);
        $display("conv2 pool1  pass = %0d / %0d", conv2_pool_match_1, CONV2_POOL_NUM);
        $display("conv2 pool2  pass = %0d / %0d", conv2_pool_match_2, CONV2_POOL_NUM);
        $display("conv2 pool3  pass = %0d / %0d", conv2_pool_match_3, CONV2_POOL_NUM);
        $display("conv2 max1   pass = %0d / %0d", conv2_maxpool_match_1, CONV2_POOL_NUM);
        $display("conv2 max2   pass = %0d / %0d", conv2_maxpool_match_2, CONV2_POOL_NUM);
        $display("conv2 max3   pass = %0d / %0d", conv2_maxpool_match_3, CONV2_POOL_NUM);
        $display("fc input chk pass = %0d", fc_input_match_cnt);
        $display("fc mac chk   pass = %0d", fc_match_cnt);
        $display("final dec chk pass = %0d", final_decision_match_cnt);
        $finish;
    end

    // -----------------------------------------
    // Main checker
    // -----------------------------------------
    always @(posedge clk) begin
        #1;

        if (!rst_n) begin
            conv_idx        = 0;
            conv_row        = 0;
            conv_col        = 0;
            conv_pass       = 0;

            pool_idx_1      = 0;
            pool_idx_2      = 0;
            pool_idx_3      = 0;

            pool_match_1    = 0;
            pool_match_2    = 0;
            pool_match_3    = 0;

            pool_err_1      = 0;
            pool_err_2      = 0;
            pool_err_3      = 0;

            maxpool_match_1 = 0;
            maxpool_match_2 = 0;
            maxpool_match_3 = 0;

            maxpool_err_1   = 0;
            maxpool_err_2   = 0;
            maxpool_err_3   = 0;

            conv2_idx_1     = 0;
            conv2_idx_2     = 0;
            conv2_idx_3     = 0;

            conv2_match_1   = 0;
            conv2_match_2   = 0;
            conv2_match_3   = 0;

            conv2_err_1     = 0;
            conv2_err_2     = 0;
            conv2_err_3     = 0;

            conv2_pool_idx_1      = 0;
            conv2_pool_idx_2      = 0;
            conv2_pool_idx_3      = 0;

            conv2_pool_match_1    = 0;
            conv2_pool_match_2    = 0;
            conv2_pool_match_3    = 0;

            conv2_pool_err_1      = 0;
            conv2_pool_err_2      = 0;
            conv2_pool_err_3      = 0;

            conv2_maxpool_match_1 = 0;
            conv2_maxpool_match_2 = 0;
            conv2_maxpool_match_3 = 0;

            conv2_maxpool_err_1   = 0;
            conv2_maxpool_err_2   = 0;
            conv2_maxpool_err_3   = 0;

            fc_input_match_cnt       = 0;
            fc_input_err_cnt         = 0;
            fc_match_cnt             = 0;
            fc_err_cnt               = 0;
            final_decision_match_cnt = 0;
            final_decision_err_cnt   = 0;
        end
        else begin
            // ------------------------------------------------
            // conv1 check
            // ------------------------------------------------
            if (dut.valid_1 && dut.valid_2 && dut.valid_3) begin
                if (conv_idx < TOTAL_WINDOWS) begin
                    conv_row = conv_idx / OUT_W;
                    conv_col = conv_idx % OUT_W;

                    if (conv_col == 0)
                        $display("===== START ROW %0d =====", conv_row);

                    golden1 = calc_golden(conv_row, conv_col, 0);
                    golden2 = calc_golden(conv_row, conv_col, 1);
                    golden3 = calc_golden(conv_row, conv_col, 2);

                    if (dut.conv_result_1 !== golden1 ||
                        dut.conv_result_2 !== golden2 ||
                        dut.conv_result_3 !== golden3) begin
                        $display("ERROR at row=%0d col=%0d", conv_row, conv_col);
                        $display("CH1 exp=%0d got=%0d", golden1, dut.conv_result_1);
                        $display("CH2 exp=%0d got=%0d", golden2, dut.conv_result_2);
                        $display("CH3 exp=%0d got=%0d", golden3, dut.conv_result_3);
                        $stop;
                    end
                    else begin
                        $display("PASS row=%0d col=%0d | CH1=%0d CH2=%0d CH3=%0d",
                                 conv_row, conv_col,
                                 dut.conv_result_1,
                                 dut.conv_result_2,
                                 dut.conv_result_3);
                    end

                    conv_seen_mem_1[conv_idx] = dut.conv_result_1;
                    conv_seen_mem_2[conv_idx] = dut.conv_result_2;
                    conv_seen_mem_3[conv_idx] = dut.conv_result_3;

                    conv_idx  = conv_idx + 1;
                    conv_pass = conv_pass + 1;
                end
                else begin
                    $display("TB ERROR: extra conv output, conv_idx=%0d", conv_idx);
                    $stop;
                end
            end

            // ------------------------------------------------
            // pool + maxpool ch1
            // ------------------------------------------------
            if (dut.pool_en_1) begin
                if (pool_idx_1 < POOL_NUM) begin
                    if (conv_idx <= (((pool_idx_1 / POOL_W) * 2 + 1) * OUT_W +
                                     ((pool_idx_1 % POOL_W) * 2 + 1))) begin
                        $display("============================================================");
                        $display("TB ERROR: pool1 came too early");
                        $display("pool idx=%0d pool(row=%0d,col=%0d)",
                                 pool_idx_1, pool_idx_1 / POOL_W, pool_idx_1 % POOL_W);
                        $display("conv_idx=%0d", conv_idx);
                        $display("DUT pool1 = [%0d, %0d, %0d, %0d]",
                                 pool1_data_0, pool1_data_1, pool1_data_2, pool1_data_3);
                        $display("============================================================");
                        $stop;
                    end

                    compare_pool_and_max_ch1(pool_idx_1);
                    maxpool_seen_mem_1[pool_idx_1] = max_pool_data_1;
                    pool_idx_1 = pool_idx_1 + 1;
                end
                else begin
                    $display("POOL1 ERROR: extra pool_en_1, pool_idx_1=%0d", pool_idx_1);
                    $stop;
                end
            end

            // ------------------------------------------------
            // pool + maxpool ch2
            // ------------------------------------------------
            if (dut.pool_en_2) begin
                if (pool_idx_2 < POOL_NUM) begin
                    if (conv_idx <= (((pool_idx_2 / POOL_W) * 2 + 1) * OUT_W +
                                     ((pool_idx_2 % POOL_W) * 2 + 1))) begin
                        $display("============================================================");
                        $display("TB ERROR: pool2 came too early");
                        $display("pool idx=%0d pool(row=%0d,col=%0d)",
                                 pool_idx_2, pool_idx_2 / POOL_W, pool_idx_2 % POOL_W);
                        $display("conv_idx=%0d", conv_idx);
                        $display("DUT pool2 = [%0d, %0d, %0d, %0d]",
                                 pool2_data_0, pool2_data_1, pool2_data_2, pool2_data_3);
                        $display("============================================================");
                        $stop;
                    end

                    compare_pool_and_max_ch2(pool_idx_2);
                    maxpool_seen_mem_2[pool_idx_2] = max_pool_data_2;
                    pool_idx_2 = pool_idx_2 + 1;
                end
                else begin
                    $display("POOL2 ERROR: extra pool_en_2, pool_idx_2=%0d", pool_idx_2);
                    $stop;
                end
            end

            // ------------------------------------------------
            // pool + maxpool ch3
            // ------------------------------------------------
            if (dut.pool_en_3) begin
                if (pool_idx_3 < POOL_NUM) begin
                    if (conv_idx <= (((pool_idx_3 / POOL_W) * 2 + 1) * OUT_W +
                                     ((pool_idx_3 % POOL_W) * 2 + 1))) begin
                        $display("============================================================");
                        $display("TB ERROR: pool3 came too early");
                        $display("pool idx=%0d pool(row=%0d,col=%0d)",
                                 pool_idx_3, pool_idx_3 / POOL_W, pool_idx_3 % POOL_W);
                        $display("conv_idx=%0d", conv_idx);
                        $display("DUT pool3 = [%0d, %0d, %0d, %0d]",
                                 pool3_data_0, pool3_data_1, pool3_data_2, pool3_data_3);
                        $display("============================================================");
                        $stop;
                    end

                    compare_pool_and_max_ch3(pool_idx_3);
                    maxpool_seen_mem_3[pool_idx_3] = max_pool_data_3;
                    pool_idx_3 = pool_idx_3 + 1;
                end
                else begin
                    $display("POOL3 ERROR: extra pool_en_3, pool_idx_3=%0d", pool_idx_3);
                    $stop;
                end
            end

            // ------------------------------------------------
            // conv2 check ch1
            // ------------------------------------------------
            if (dut.conv2_valid_1) begin
                if (conv2_idx_1 < CONV2_NUM) begin
                    conv2_row = conv2_idx_1 / CONV2_W;
                    conv2_col = conv2_idx_1 % CONV2_W;

                    if (pool_idx_1 <= ((conv2_row + 4) * POOL_W + (conv2_col + 4))) begin
                        $display("============================================================");
                        $display("TB ERROR: conv2 ch1 came too early");
                        $display("conv2 idx=%0d row=%0d col=%0d", conv2_idx_1, conv2_row, conv2_col);
                        $display("pool_idx_1=%0d", pool_idx_1);
                        $display("============================================================");
                        $stop;
                    end

                    conv2_golden = calc_golden_conv2(conv2_row, conv2_col, 0);

                    if (dut.conv2_result_1 !== conv2_golden) begin
                        conv2_err_1 = conv2_err_1 + 1;
                        $display("============================================================");
                        $display("CONV2 CH1 ERROR row=%0d col=%0d idx=%0d", conv2_row, conv2_col, conv2_idx_1);
                        $display("DUT    = %0d", dut.conv2_result_1);
                        $display("GOLDEN = %0d", conv2_golden);
                        $display("============================================================");
                        $stop;
                    end
                    else begin
                        conv2_match_1 = conv2_match_1 + 1;
                        $display("CONV2 CH1 PASS row=%0d col=%0d -> %0d",
                                 conv2_row, conv2_col, dut.conv2_result_1);
                    end

                    conv2_seen_mem_1[conv2_idx_1] = dut.conv2_result_1;
                    conv2_idx_1 = conv2_idx_1 + 1;
                end
                else begin
                    $display("CONV2 CH1 ERROR: extra output, conv2_idx_1=%0d", conv2_idx_1);
                    $stop;
                end
            end

            // ------------------------------------------------
            // conv2 check ch2
            // ------------------------------------------------
            if (dut.conv2_valid_2) begin
                if (conv2_idx_2 < CONV2_NUM) begin
                    conv2_row = conv2_idx_2 / CONV2_W;
                    conv2_col = conv2_idx_2 % CONV2_W;

                    if (pool_idx_2 <= ((conv2_row + 4) * POOL_W + (conv2_col + 4))) begin
                        $display("============================================================");
                        $display("TB ERROR: conv2 ch2 came too early");
                        $display("conv2 idx=%0d row=%0d col=%0d", conv2_idx_2, conv2_row, conv2_col);
                        $display("pool_idx_2=%0d", pool_idx_2);
                        $display("============================================================");
                        $stop;
                    end

                    conv2_golden = calc_golden_conv2(conv2_row, conv2_col, 1);

                    if (dut.conv2_result_2 !== conv2_golden) begin
                        conv2_err_2 = conv2_err_2 + 1;
                        $display("============================================================");
                        $display("CONV2 CH2 ERROR row=%0d col=%0d idx=%0d", conv2_row, conv2_col, conv2_idx_2);
                        $display("DUT    = %0d", dut.conv2_result_2);
                        $display("GOLDEN = %0d", conv2_golden);
                        $display("============================================================");
                        $stop;
                    end
                    else begin
                        conv2_match_2 = conv2_match_2 + 1;
                        $display("CONV2 CH2 PASS row=%0d col=%0d -> %0d",
                                 conv2_row, conv2_col, dut.conv2_result_2);
                    end

                    conv2_seen_mem_2[conv2_idx_2] = dut.conv2_result_2;
                    conv2_idx_2 = conv2_idx_2 + 1;
                end
                else begin
                    $display("CONV2 CH2 ERROR: extra output, conv2_idx_2=%0d", conv2_idx_2);
                    $stop;
                end
            end

            // ------------------------------------------------
            // conv2 check ch3
            // ------------------------------------------------
            if (dut.conv2_valid_3) begin
                if (conv2_idx_3 < CONV2_NUM) begin
                    conv2_row = conv2_idx_3 / CONV2_W;
                    conv2_col = conv2_idx_3 % CONV2_W;

                    if (pool_idx_3 <= ((conv2_row + 4) * POOL_W + (conv2_col + 4))) begin
                        $display("============================================================");
                        $display("TB ERROR: conv2 ch3 came too early");
                        $display("conv2 idx=%0d row=%0d col=%0d", conv2_idx_3, conv2_row, conv2_col);
                        $display("pool_idx_3=%0d", pool_idx_3);
                        $display("============================================================");
                        $stop;
                    end

                    conv2_golden = calc_golden_conv2(conv2_row, conv2_col, 2);

                    if (dut.conv2_result_3 !== conv2_golden) begin
                        conv2_err_3 = conv2_err_3 + 1;
                        $display("============================================================");
                        $display("CONV2 CH3 ERROR row=%0d col=%0d idx=%0d", conv2_row, conv2_col, conv2_idx_3);
                        $display("DUT    = %0d", dut.conv2_result_3);
                        $display("GOLDEN = %0d", conv2_golden);
                        $display("============================================================");
                        $stop;
                    end
                    else begin
                        conv2_match_3 = conv2_match_3 + 1;
                        $display("CONV2 CH3 PASS row=%0d col=%0d -> %0d",
                                 conv2_row, conv2_col, dut.conv2_result_3);
                    end

                    conv2_seen_mem_3[conv2_idx_3] = dut.conv2_result_3;
                    conv2_idx_3 = conv2_idx_3 + 1;
                end
                else begin
                    $display("CONV2 CH3 ERROR: extra output, conv2_idx_3=%0d", conv2_idx_3);
                    $stop;
                end
            end

            // ------------------------------------------------
            // conv2 pool + maxpool ch1
            // ------------------------------------------------
            if (dut.conv2_pool_en_1) begin
                if (conv2_pool_idx_1 < CONV2_POOL_NUM) begin
                    if (conv2_idx_1 <= (((conv2_pool_idx_1 / CONV2_POOL_W) * 2 + 1) * CONV2_W +
                                        ((conv2_pool_idx_1 % CONV2_POOL_W) * 2 + 1))) begin
                        $display("============================================================");
                        $display("TB ERROR: conv2 pool1 came too early");
                        $display("conv2 pool idx=%0d pool(row=%0d,col=%0d)",
                                 conv2_pool_idx_1, conv2_pool_idx_1 / CONV2_POOL_W, conv2_pool_idx_1 % CONV2_POOL_W);
                        $display("conv2_idx_1=%0d", conv2_idx_1);
                        $display("============================================================");
                        $stop;
                    end

                    compare_conv2_pool_and_max_ch1(conv2_pool_idx_1);
                    fc_seen_data[conv2_pool_idx_1] = conv2_max_pool_data_1;
                    conv2_pool_idx_1 = conv2_pool_idx_1 + 1;
                end
                else begin
                    $display("CONV2 POOL1 ERROR: extra conv2_pool_en_1, idx=%0d", conv2_pool_idx_1);
                    $stop;
                end
            end

            // ------------------------------------------------
            // conv2 pool + maxpool ch2
            // ------------------------------------------------
            if (dut.conv2_pool_en_2) begin
                if (conv2_pool_idx_2 < CONV2_POOL_NUM) begin
                    if (conv2_idx_2 <= (((conv2_pool_idx_2 / CONV2_POOL_W) * 2 + 1) * CONV2_W +
                                        ((conv2_pool_idx_2 % CONV2_POOL_W) * 2 + 1))) begin
                        $display("============================================================");
                        $display("TB ERROR: conv2 pool2 came too early");
                        $display("conv2 pool idx=%0d pool(row=%0d,col=%0d)",
                                 conv2_pool_idx_2, conv2_pool_idx_2 / CONV2_POOL_W, conv2_pool_idx_2 % CONV2_POOL_W);
                        $display("conv2_idx_2=%0d", conv2_idx_2);
                        $display("============================================================");
                        $stop;
                    end

                    compare_conv2_pool_and_max_ch2(conv2_pool_idx_2);
                    fc_seen_data[conv2_pool_idx_2 + 16] = conv2_max_pool_data_2;
                    conv2_pool_idx_2 = conv2_pool_idx_2 + 1;
                end
                else begin
                    $display("CONV2 POOL2 ERROR: extra conv2_pool_en_2, idx=%0d", conv2_pool_idx_2);
                    $stop;
                end
            end

            // ------------------------------------------------
            // conv2 pool + maxpool ch3
            // ------------------------------------------------
            if (dut.conv2_pool_en_3) begin
                if (conv2_pool_idx_3 < CONV2_POOL_NUM) begin
                    if (conv2_idx_3 <= (((conv2_pool_idx_3 / CONV2_POOL_W) * 2 + 1) * CONV2_W +
                                        ((conv2_pool_idx_3 % CONV2_POOL_W) * 2 + 1))) begin
                        $display("============================================================");
                        $display("TB ERROR: conv2 pool3 came too early");
                        $display("conv2 pool idx=%0d pool(row=%0d,col=%0d)",
                                 conv2_pool_idx_3, conv2_pool_idx_3 / CONV2_POOL_W, conv2_pool_idx_3 % CONV2_POOL_W);
                        $display("conv2_idx_3=%0d", conv2_idx_3);
                        $display("============================================================");
                        $stop;
                    end

                    compare_conv2_pool_and_max_ch3(conv2_pool_idx_3);
                    fc_seen_data[conv2_pool_idx_3 + 32] = conv2_max_pool_data_3;
                    conv2_pool_idx_3 = conv2_pool_idx_3 + 1;
                end
                else begin
                    $display("CONV2 POOL3 ERROR: extra conv2_pool_en_3, idx=%0d", conv2_pool_idx_3);
                    $stop;
                end
            end

            // ------------------------------------------------
            // FC input / fc_mac check
            // ------------------------------------------------
            if (dut.u_fc.mac_data_valid_all) begin
                // 1) fc_data content check
                for (fc_i = 0; fc_i < FC_IN_NUM; fc_i = fc_i + 1) begin
                    if ($signed(dut.u_fc.fc_data[fc_i]) !== fc_seen_data[fc_i]) begin
                        fc_input_err_cnt = fc_input_err_cnt + 1;
                        $display("============================================================");
                        $display("FC INPUT ERROR idx=%0d", fc_i);
                        $display("DUT    fc_data[%0d] = %0d", fc_i, $signed(dut.u_fc.fc_data[fc_i]));
                        $display("GOLDEN fc_data[%0d] = %0d", fc_i, fc_seen_data[fc_i]);
                        $display("============================================================");
                        $stop;
                    end
                end
                fc_input_match_cnt = fc_input_match_cnt + 1;

                // 2) 10-class golden logits
                for (fc_cls = 0; fc_cls < FC_OUT_NUM; fc_cls = fc_cls + 1) begin
                    fc_sum = golden_fc_bias[fc_cls];
                    for (fc_i = 0; fc_i < FC_IN_NUM; fc_i = fc_i + 1) begin
                        fc_sum = fc_sum + (fc_seen_data[fc_i] * golden_fc_weight[fc_cls][fc_i]);
                    end
                    fc_golden_data[fc_cls] = fc_sum[31:0];
                end

                // 3) compare fc_mac outputs only
                if (($signed(dut.u_fc.mac_data_0) !== fc_golden_data[0]) ||
                    ($signed(dut.u_fc.mac_data_1) !== fc_golden_data[1]) ||
                    ($signed(dut.u_fc.mac_data_2) !== fc_golden_data[2]) ||
                    ($signed(dut.u_fc.mac_data_3) !== fc_golden_data[3]) ||
                    ($signed(dut.u_fc.mac_data_4) !== fc_golden_data[4]) ||
                    ($signed(dut.u_fc.mac_data_5) !== fc_golden_data[5]) ||
                    ($signed(dut.u_fc.mac_data_6) !== fc_golden_data[6]) ||
                    ($signed(dut.u_fc.mac_data_7) !== fc_golden_data[7]) ||
                    ($signed(dut.u_fc.mac_data_8) !== fc_golden_data[8]) ||
                    ($signed(dut.u_fc.mac_data_9) !== fc_golden_data[9])) begin
                    fc_err_cnt = fc_err_cnt + 1;
                    $display("============================================================");
                    $display("FC_MAC ERROR");
                    $display("DUT    = [%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d]",
                             $signed(dut.u_fc.mac_data_0), $signed(dut.u_fc.mac_data_1),
                             $signed(dut.u_fc.mac_data_2), $signed(dut.u_fc.mac_data_3),
                             $signed(dut.u_fc.mac_data_4), $signed(dut.u_fc.mac_data_5),
                             $signed(dut.u_fc.mac_data_6), $signed(dut.u_fc.mac_data_7),
                             $signed(dut.u_fc.mac_data_8), $signed(dut.u_fc.mac_data_9));
                    $display("GOLDEN = [%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d]",
                             fc_golden_data[0], fc_golden_data[1], fc_golden_data[2], fc_golden_data[3], fc_golden_data[4],
                             fc_golden_data[5], fc_golden_data[6], fc_golden_data[7], fc_golden_data[8], fc_golden_data[9]);
                    $display("============================================================");
                    $stop;
                end
                else begin
                    fc_match_cnt = fc_match_cnt + 1;
                    $display("FC_MAC PASS");
                    $display("LOGITS = [%0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d, %0d]",
                             $signed(dut.u_fc.mac_data_0), $signed(dut.u_fc.mac_data_1),
                             $signed(dut.u_fc.mac_data_2), $signed(dut.u_fc.mac_data_3),
                             $signed(dut.u_fc.mac_data_4), $signed(dut.u_fc.mac_data_5),
                             $signed(dut.u_fc.mac_data_6), $signed(dut.u_fc.mac_data_7),
                             $signed(dut.u_fc.mac_data_8), $signed(dut.u_fc.mac_data_9));
                end

                // 4) compute golden argmax, but do NOT check comparator here
                golden_selected_index = 0;
                golden_fc_max = fc_golden_data[0];
                for (fc_i = 1; fc_i < FC_OUT_NUM; fc_i = fc_i + 1) begin
                    if (fc_golden_data[fc_i] > golden_fc_max) begin
                        golden_fc_max = fc_golden_data[fc_i];
                        golden_selected_index = fc_i[3:0];
                    end
                end
            end

            // ------------------------------------------------
            // Final decision check: only when top-level decision_valid
            // ------------------------------------------------
            if (decision_valid) begin
                if ((dut.u_fc.selected_index !== golden_selected_index) ||
                    (decision !== golden_selected_index)) begin
                    final_decision_err_cnt = final_decision_err_cnt + 1;
                    $display("============================================================");
                    $display("FINAL DECISION ERROR");
                    $display("DUT decision          = %0d", decision);
                    $display("internal selected_idx = %0d", dut.u_fc.selected_index);
                    $display("golden  selected_idx  = %0d", golden_selected_index);
                    $display("============================================================");
                    $stop;
                end
                else begin
                    final_decision_match_cnt = final_decision_match_cnt + 1;
                    $display("============================================================");
                    $display("FINAL DECISION VALID");
                    $display("DUT decision         = %0d", decision);
                    $display("internal class index = %0d", dut.u_fc.selected_index);
                    $display("golden class index   = %0d", golden_selected_index);
                    $display("============================================================");
                end
            end

            // ------------------------------------------------
            // Final success condition
            // ------------------------------------------------
            if ((conv_idx == TOTAL_WINDOWS) &&
                (pool_idx_1 == POOL_NUM) &&
                (pool_idx_2 == POOL_NUM) &&
                (pool_idx_3 == POOL_NUM) &&
                (maxpool_match_1 == POOL_NUM) &&
                (maxpool_match_2 == POOL_NUM) &&
                (maxpool_match_3 == POOL_NUM) &&
                (conv2_idx_1 == CONV2_NUM) &&
                (conv2_idx_2 == CONV2_NUM) &&
                (conv2_idx_3 == CONV2_NUM) &&
                (conv2_pool_idx_1 == CONV2_POOL_NUM) &&
                (conv2_pool_idx_2 == CONV2_POOL_NUM) &&
                (conv2_pool_idx_3 == CONV2_POOL_NUM) &&
                (conv2_maxpool_match_1 == CONV2_POOL_NUM) &&
                (conv2_maxpool_match_2 == CONV2_POOL_NUM) &&
                (conv2_maxpool_match_3 == CONV2_POOL_NUM) &&
                (fc_match_cnt > 0) &&
                (final_decision_match_cnt > 0)) begin
                $display("============================================================");
                $display("===== ALL SUCCESS =====");
                $display("conv         pass = %0d / %0d", conv_pass, TOTAL_WINDOWS);
                $display("pool ch1     pass = %0d / %0d", pool_match_1, POOL_NUM);
                $display("pool ch2     pass = %0d / %0d", pool_match_2, POOL_NUM);
                $display("pool ch3     pass = %0d / %0d", pool_match_3, POOL_NUM);
                $display("max  ch1     pass = %0d / %0d", maxpool_match_1, POOL_NUM);
                $display("max  ch2     pass = %0d / %0d", maxpool_match_2, POOL_NUM);
                $display("max  ch3     pass = %0d / %0d", maxpool_match_3, POOL_NUM);
                $display("conv2 ch1    pass = %0d / %0d", conv2_match_1, CONV2_NUM);
                $display("conv2 ch2    pass = %0d / %0d", conv2_match_2, CONV2_NUM);
                $display("conv2 ch3    pass = %0d / %0d", conv2_match_3, CONV2_NUM);
                $display("conv2 pool1  pass = %0d / %0d", conv2_pool_match_1, CONV2_POOL_NUM);
                $display("conv2 pool2  pass = %0d / %0d", conv2_pool_match_2, CONV2_POOL_NUM);
                $display("conv2 pool3  pass = %0d / %0d", conv2_pool_match_3, CONV2_POOL_NUM);
                $display("conv2 max1   pass = %0d / %0d", conv2_maxpool_match_1, CONV2_POOL_NUM);
                $display("conv2 max2   pass = %0d / %0d", conv2_maxpool_match_2, CONV2_POOL_NUM);
                $display("conv2 max3   pass = %0d / %0d", conv2_maxpool_match_3, CONV2_POOL_NUM);
                $display("fc input chk pass = %0d", fc_input_match_cnt);
                $display("fc mac chk   pass = %0d", fc_match_cnt);
                $display("final dec chk pass = %0d", final_decision_match_cnt);
                $display("final class index   = %0d", dut.u_fc.selected_index);
                $display("top decision        = %0d", decision);
                $display("============================================================");
                $finish;
            end
        end
    end

endmodule