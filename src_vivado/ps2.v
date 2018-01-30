`timescale 1ns / 1ps

// controller_keyboard(.clk_25mhz(),.ps2_clk(),.ps2_data(),.data());

module controller_keyboard(
    input wire clk_25mhz,
    input wire reset,
    input wire ps2_clk,
    input wire ps2_data,
    output wire [7:0] data
    );

    parameter code_null = 6'd0;
    parameter code_a = 6'd1,code_z=6'd26,code_A=6'd27,code_Z=6'd52;
    parameter code_dollar = 6'd53;
    parameter code_lbrace = 6'd54,code_rbrace=6'd55;
    parameter code_eq = 6'd56;
    parameter code_starter = 6'd57;
    parameter code_lambda = 6'd58;
    parameter code_space = 6'd59;
    parameter code_dot = 6'd60;
    parameter code_end = 6'd61;     
    parameter code_none = 6'd63;

    parameter code_bksp = 8'd65;
    parameter code_enter = 8'd66;
    parameter code_up = 8'd67;
    parameter code_down = 8'd68;

    wire clk_bit, data_bit;
    filter fc(.clk_25mhz(clk_25mhz),.data_in(ps2_clk),.data_out(clk_bit));
    filter fd(.clk_25mhz(clk_25mhz),.data_in(ps2_data),.data_out(data_bit));

    reg [10:0] word1, word2;
    reg [7:0] pre;
    reg [31:0] hold_counter;
    reg block;
    wire [7:0] trans_c;
    
    initial begin
        block <= 0;
    end

    always @(negedge clk_bit) begin
        word1 <= {data_bit, word1[10:1]};
        word2 <= {word1[0], word2[10:1]};
    end
 

    always @(posedge clk_25mhz) begin
        if (word2[8:1] != 8'hF0) begin
            pre[7:0] <= word1[8:1];
            if(trans_c) block<=1;
        end else begin
            block <= 0;
            pre[7:0] <= 8'h00;
        end
        if(pre==word1[8:1]) begin
            hold_counter = hold_counter + 1;
        end else begin
            hold_counter = 8'b0;
        end
    end
    
    trans_code mt(.clk_25mhz(clk_25mhz),.enable(hold_counter[15]),.precode(pre),.data(trans_c));

    assign data = block?code_null:trans_c;

endmodule

module filter(
    input wire clk_25mhz,
    input wire data_in,
    output reg data_out
);
    reg [7:0] buffer;
    initial begin
        buffer <= 8'd0;
    end

    always @ (posedge clk_25mhz) begin
        buffer[7] <= data_in;
        buffer[6:0] <= buffer[7:1];
        if(buffer==8'hff) begin
            data_out <= 1;
        end else if(buffer==8'h00) begin
            data_out <= 0;
        end
    end
endmodule

module trans_code(
    input wire clk_25mhz,
    input wire enable,
    input wire [7:0] precode,
    output reg [7:0] data
);
    reg shift;

    parameter code_null = 6'd0;
    parameter code_a = 6'd1,code_z=6'd26,code_A=6'd27,code_Z=6'd52;
    parameter code_dollar = 6'd53;
    parameter code_lbrace = 6'd54,code_rbrace=6'd55;
    parameter code_eq = 6'd56;
    parameter code_starter = 6'd57;
    parameter code_lambda = 6'd58;
    parameter code_space = 6'd59;
    parameter code_dot = 6'd60;
    parameter code_end = 6'd61;     
    parameter code_none = 6'd63;

    parameter code_bksp = 8'd65;
    parameter code_enter = 8'd66;
    parameter code_up = 8'd67;
    parameter code_down = 8'd68;

    always @ (posedge clk_25mhz) begin
        if(enable) begin
            if(!shift) begin
                case(precode[7:0])
                    8'h00:  begin
                        data <= code_null; // none
                        shift <= 1'b0;
                    end
                    8'h12: begin
                        data<=code_null;
                        shift<=1'b1;
                    end
                    8'h59: begin
                        data<=code_null;
                        shift<=1'b1;
                    end
                    8'h16: data<=code_up;     // 1 up
                    8'h1e: data<=code_down;   // 2 down
                    8'h5d: data<=code_lambda; // \
                    8'h49: data<=code_dot;    // .
                    8'h55: data<=code_eq;     // =
                    8'h46: data<=code_lbrace; // 9 (
                    8'h45: data<=code_rbrace; // 0 )
                    8'h25: data<=code_dollar; // 3 $
                    8'h1c: data<=code_a+0;    // a
                    8'h32: data<=code_a+1;
                    8'h21: data<=code_a+2;
                    8'h23: data<=code_a+3;
                    8'h24: data<=code_a+4;
                    8'h2b: data<=code_a+5;
                    8'h34: data<=code_a+6;
                    8'h33: data<=code_a+7;
                    8'h43: data<=code_a+8;
                    8'h3b: data<=code_a+9;
                    8'h42: data<=code_a+10;
                    8'h4b: data<=code_a+11;
                    8'h3a: data<=code_a+12;
                    8'h31: data<=code_a+13;
                    8'h44: data<=code_a+14;
                    8'h4d: data<=code_a+15;
                    8'h15: data<=code_a+16;
                    8'h2d: data<=code_a+17;
                    8'h1b: data<=code_a+18;
                    8'h2c: data<=code_a+19;
                    8'h3c: data<=code_a+20;
                    8'h2a: data<=code_a+21;
                    8'h1d: data<=code_a+22;
                    8'h22: data<=code_a+23;
                    8'h35: data<=code_a+24;
                    8'h1a: data<=code_a+25;
                    8'h29: data<=code_space; // SPACE
                    8'h66: data<=code_bksp;  // BKSP
                    8'h5a: data<=code_enter; // Enter
                    default: data<=code_null;
                endcase
            end else begin
                case(precode[7:0])
                    8'h00:  begin
                        data<=code_null; // none
                        shift<=1'b0;
                    end
                    8'h12: begin
                        data<=code_null;
                        shift<=1'b1;
                    end
                    8'h59: begin
                        data<=code_null;
                        shift<=1'b1;
                    end
                    8'h16: data<=code_up;     // 1 up
                    8'h1e: data<=code_down;   // 2 down
                    8'h5d: data<=code_lambda; // \
                    8'h49: data<=code_dot;    // .
                    8'h55: data<=code_eq;     // =
                    8'h46: data<=code_lbrace; // 9 (
                    8'h45: data<=code_rbrace; // 0 )
                    8'h25: data<=code_dollar; // 3 $
                    8'h1c: data<=code_A+0;    // A
                    8'h32: data<=code_A+1;
                    8'h21: data<=code_A+2;
                    8'h23: data<=code_A+3;
                    8'h24: data<=code_A+4;
                    8'h2b: data<=code_A+5;
                    8'h34: data<=code_A+6;
                    8'h33: data<=code_A+7;
                    8'h43: data<=code_A+8;
                    8'h3b: data<=code_A+9;
                    8'h42: data<=code_A+10;
                    8'h4b: data<=code_A+11;
                    8'h3a: data<=code_A+12;
                    8'h31: data<=code_A+13;
                    8'h44: data<=code_A+14;
                    8'h4d: data<=code_A+15;
                    8'h15: data<=code_A+16;
                    8'h2d: data<=code_A+17;
                    8'h1b: data<=code_A+18;
                    8'h2c: data<=code_A+19;
                    8'h3c: data<=code_A+20;
                    8'h2a: data<=code_A+21;
                    8'h1d: data<=code_A+22;
                    8'h22: data<=code_A+23;
                    8'h35: data<=code_A+24;
                    8'h1a: data<=code_A+25;
                    8'h29: data<=code_space; // SPACE
                    8'h66: data<=code_bksp;  // BKSP
                    8'h5a: data<=code_enter; // Enter
                endcase
            end
        end else begin
            data <= code_null;
        end
    end

endmodule
