`timescale 1ns / 1ps

// model_lexer ml(.clk_25mhz(),.reset(),.data_in(),.data_step(),.data_out());


module model_lexer(
    input wire clk_25mhz,               // clock
    input wire clk_io,                  // io clock
    input wire reset,                   // reset
    input wire [7:0] data_in,           // input:  byte stream
    input wire [7:0] data_step,         // input:  output stream's move step
    output reg [15:0] data_out          // output: token stream (look ahead 2 characters)
);

    parameter token_null = 0;
    parameter token_identifier = 65;
    parameter token_lbrace = 66;
    parameter token_rbrace = 67;
    parameter token_lambda = 68;
    parameter token_dot = 69;
    parameter token_eq = 70;
    parameter token_set = 71;
    parameter token_end = 72;

    parameter buffer_size = 32;

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

    reg [7:0]  state;
    reg [7:0]  buffer[0:buffer_size-1];
    reg [7:0] ptr_write,ptr_read;
    reg done;

    initial begin
        done <= 0;
        ptr_write <= 8'd0;
        ptr_read  <= 8'd0;
        state <= token_null;
    end


    always @ (posedge clk_25mhz) begin
        if(reset) begin
            ptr_write <= 8'd0;
            ptr_read  <= 8'd0;
            done <= 0;
            state <= token_null;
        end else begin
            if(clk_io) begin
                // output the token stream
                ptr_read <= ptr_read + data_step;
                data_out[7:0]  <= (ptr_read+data_step+0<ptr_write)?buffer[(ptr_read+data_step+0)%buffer_size]:(done?token_end:token_null);
                data_out[15:8] <= (ptr_read+data_step+1<ptr_write)?buffer[(ptr_read+data_step+1)%buffer_size]:(done?token_end:token_null);
            end else begin
                // tokenize
                if(done==0 && data_in[7:0]) begin
                    if((data_in>=code_a && data_in<=code_z) || (data_in>=code_A&&data_in<=code_Z)) begin
                        case(state)
                            token_null:
                            begin
                                buffer[ptr_write%buffer_size] <= token_identifier;
                                buffer[(ptr_write+1)%buffer_size] <= data_in;
                                ptr_write <= ptr_write + 8'd2;
                                state <= token_identifier;
                            end

                            token_identifier:
                            begin
                                buffer[ptr_write%buffer_size] <= data_in;
                                ptr_write <= ptr_write + 8'b1;
                            end
                        endcase
                    end else begin
                        state <= token_null;                    
                        if(data_in==code_lambda) begin
                            buffer[ptr_write%buffer_size] <= token_lambda;
                            ptr_write <= ptr_write + 8'd1;
                        end else if(data_in==code_lbrace) begin
                            buffer[ptr_write%buffer_size] <= token_lbrace;
                            ptr_write <= ptr_write + 8'd1;
                        end else if(data_in==code_rbrace) begin
                            buffer[ptr_write%buffer_size] <= token_rbrace;
                            ptr_write <= ptr_write + 8'd1;                                
                        end else if(data_in==code_dot) begin
                            buffer[ptr_write%buffer_size] <= token_dot;
                            ptr_write <= ptr_write + 8'd1;  
                        end else if(data_in==code_eq) begin
                            buffer[ptr_write%buffer_size] <= token_eq;
                            ptr_write <= ptr_write + 8'd1;                                                        
                        end else if(data_in==code_dollar) begin
                            buffer[ptr_write%buffer_size] <= token_set;
                            ptr_write <= ptr_write + 8'd1;
                        end else if(data_in==code_end) begin
                            buffer[ptr_write%buffer_size] <= token_end;
                            ptr_write <= ptr_write + 8'd1;
                            done <= 1;
                        end
                    end
                end
            end
        end
    end

endmodule


