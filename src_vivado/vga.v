`timescale 1ns / 1ps

// vga (.clk_25mhz(),.reset(),.y(),.x(),.rdn(),.r(),.g(),.b(),.hs(),.vs(),.px());

module vga(
    input wire clk_25mhz,           // clock
    input wire reset,               // reset
    output wire [8:0] y,            // y
    output wire [9:0] x,            // x
    output wire rdn,                // read pixel RAM
    output wire [3:0] r,g,b,        // rgb
    output reg hs,vs,               // horizontal and vertical synchronization
    input wire px                   // px
    );
  
    reg [31:0] h_count;            // h_count: VGA horizontal counter (0-799)
    reg [31:0] v_count;            // v_count: VGA vertical counter (0-524)

    always @ (posedge clk_25mhz) begin
        if (reset) begin
            h_count <= 10'h0;
            v_count <= 10'h0;
        end else if (h_count == 10'd799) begin
            h_count <= 10'h0;
            if (v_count == 10'd524) begin
                v_count <= 10'h0;
            end else begin
                v_count <= v_count + 10'h1;
            end
        end else begin
            h_count <= h_count + 10'h1;
        end
    end

    // handle offset
    assign y = v_count - 10'd35;             // pixel ram row addr 
    assign x = h_count - 10'd143;            // pixel ram col addr 
    assign rdn = (h_count > 10'd142) &&         // 143 -> 782
                 (h_count < 10'd783) &&         //        640 pixels
                 (v_count > 10'd34)  &&         // 35 -> 514
                 (v_count < 10'd515);           //        480 lines


    // color: black
    assign r = (~rdn) ? 4'h0 : px ? 4'b1111:4'b0000; // red
    assign g = (~rdn) ? 4'h0 : px ? 4'b1111:4'b0000; // green
    assign b = (~rdn) ? 4'h0 : px ? 4'b1111:4'b0000; // blue

    // vga signals
    always @(posedge clk_25mhz) begin
        hs   <=  (h_count > 10'd95);    // horizontal synchronization
        vs   <=  (v_count > 10'd1);     // vertical   synchronization
    end
    
endmodule


