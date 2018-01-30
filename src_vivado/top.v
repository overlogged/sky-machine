`timescale 1ns / 1ps

module top(
    input wire clk_100mhz,
    input wire [3:0] SW,
    input wire PS2_data,
    input wire PS2_clk,
    output wire [3:0] Blue,
    output wire [3:0] Green,
    output wire [3:0] Red,
    output wire HSYNC,
    output wire VSYNC
);

    wire reset;    
    wire [31:0] clk_div;
    wire [7:0] char_to_append;
    wire [7:0] char_input;
    wire [7:0] cmd;
    wire clk_25mhz,clk_1s,clk_io,clk_50mhz;

    assign clk_1s = clk_div[25];
    assign clk_25mhz = clk_div[1];
    assign clk_50mhz = clk_div[0];
    assign clk_io = clk_div[2];
	 
    assign reset = SW[1];
    view mv(
        .clk_50mhz(clk_50mhz),
        .clk_25mhz(clk_25mhz),
        .clk_1s(clk_1s),
        .reset(reset),
        .r(Red),.g(Green),.b(Blue),
        .hs(HSYNC),.vs(VSYNC),
        .cmd(cmd),
        .data(char_to_append)    
    );
    model_editor me(
        .clk_25mhz(clk_25mhz),
        .clk_io(clk_io),
        .reset(reset),
        .ch_input(char_input),
        .ch_append(char_to_append),
        .cmd(cmd)
    );
    
    recycle_counter mc(.ticks(clk_100mhz),.reset(1'b0),.max_value(32'hffffffff),.counter(clk_div));


    
    controller_keyboard mk(
        .clk_25mhz(clk_25mhz),
        .reset(reset),
        .ps2_clk(PS2_clk),.ps2_data(PS2_data),
        .data(char_input)
    );

endmodule
