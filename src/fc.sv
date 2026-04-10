module fc(
    input clk,
    input rst_n,
    input signed [31:0] i_pool_data_1,
    input i_wr_valid_1,
    input signed [31:0] i_pool_data_2,
    input i_wr_valid_2,
    input signed [31:0] i_pool_data_3,
    input i_wr_valid_3,
    output logic o_decision_valid,
    output logic [3:0] decision,
    output logic o_ch1_full,
    output logic o_ch2_full,
    output logic o_ch3_full
);

localparam DATA_SIZE = 48;
localparam DATA_WIDTH = $clog2(DATA_SIZE);

logic [DATA_WIDTH - 1:0] counter_1, counter_2, counter_3;
logic signed [31:0] fc_data [0:DATA_SIZE-1];
logic signed [7:0] weight [0:9][0:DATA_SIZE-1]; 
logic signed [7:0] weight_flat [0:DATA_SIZE*10-1];
logic signed [7:0] bias [0:9];

logic mac_en;
logic [3:0] selected_index;
logic decision_valid;
logic mac_data_valid_all;

logic mac_data_valid_0, mac_data_valid_1, mac_data_valid_2, mac_data_valid_3, mac_data_valid_4;
logic mac_data_valid_5, mac_data_valid_6, mac_data_valid_7, mac_data_valid_8, mac_data_valid_9;
logic signed [31:0] mac_data_0, mac_data_1, mac_data_2, mac_data_3, mac_data_4;
logic signed [31:0] mac_data_5, mac_data_6, mac_data_7, mac_data_8, mac_data_9;

integer i, j;

initial begin
    $readmemh("E:/mnist/weight/fc_bias.txt", bias);
    $readmemh("E:/mnist/weight/fc_weight.txt", weight_flat);

    for (i = 0; i < 10; i = i + 1) begin
        for (j = 0; j < DATA_SIZE; j = j + 1) begin
            weight[i][j] = weight_flat[i*DATA_SIZE + j];
        end
    end
end

assign o_ch1_full = (counter_1 == 16);
assign o_ch2_full = (counter_2 == 16);
assign o_ch3_full = (counter_3 == 16);
assign mac_en = o_ch1_full && o_ch2_full && o_ch3_full;

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        counter_1 <= 0;
        counter_2 <= 0;
        counter_3 <= 0;
        for (int i=0; i<DATA_SIZE; i=i+1) begin
            fc_data[i] <= 0;
        end
    end else begin
        if(i_wr_valid_1 && !o_ch1_full) begin
            counter_1 <= counter_1 + 1;
            fc_data[counter_1] <= i_pool_data_1;
        end
        if(i_wr_valid_2 && !o_ch2_full) begin
            counter_2 <= counter_2 + 1;
            fc_data[counter_2 + 16] <= i_pool_data_2;
        end
        if(i_wr_valid_3 && !o_ch3_full) begin
            counter_3 <= counter_3 + 1;
            fc_data[counter_3 + 32] <= i_pool_data_3;
        end
    end
end


fc_mac u_fc_mac_0(
    .clk(clk),
    .rst_n(rst_n),
    .i_mac_en(mac_en),
    .i_data(fc_data),  
    .i_weight(weight[0]),       
    .bias(bias[0]),                  
    .o_mac_data_valid(mac_data_valid_0),     
    .o_mac_data(mac_data_0)  
);

fc_mac u_fc_mac_1(
    .clk(clk),
    .rst_n(rst_n),
    .i_mac_en(mac_en),
    .i_data(fc_data),  
    .i_weight(weight[1]),       
    .bias(bias[1]),                  
    .o_mac_data_valid(mac_data_valid_1),     
    .o_mac_data(mac_data_1)  
);

fc_mac u_fc_mac_2(
    .clk(clk),
    .rst_n(rst_n),
    .i_mac_en(mac_en),
    .i_data(fc_data),  
    .i_weight(weight[2]),       
    .bias(bias[2]),                  
    .o_mac_data_valid(mac_data_valid_2),     
    .o_mac_data(mac_data_2)  
);

fc_mac u_fc_mac_3(
    .clk(clk),
    .rst_n(rst_n),
    .i_mac_en(mac_en),
    .i_data(fc_data),  
    .i_weight(weight[3]),       
    .bias(bias[3]),                  
    .o_mac_data_valid(mac_data_valid_3),     
    .o_mac_data(mac_data_3)  
);

fc_mac u_fc_mac_4(
    .clk(clk),
    .rst_n(rst_n),
    .i_mac_en(mac_en),
    .i_data(fc_data),  
    .i_weight(weight[4]),       
    .bias(bias[4]),                  
    .o_mac_data_valid(mac_data_valid_4),     
    .o_mac_data(mac_data_4)  
);

fc_mac u_fc_mac_5(
    .clk(clk),
    .rst_n(rst_n),
    .i_mac_en(mac_en),
    .i_data(fc_data),  
    .i_weight(weight[5]),       
    .bias(bias[5]),                  
    .o_mac_data_valid(mac_data_valid_5),     
    .o_mac_data(mac_data_5)  
);

fc_mac u_fc_mac_6(
    .clk(clk),
    .rst_n(rst_n),
    .i_mac_en(mac_en),
    .i_data(fc_data),  
    .i_weight(weight[6]),       
    .bias(bias[6]),                  
    .o_mac_data_valid(mac_data_valid_6),     
    .o_mac_data(mac_data_6)  
);

fc_mac u_fc_mac_7(
    .clk(clk),
    .rst_n(rst_n),
    .i_mac_en(mac_en),
    .i_data(fc_data),  
    .i_weight(weight[7]),       
    .bias(bias[7]),                  
    .o_mac_data_valid(mac_data_valid_7),     
    .o_mac_data(mac_data_7)  
);

fc_mac u_fc_mac_8(
    .clk(clk),
    .rst_n(rst_n),
    .i_mac_en(mac_en),
    .i_data(fc_data),  
    .i_weight(weight[8]),       
    .bias(bias[8]),                  
    .o_mac_data_valid(mac_data_valid_8),     
    .o_mac_data(mac_data_8)  
);

fc_mac u_fc_mac_9(
    .clk(clk),
    .rst_n(rst_n),
    .i_mac_en(mac_en),
    .i_data(fc_data),  
    .i_weight(weight[9]),       
    .bias(bias[9]),                  
    .o_mac_data_valid(mac_data_valid_9),     
    .o_mac_data(mac_data_9)  
);

assign mac_data_valid_all = mac_data_valid_0 & mac_data_valid_1 & mac_data_valid_2 &
                            mac_data_valid_3 & mac_data_valid_4 & mac_data_valid_5 &
                            mac_data_valid_6 & mac_data_valid_7 & mac_data_valid_8 &
                            mac_data_valid_9;

comparator u_comparator(
    .clk(clk),
    .rst_n(rst_n),
    .mac_data_0(mac_data_0),
    .mac_data_1(mac_data_1),
    .mac_data_2(mac_data_2),
    .mac_data_3(mac_data_3),
    .mac_data_4(mac_data_4),
    .mac_data_5(mac_data_5),
    .mac_data_6(mac_data_6),
    .mac_data_7(mac_data_7),
    .mac_data_8(mac_data_8),
    .mac_data_9(mac_data_9),
    .mac_data_valid_all(mac_data_valid_all), 
    .selected_index(selected_index),
    .decision_valid(decision_valid)
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        decision <= 0;
        o_decision_valid <= 0;
    end else if (decision_valid) begin
        o_decision_valid <= 1;
        decision <= selected_index; 
    end else begin
        o_decision_valid <= 0;
    end
end

endmodule