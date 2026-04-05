`timescale 1ns/1ps

module cov1_ram_tb;

    localparam int IMG_W    = 24;
    localparam int IMG_H    = 24;
    localparam int INPUT_NUM = IMG_W * IMG_H;   // 576
    localparam int POOL_W   = 12;
    localparam int POOL_H   = 12;
    localparam int POOL_NUM = POOL_W * POOL_H;  // 144

    logic clk;
    logic rst_n;
    logic signed [31:0] i_cov_result;
    logic i_valid;
    logic signed [31:0] o_pool_data [0:3];
    logic o_pool_en;

    logic signed [31:0] src_img [0:IMG_H-1][0:IMG_W-1];
    logic signed [31:0] golden  [0:POOL_NUM-1][0:3];
    logic signed [31:0] o_pool_data_0;
    logic signed [31:0] o_pool_data_1;
    logic signed [31:0] o_pool_data_2;
    logic signed [31:0] o_pool_data_3;


    integer err_cnt;
    integer match_cnt;
    integer check_idx;

    cov1_ram dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .i_cov_result(i_cov_result),
        .i_valid     (i_valid),
        .o_pool_data (o_pool_data),
        .o_pool_en   (o_pool_en)
    );

    assign o_pool_data_0 = o_pool_data[0];
    assign o_pool_data_1 = o_pool_data[1];
    assign o_pool_data_2 = o_pool_data[2];
    assign o_pool_data_3 = o_pool_data[3];

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic build_input_pattern;
        integer r, c;
        integer val;
        begin
            val = 1;
            for (r = 0; r < IMG_H; r = r + 1) begin
                for (c = 0; c < IMG_W; c = c + 1) begin
                    src_img[r][c] = val;
                    val = val + 1;
                end
            end
        end
    endtask

    task automatic build_golden;
        integer pr, pc, idx;
        begin
            idx = 0;
            for (pr = 0; pr < POOL_H; pr = pr + 1) begin
                for (pc = 0; pc < POOL_W; pc = pc + 1) begin
                    golden[idx][0] = src_img[pr*2    ][pc*2    ];
                    golden[idx][1] = src_img[pr*2    ][pc*2 + 1];
                    golden[idx][2] = src_img[pr*2 + 1][pc*2    ];
                    golden[idx][3] = src_img[pr*2 + 1][pc*2 + 1];
                    idx = idx + 1;
                end
            end
        end
    endtask

    task automatic feed_input;
        integer r, c;
        begin
            i_valid      = 0;
            i_cov_result = 0;
            @(posedge clk);

            for (r = 0; r < IMG_H; r = r + 1) begin
                for (c = 0; c < IMG_W; c = c + 1) begin
                    @(negedge clk);
                    i_valid      = 1;
                    i_cov_result = src_img[r][c];
                end
            end

            @(negedge clk);
            i_valid      = 0;
            i_cov_result = 0;
        end
    endtask

    task automatic compare_window(input integer idx);
        integer pool_r, pool_c;
        begin
            pool_r = idx / POOL_W;
            pool_c = idx % POOL_W;

            if (idx >= POOL_NUM) begin
                err_cnt = err_cnt + 1;
                $display("[%0t] ERROR: extra o_pool_en, idx=%0d", $time, idx);
                $finish;
            end
            else if ((o_pool_data[0] !== golden[idx][0]) ||
                     (o_pool_data[1] !== golden[idx][1]) ||
                     (o_pool_data[2] !== golden[idx][2]) ||
                     (o_pool_data[3] !== golden[idx][3])) begin
                err_cnt = err_cnt + 1;
                $display("============================================================");
                $display("[%0t] MISMATCH idx=%0d pool(row=%0d,col=%0d)", $time, idx, pool_r, pool_c);
                $display("DUT    = [%0d, %0d, %0d, %0d]",
                         o_pool_data[0], o_pool_data[1], o_pool_data[2], o_pool_data[3]);
                $display("GOLDEN = [%0d, %0d, %0d, %0d]",
                         golden[idx][0], golden[idx][1], golden[idx][2], golden[idx][3]);
                $display("============================================================");
                $finish;
            end
            else begin
                match_cnt = match_cnt + 1;
                $display("[%0t] MATCH idx=%0d pool(row=%0d,col=%0d) -> [%0d, %0d, %0d, %0d]",
                         $time, idx, pool_r, pool_c,
                         o_pool_data[0], o_pool_data[1], o_pool_data[2], o_pool_data[3]);
            end
        end
    endtask

    always @(posedge clk) begin
        if (rst_n && o_pool_en) begin
            compare_window(check_idx);
            check_idx = check_idx + 1;
        end
    end

    initial begin
        err_cnt      = 0;
        match_cnt    = 0;
        check_idx    = 0;
        rst_n        = 0;
        i_valid      = 0;
        i_cov_result = 0;

        build_input_pattern();
        build_golden();

        repeat (5) @(posedge clk);
        rst_n = 1;

        feed_input();

        repeat (800) @(posedge clk);

        $display("============================================================");
        $display("Simulation done");
        $display("check_idx = %0d", check_idx);
        $display("match_cnt = %0d", match_cnt);
        $display("err_cnt   = %0d", err_cnt);
        $display("============================================================");

        $finish;
    end

endmodule