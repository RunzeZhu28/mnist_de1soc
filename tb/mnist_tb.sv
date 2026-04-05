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

    logic clk;
    logic rst_n;
    logic decision;

    mnist dut(
        .clk     (clk),
        .rst_n   (rst_n),
        .decision(decision)
    );

    logic signed [7:0] golden_weight_1 [0:24];
    logic signed [7:0] golden_weight_2 [0:24];
    logic signed [7:0] golden_weight_3 [0:24];
    logic signed [7:0] golden_bias     [0:2];
    logic        [7:0] golden_data     [0:783];

    logic signed [31:0] conv_seen_mem_1 [0:TOTAL_WINDOWS-1];
    logic signed [31:0] conv_seen_mem_2 [0:TOTAL_WINDOWS-1];
    logic signed [31:0] conv_seen_mem_3 [0:TOTAL_WINDOWS-1];

    integer conv_idx;
    integer conv_row;
    integer conv_col;
    integer conv_pass;

    integer golden1, golden2, golden3;

    integer pool_idx_1, pool_idx_2, pool_idx_3;
    integer pool_match_1, pool_match_2, pool_match_3;
    integer pool_err_1,   pool_err_2,   pool_err_3;

    integer maxpool_match_1, maxpool_match_2, maxpool_match_3;
    integer maxpool_err_1,   maxpool_err_2,   maxpool_err_3;

    logic signed [31:0] pool1_data_0, pool1_data_1, pool1_data_2, pool1_data_3;
    logic signed [31:0] pool2_data_0, pool2_data_1, pool2_data_2, pool2_data_3;
    logic signed [31:0] pool3_data_0, pool3_data_1, pool3_data_2, pool3_data_3;

    logic signed [31:0] max_pool_data_1, max_pool_data_2, max_pool_data_3;

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

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $readmemh("E:\\mnist\\weight\\conv1_weight_1.txt", golden_weight_1);
        $readmemh("E:\\mnist\\weight\\conv1_weight_2.txt", golden_weight_2);
        $readmemh("E:\\mnist\\weight\\conv1_weight_3.txt", golden_weight_3);
        $readmemh("E:\\mnist\\weight\\conv1_bias.txt",     golden_bias);
        $readmemh("E:\\mnist\\mnist_data.txt",             golden_data);
    end

    function automatic integer calc_golden(input integer row, input integer col, input integer ch);
        integer sum;
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
            calc_golden = sum;
        end
    endfunction

    function automatic integer max4(
        input integer a,
        input integer b,
        input integer c,
        input integer d
    );
        integer m01, m23;
        begin
            m01  = (a > b) ? a : b;
            m23  = (c > d) ? c : d;
            max4 = (m01 > m23) ? m01 : m23;
        end
    endfunction

    task automatic compare_pool_and_max_ch1(input integer idx);
        integer pr, pc;
        integer addr0, addr1, addr2, addr3;
        integer exp0, exp1, exp2, exp3;
        integer exp_max;
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
        integer exp0, exp1, exp2, exp3;
        integer exp_max;
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
        integer exp0, exp1, exp2, exp3;
        integer exp_max;
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

        #20;
        rst_n = 1;
    end

    initial begin
        repeat (80000) @(posedge clk);
        $display("===== TIMEOUT =====");
        $display("conv      pass = %0d / %0d", conv_pass, TOTAL_WINDOWS);
        $display("pool ch1  pass = %0d / %0d", pool_match_1, POOL_NUM);
        $display("pool ch2  pass = %0d / %0d", pool_match_2, POOL_NUM);
        $display("pool ch3  pass = %0d / %0d", pool_match_3, POOL_NUM);
        $display("max  ch1  pass = %0d / %0d", maxpool_match_1, POOL_NUM);
        $display("max  ch2  pass = %0d / %0d", maxpool_match_2, POOL_NUM);
        $display("max  ch3  pass = %0d / %0d", maxpool_match_3, POOL_NUM);
        $finish;
    end

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
        end
        else begin
            // conv check
            if (dut.valid_1 && dut.valid_2 && dut.valid_3) begin
                if (conv_idx < TOTAL_WINDOWS) begin
                    conv_row = conv_idx / OUT_W;
                    conv_col = conv_idx % OUT_W;

                    if (conv_col == 0)
                        $display("===== START ROW %0d =====", conv_row);

                    golden1 = calc_golden(conv_row, conv_col, 0);
                    golden2 = calc_golden(conv_row, conv_col, 1);
                    golden3 = calc_golden(conv_row, conv_col, 2);

                    if (dut.cov_result_1 !== golden1 ||
                        dut.cov_result_2 !== golden2 ||
                        dut.cov_result_3 !== golden3) begin
                        $display("ERROR at row=%0d col=%0d", conv_row, conv_col);
                        $display("CH1 exp=%0d got=%0d", golden1, dut.cov_result_1);
                        $display("CH2 exp=%0d got=%0d", golden2, dut.cov_result_2);
                        $display("CH3 exp=%0d got=%0d", golden3, dut.cov_result_3);
                        $stop;
                    end
                    else begin
                        $display("PASS row=%0d col=%0d | CH1=%0d CH2=%0d CH3=%0d",
                                 conv_row, conv_col,
                                 dut.cov_result_1,
                                 dut.cov_result_2,
                                 dut.cov_result_3);
                    end

                    conv_seen_mem_1[conv_idx] = dut.cov_result_1;
                    conv_seen_mem_2[conv_idx] = dut.cov_result_2;
                    conv_seen_mem_3[conv_idx] = dut.cov_result_3;

                    conv_idx  = conv_idx + 1;
                    conv_pass = conv_pass + 1;
                end
                else begin
                    $display("TB ERROR: extra conv output, conv_idx=%0d", conv_idx);
                    $stop;
                end
            end

            // pool + maxpool ch1
            if (dut.pool_en_1) begin
                if (pool_idx_1 < POOL_NUM) begin
                    if (conv_idx <= (((pool_idx_1 / POOL_W) * 2 + 1) * OUT_W + ((pool_idx_1 % POOL_W) * 2 + 1))) begin
                        $display("============================================================");
                        $display("TB ERROR: pool1 came too early");
                        $display("pool idx=%0d pool(row=%0d,col=%0d)", pool_idx_1, pool_idx_1 / POOL_W, pool_idx_1 % POOL_W);
                        $display("conv_idx=%0d", conv_idx);
                        $display("DUT pool1 = [%0d, %0d, %0d, %0d]",
                                 pool1_data_0, pool1_data_1, pool1_data_2, pool1_data_3);
                        $display("============================================================");
                        $stop;
                    end

                    compare_pool_and_max_ch1(pool_idx_1);
                    pool_idx_1 = pool_idx_1 + 1;
                end
                else begin
                    $display("POOL1 ERROR: extra pool_en_1, pool_idx_1=%0d", pool_idx_1);
                    $stop;
                end
            end

            // pool + maxpool ch2
            if (dut.pool_en_2) begin
                if (pool_idx_2 < POOL_NUM) begin
                    if (conv_idx <= (((pool_idx_2 / POOL_W) * 2 + 1) * OUT_W + ((pool_idx_2 % POOL_W) * 2 + 1))) begin
                        $display("============================================================");
                        $display("TB ERROR: pool2 came too early");
                        $display("pool idx=%0d pool(row=%0d,col=%0d)", pool_idx_2, pool_idx_2 / POOL_W, pool_idx_2 % POOL_W);
                        $display("conv_idx=%0d", conv_idx);
                        $display("DUT pool2 = [%0d, %0d, %0d, %0d]",
                                 pool2_data_0, pool2_data_1, pool2_data_2, pool2_data_3);
                        $display("============================================================");
                        $stop;
                    end

                    compare_pool_and_max_ch2(pool_idx_2);
                    pool_idx_2 = pool_idx_2 + 1;
                end
                else begin
                    $display("POOL2 ERROR: extra pool_en_2, pool_idx_2=%0d", pool_idx_2);
                    $stop;
                end
            end

            // pool + maxpool ch3
            if (dut.pool_en_3) begin
                if (pool_idx_3 < POOL_NUM) begin
                    if (conv_idx <= (((pool_idx_3 / POOL_W) * 2 + 1) * OUT_W + ((pool_idx_3 % POOL_W) * 2 + 1))) begin
                        $display("============================================================");
                        $display("TB ERROR: pool3 came too early");
                        $display("pool idx=%0d pool(row=%0d,col=%0d)", pool_idx_3, pool_idx_3 / POOL_W, pool_idx_3 % POOL_W);
                        $display("conv_idx=%0d", conv_idx);
                        $display("DUT pool3 = [%0d, %0d, %0d, %0d]",
                                 pool3_data_0, pool3_data_1, pool3_data_2, pool3_data_3);
                        $display("============================================================");
                        $stop;
                    end

                    compare_pool_and_max_ch3(pool_idx_3);
                    pool_idx_3 = pool_idx_3 + 1;
                end
                else begin
                    $display("POOL3 ERROR: extra pool_en_3, pool_idx_3=%0d", pool_idx_3);
                    $stop;
                end
            end

            if ((conv_idx == TOTAL_WINDOWS) &&
                (pool_idx_1 == POOL_NUM) &&
                (pool_idx_2 == POOL_NUM) &&
                (pool_idx_3 == POOL_NUM) &&
                (maxpool_match_1 == POOL_NUM) &&
                (maxpool_match_2 == POOL_NUM) &&
                (maxpool_match_3 == POOL_NUM)) begin
                $display("============================================================");
                $display("===== ALL SUCCESS =====");
                $display("conv      pass = %0d / %0d", conv_pass, TOTAL_WINDOWS);
                $display("pool ch1  pass = %0d / %0d", pool_match_1, POOL_NUM);
                $display("pool ch2  pass = %0d / %0d", pool_match_2, POOL_NUM);
                $display("pool ch3  pass = %0d / %0d", pool_match_3, POOL_NUM);
                $display("max  ch1  pass = %0d / %0d", maxpool_match_1, POOL_NUM);
                $display("max  ch2  pass = %0d / %0d", maxpool_match_2, POOL_NUM);
                $display("max  ch3  pass = %0d / %0d", maxpool_match_3, POOL_NUM);
                $display("============================================================");
                $finish;
            end
        end
    end

endmodule