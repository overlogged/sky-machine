`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:43:56 12/30/2017
// Design Name:   model_lexer
// Module Name:   C:/Users/nicekingwei/workspace/verilog/sky-machine/test_lexer.v
// Project Name:  sky-machine
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: model_lexer
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_lexer;

    // Inputs
    reg clk_25mhz;
    reg reset;
    reg [7:0] data_in;
    reg [7:0] data_step;

    // Outputs
    wire [31:0] data_out;

    // Instantiate the Unit Under Test (UUT)
    model_lexer uut (
        .clk_25mhz(clk_25mhz), 
        .reset(reset), 
        .data_in(data_in), 
        .data_step(data_step), 
        .data_out(data_out)
    );

    initial begin
        // Initialize Inputs
        clk_25mhz = 0;
        reset = 1;
        data_step = 0;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Add stimulus here
        reset = 0;
        data_step = 1;
    end
      
    always begin
        clk_25mhz<=~clk_25mhz;
        #50;
    end
    
    reg [7:0] counter;
    initial begin
        counter <= 8'b0;
    end
    wire [7:0] token;
    assign token = data_out[7:0]<8 ? data_out[7:0]+48 : data_out[7:0];

    // let str="    (\\xxx.xxx) yyy" in sequence_ $ map putStr $ ["parameter max_size = ",(show (length str)),";\nwire [7:0] string [0:max_size-1];\n/*",str,"*/\n"] ++ ([("assign string[" ++ show (fst t) ++ "] = " ++ "8'd" ++ show (ord (snd t)) ++ ";\n") | t<-zip [0..] str])
    parameter max_size = 8;
    wire [7:0] string [0:max_size-1];
    /* id=\x.x*/
    assign string[0] = 8'd32;
    assign string[1] = 8'd105;
    assign string[2] = 8'd100;
    assign string[3] = 8'd61;
    assign string[4] = 8'd92;
    assign string[5] = 8'd120;
    assign string[6] = 8'd46;
    assign string[7] = 8'd120;

    always @(posedge clk_25mhz or posedge reset) begin
        if(reset) begin
            counter <= 8'b0;
        end else begin
            if(counter<max_size) begin
                data_in<=string[counter];
                counter<=counter+1;
            end else begin
                data_in<=0;
            end
        end
    end

endmodule
