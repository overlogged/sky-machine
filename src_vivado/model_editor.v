`timescale 1ns / 1ps

// model_editor(.clk_25mhz(),.ch_input(),.reset(),.ch_append(),.cmd());

module model_editor(
    input wire clk_25mhz,               // clock
    input wire clk_io,                  // io clock
    input wire [7:0] ch_input,          // input of keyboard
    input wire reset,                   // reset
    output reg [5:0] ch_append,         // data for appending: 0 for nothing input
    output reg [7:0] cmd                // commmand
);
    parameter buffer_size = 256;                    // max_size for a lamdba expression
    reg [7:0] buffer_output;
    reg [7:0] buffer [0:buffer_size-1];             // for parser
    reg [7:0] buffer_pos;
    reg [7:0] buffer_counter;

    reg [7:0] delay_counter;

    // cmd
    wire busy,pg_up,pg_down,backspace,breakline;
    parameter cmd_ready = 8'd0;
    parameter cmd_busy = 8'b00000001;
    parameter cmd_pgup = 8'b00000010;
    parameter cmd_pgdown = 8'b00000100;
    parameter cmd_backspace = 8'b00001000;
    parameter cmd_breakline = 8'b00010000;
    parameter cmd_reserved = 8'b10000000;


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

    assign busy = cmd[0];

    reg done;    

    wire [5:0] lambda_output;

    model_lambda_calculus ml(
        .clk_25mhz(clk_25mhz),
        .clk_io(clk_io),
        .reset(reset),
        .data_in(buffer_output),
        .data_out(lambda_output)
    );    

    always @ (posedge clk_25mhz) begin
        if(reset) begin
            buffer_pos <= 8'd0;
            buffer_counter <= 8'd0;
            ch_append <= 6'd0;
            cmd <= cmd_ready;
            buffer_output <= 8'd0;
            done <= 1'b0;
        end else begin  
            if(!busy) begin
                if(ch_input==code_bksp) begin
                    // backspace
                    if(buffer_pos>=8'd10) begin
                        buffer_pos <= buffer_pos-8'd1;
                        cmd <= cmd_backspace;
                    end
                    ch_append <= code_null;
                end else if(ch_input==code_enter) begin
                    // breakline
                    ch_append <= code_null;     
                    cmd <= cmd_breakline | cmd_busy;            // start lambda calculus
                    buffer[buffer_pos] <= code_end;
                    buffer_pos <= buffer_pos+1;
                end else if(ch_input==code_up) begin
                    // up
                    ch_append <= code_null;
                    cmd <= cmd_pgup;
                end else if(ch_input==code_down) begin
                    // down
                    ch_append <= code_null;
                    cmd <= cmd_pgdown;
                end else if(ch_input!=code_null && ch_input!=code_end) begin
                    ch_append <= ch_input;
                    cmd <= code_null;
                    buffer[buffer_pos] <= ch_input;
                    buffer_pos <= buffer_pos+8'd1;         
                end else if(buffer_pos<=8'd8) begin
                    if(buffer_pos==0) ch_append <= code_starter;
                    else ch_append<=0;
                    cmd <= cmd_ready;
                    buffer[buffer_pos] <= code_space;
                    buffer_pos <= buffer_pos+1;
                end else begin
                    buffer[buffer_pos] <= code_null;
                    ch_append <= code_null;
                    cmd <= cmd_ready;
                end
            end else begin
                ch_append <= code_null;
                cmd <= cmd_busy;

                // transfer
                if(clk_io) begin
                    if(buffer_counter<buffer_pos) begin
                        buffer_output <= buffer[buffer_counter];
                        buffer_counter <= buffer_counter+1;
                    end else begin
                        buffer_output <= 0;
                    end
                
                    // output
                    if(!done) begin
                        if(lambda_output==code_end) begin
                            ch_append <= code_null;
                            done <= 1;
                        end else if(lambda_output) begin
                            ch_append <= lambda_output;
                        end
                    end else begin
                        buffer_pos <= 8'd0;
                        ch_append <= code_null;
                        cmd <= cmd_breakline;
                        buffer_counter <= 8'd0;
                        buffer_output <= 8'd0;
                        done <= 1'b0;
                    end
                end
            end
        end
    end
endmodule
