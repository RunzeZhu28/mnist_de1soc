module comparator(
    input  logic clk,
    input  logic rst_n,
    input  logic signed [31:0] mac_data_0,
    input  logic signed [31:0] mac_data_1,
    input  logic signed [31:0] mac_data_2,
    input  logic signed [31:0] mac_data_3,
    input  logic signed [31:0] mac_data_4,
    input  logic signed [31:0] mac_data_5,
    input  logic signed [31:0] mac_data_6,
    input  logic signed [31:0] mac_data_7,
    input  logic signed [31:0] mac_data_8,
    input  logic signed [31:0] mac_data_9,
    input  logic mac_data_valid_all,
    output logic [3:0] selected_index,
    output logic decision_valid
);

logic signed [31:0] max_value_nxt;
logic [3:0] selected_index_nxt;

always_comb begin
    selected_index_nxt = 0;
    max_value_nxt      = mac_data_0;

    if (mac_data_1 > max_value_nxt) begin
        max_value_nxt      = mac_data_1;
        selected_index_nxt = 1;
    end
    if (mac_data_2 > max_value_nxt) begin
        max_value_nxt      = mac_data_2;
        selected_index_nxt = 2;
    end
    if (mac_data_3 > max_value_nxt) begin
        max_value_nxt      = mac_data_3;
        selected_index_nxt = 3;
    end
    if (mac_data_4 > max_value_nxt) begin
        max_value_nxt      = mac_data_4;
        selected_index_nxt = 4;
    end
    if (mac_data_5 > max_value_nxt) begin
        max_value_nxt      = mac_data_5;
        selected_index_nxt = 5;
    end
    if (mac_data_6 > max_value_nxt) begin
        max_value_nxt      = mac_data_6;
        selected_index_nxt = 6;
    end
    if (mac_data_7 > max_value_nxt) begin
        max_value_nxt      = mac_data_7;
        selected_index_nxt = 7;
    end
    if (mac_data_8 > max_value_nxt) begin
        max_value_nxt      = mac_data_8;
        selected_index_nxt = 8;
    end
    if (mac_data_9 > max_value_nxt) begin
        max_value_nxt      = mac_data_9;
        selected_index_nxt = 9;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        selected_index <= 0;
        decision_valid <= 0;
    end
    else begin
        if (mac_data_valid_all) begin
            selected_index <= selected_index_nxt;
            decision_valid <= 1'b1;
        end
        else begin
            decision_valid <= 1'b0;
        end
    end
end

endmodule