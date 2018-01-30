`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:22:43 12/31/2017
// Design Name:   model_editor
// Module Name:   C:/Users/nicekingwei/workspace/verilog/sky-machine/test_editor.v
// Project Name:  sky-machine
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: model_editor
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module test_editor;

    // Inputs
    reg [1:0] counter;
    reg [7:0] ch_input;
    reg reset;

    // Outputs
    wire [5:0] ch_append;
    wire [7:0] cmd;

    wire busy;
    assign busy = cmd[0];

    // Instantiate the Unit Under Test (UUT)
    model_editor uut (
        .clk_25mhz(counter[0]), 
        .clk_io(counter[1]),
        .ch_input(ch_input), 
        .reset(reset), 
        .ch_append(ch_append), 
        .cmd(cmd)
    );

    initial begin
        // Initialize Inputs
        ch_input = 0;
		  counter = 0;
        reset = 1;

        // Wait 100 ns for global reset to finish
        #100;
        
        // Add stimulus here
        reset = 0;
    end
    
	always begin
		counter<=(counter+1)%4;
		#50;
	end

    reg [15:0] pos,index;
    parameter max_size = 64;
    // codegen
    parameter count = 13;
    wire [7:0] string [0:count-1][0:max_size-1];
    /* */
    assign string[0][0] = 8'd59;
    assign string[0][1] = 8'd66;
    assign string[0][2] = 8'd0;
    /*$id =\x.x*/
    assign string[1][0] = 8'd53;
    assign string[1][1] = 8'd9;
    assign string[1][2] = 8'd4;
    assign string[1][3] = 8'd59;
    assign string[1][4] = 8'd56;
    assign string[1][5] = 8'd58;
    assign string[1][6] = 8'd24;
    assign string[1][7] = 8'd60;
    assign string[1][8] = 8'd24;
    assign string[1][9] = 8'd66;
    assign string[1][10] = 8'd0;
    /*(\xx.xx) a*/
    assign string[2][0] = 8'd54;
    assign string[2][1] = 8'd58;
    assign string[2][2] = 8'd24;
    assign string[2][3] = 8'd24;
    assign string[2][4] = 8'd60;
    assign string[2][5] = 8'd24;
    assign string[2][6] = 8'd24;
    assign string[2][7] = 8'd55;
    assign string[2][8] = 8'd59;
    assign string[2][9] = 8'd1;
    assign string[2][10] = 8'd66;
    assign string[2][11] = 8'd0;
    /*id yyy*/
    assign string[3][0] = 8'd9;
    assign string[3][1] = 8'd4;
    assign string[3][2] = 8'd59;
    assign string[3][3] = 8'd25;
    assign string[3][4] = 8'd25;
    assign string[3][5] = 8'd25;
    assign string[3][6] = 8'd66;
    assign string[3][7] = 8'd0;
    /*$true=\a.\b.a*/
    assign string[4][0] = 8'd53;
    assign string[4][1] = 8'd20;
    assign string[4][2] = 8'd18;
    assign string[4][3] = 8'd21;
    assign string[4][4] = 8'd5;
    assign string[4][5] = 8'd56;
    assign string[4][6] = 8'd58;
    assign string[4][7] = 8'd1;
    assign string[4][8] = 8'd60;
    assign string[4][9] = 8'd58;
    assign string[4][10] = 8'd2;
    assign string[4][11] = 8'd60;
    assign string[4][12] = 8'd1;
    assign string[4][13] = 8'd66;
    assign string[4][14] = 8'd0;
    /*$false=\a.\b.b*/
    assign string[5][0] = 8'd53;
    assign string[5][1] = 8'd6;
    assign string[5][2] = 8'd1;
    assign string[5][3] = 8'd12;
    assign string[5][4] = 8'd19;
    assign string[5][5] = 8'd5;
    assign string[5][6] = 8'd56;
    assign string[5][7] = 8'd58;
    assign string[5][8] = 8'd1;
    assign string[5][9] = 8'd60;
    assign string[5][10] = 8'd58;
    assign string[5][11] = 8'd2;
    assign string[5][12] = 8'd60;
    assign string[5][13] = 8'd2;
    assign string[5][14] = 8'd66;
    assign string[5][15] = 8'd0;
    /*true*/
    assign string[6][0] = 8'd20;
    assign string[6][1] = 8'd18;
    assign string[6][2] = 8'd21;
    assign string[6][3] = 8'd5;
    assign string[6][4] = 8'd66;
    assign string[6][5] = 8'd0;
    /*$zero=\f.\x.x*/
    assign string[7][0] = 8'd53;
    assign string[7][1] = 8'd26;
    assign string[7][2] = 8'd5;
    assign string[7][3] = 8'd18;
    assign string[7][4] = 8'd15;
    assign string[7][5] = 8'd56;
    assign string[7][6] = 8'd58;
    assign string[7][7] = 8'd6;
    assign string[7][8] = 8'd60;
    assign string[7][9] = 8'd58;
    assign string[7][10] = 8'd24;
    assign string[7][11] = 8'd60;
    assign string[7][12] = 8'd24;
    assign string[7][13] = 8'd66;
    assign string[7][14] = 8'd0;
    /*$one=\f.\x.f x*/
    assign string[8][0] = 8'd53;
    assign string[8][1] = 8'd15;
    assign string[8][2] = 8'd14;
    assign string[8][3] = 8'd5;
    assign string[8][4] = 8'd56;
    assign string[8][5] = 8'd58;
    assign string[8][6] = 8'd6;
    assign string[8][7] = 8'd60;
    assign string[8][8] = 8'd58;
    assign string[8][9] = 8'd24;
    assign string[8][10] = 8'd60;
    assign string[8][11] = 8'd6;
    assign string[8][12] = 8'd59;
    assign string[8][13] = 8'd24;
    assign string[8][14] = 8'd66;
    assign string[8][15] = 8'd0;
    /*$two=\f.\x.f (f x)*/
    assign string[9][0] = 8'd53;
    assign string[9][1] = 8'd20;
    assign string[9][2] = 8'd23;
    assign string[9][3] = 8'd15;
    assign string[9][4] = 8'd56;
    assign string[9][5] = 8'd58;
    assign string[9][6] = 8'd6;
    assign string[9][7] = 8'd60;
    assign string[9][8] = 8'd58;
    assign string[9][9] = 8'd24;
    assign string[9][10] = 8'd60;
    assign string[9][11] = 8'd6;
    assign string[9][12] = 8'd59;
    assign string[9][13] = 8'd54;
    assign string[9][14] = 8'd6;
    assign string[9][15] = 8'd59;
    assign string[9][16] = 8'd24;
    assign string[9][17] = 8'd55;
    assign string[9][18] = 8'd66;
    assign string[9][19] = 8'd0;
    /*$succ=\n.\f.\x.f ((n f) x)*/
    assign string[10][0] = 8'd53;
    assign string[10][1] = 8'd19;
    assign string[10][2] = 8'd21;
    assign string[10][3] = 8'd3;
    assign string[10][4] = 8'd3;
    assign string[10][5] = 8'd56;
    assign string[10][6] = 8'd58;
    assign string[10][7] = 8'd14;
    assign string[10][8] = 8'd60;
    assign string[10][9] = 8'd58;
    assign string[10][10] = 8'd6;
    assign string[10][11] = 8'd60;
    assign string[10][12] = 8'd58;
    assign string[10][13] = 8'd24;
    assign string[10][14] = 8'd60;
    assign string[10][15] = 8'd6;
    assign string[10][16] = 8'd59;
    assign string[10][17] = 8'd54;
    assign string[10][18] = 8'd54;
    assign string[10][19] = 8'd14;
    assign string[10][20] = 8'd59;
    assign string[10][21] = 8'd6;
    assign string[10][22] = 8'd55;
    assign string[10][23] = 8'd59;
    assign string[10][24] = 8'd24;
    assign string[10][25] = 8'd55;
    assign string[10][26] = 8'd66;
    assign string[10][27] = 8'd0;
    /*$two=succ one*/
    assign string[11][0] = 8'd53;
    assign string[11][1] = 8'd20;
    assign string[11][2] = 8'd23;
    assign string[11][3] = 8'd15;
    assign string[11][4] = 8'd56;
    assign string[11][5] = 8'd19;
    assign string[11][6] = 8'd21;
    assign string[11][7] = 8'd3;
    assign string[11][8] = 8'd3;
    assign string[11][9] = 8'd59;
    assign string[11][10] = 8'd15;
    assign string[11][11] = 8'd14;
    assign string[11][12] = 8'd5;
    assign string[11][13] = 8'd66;
    assign string[11][14] = 8'd0;
    /*$three=succ two*/
    assign string[12][0] = 8'd53;
    assign string[12][1] = 8'd20;
    assign string[12][2] = 8'd8;
    assign string[12][3] = 8'd18;
    assign string[12][4] = 8'd5;
    assign string[12][5] = 8'd5;
    assign string[12][6] = 8'd56;
    assign string[12][7] = 8'd19;
    assign string[12][8] = 8'd21;
    assign string[12][9] = 8'd3;
    assign string[12][10] = 8'd3;
    assign string[12][11] = 8'd59;
    assign string[12][12] = 8'd20;
    assign string[12][13] = 8'd23;
    assign string[12][14] = 8'd15;
    assign string[12][15] = 8'd66;
    assign string[12][16] = 8'd0;

    reg start;
    reg [7:0] delay_counter;
    always @(posedge counter[0] or posedge reset) begin
        if(reset) begin
            pos <= 8'b0;
            start <= 0;
            index <= 0;
            delay_counter <= 0;
        end else if(index<count) begin
            if(start && string[index][pos]) begin
                if(pos==0) begin
                    $display("start input");
                end
                ch_input<=string[index][pos];
                pos<=pos+1;             
            end else if(start) begin
                start <= 0;
                pos <= 0;
                index <= index+1;
                ch_input <= 0;
            end else if(busy==0) begin
                if(delay_counter==8'hff) begin
                    start <= 1;
                    delay_counter <= 0;
                end else begin
                    delay_counter <= delay_counter+1;
                end
            end
        end
    end

    always @(posedge counter[0]) begin
        if(ch_append) begin
            $display("%d",ch_append);
        end
    end

endmodule

