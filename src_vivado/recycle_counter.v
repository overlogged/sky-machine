`timescale 1ns / 1ps

// recycle_counter(.ticks(tick_h),.reset(reset),.max_value(10'd799),.counter(h_count));

module recycle_counter(
    input wire ticks,
    input wire reset,
    input wire [31:0] max_value,
    output reg [31:0] counter
);
    always @(posedge ticks or posedge reset) begin
        if (reset) begin
            counter <= 0;
        end else if (counter == max_value) begin
            counter <= 0;
        end else begin 
            counter <= counter + 1;
        end
    end
endmodule
