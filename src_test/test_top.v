`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:18:37 12/31/2017
// Design Name:   top
// Module Name:   C:/Users/nicekingwei/workspace/verilog/sky-machine/test_top.v
// Project Name:  sky-machine
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_top;

	// Inputs
	reg clk_100mhz;
	reg [15:0] SW;
	reg PS2_data;
	reg PS2_clk;

	// Outputs
	wire [3:0] Blue;
	wire [3:0] Green;
	wire [3:0] Red;
	wire HSYNC;
	wire VSYNC;
	wire Buzzer;

	// Instantiate the Unit Under Test (UUT)
	top uut (
		.clk_100mhz(clk_100mhz), 
		.SW(SW), 
		.PS2_data(PS2_data), 
		.PS2_clk(PS2_clk), 
		.Blue(Blue), 
		.Green(Green), 
		.Red(Red), 
		.HSYNC(HSYNC), 
		.VSYNC(VSYNC), 
		.Buzzer(Buzzer)
	);

	initial begin
		// Initialize Inputs
		clk_100mhz = 0;
		SW = 0;
		PS2_data = 0;
		PS2_clk = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

