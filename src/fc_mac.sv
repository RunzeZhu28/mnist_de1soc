module fc_mac(
    input clk,
    input rst_n,
    input i_mac_en,
    input signed [31:0] i_data [0:47],  
    input signed [7:0] i_weight [0:47],       
    input signed [7:0] bias,                  
    output logic o_mac_data_valid,     
    output logic signed [31:0] o_mac_data  
);

always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        o_mac_data_valid <= 0;
        o_mac_data <= 0; 
    end
    else if(i_mac_en) begin
        logic signed [31:0] sum;  
        sum = bias;  

        for (int i = 0; i < 48; i = i + 1) begin
            sum = sum + (i_data[i] * i_weight[i]); 
        end
        
        o_mac_data <= sum;  
        o_mac_data_valid <= 1;  
    end
    else begin
        o_mac_data_valid <= 0; 
    end
end

endmodule