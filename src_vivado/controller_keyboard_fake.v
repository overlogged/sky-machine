`timescale 1ns / 1ps

// controller_keyboard(.clk_25mhz(),.ps2_clk(),.ps2_data(),.data());

module controller_keyboard_fake(
    input wire clk_25mhz,
    input wire reset,
    input wire ps2_clk,
    input wire ps2_data,
    output reg	[7:0] data
    );

    reg [7:0] counter;
    reg [7:0] delay_counter;
    parameter max_size = 10;
    wire [7:0] string [0:max_size-1];

    initial begin
        counter <= 8'b0;
        delay_counter <= 8'b0;
    end

    // sequence_ $ [putStrLn ("\tassign string[" ++ show (fst t) ++ "] = " ++ "8'd" ++ show (ord (snd t)) ++ ";") | t<-zip [0..] "skysissi,I love you!"]
        assign string[0] = 8'd53;
        assign string[1] = 8'd9;
        assign string[2] = 8'd4;
        assign string[3] = 8'd59;
        assign string[4] = 8'd56;
        assign string[5] = 8'd58;
        assign string[6] = 8'd24;
        assign string[7] = 8'd60;
        assign string[8] = 8'd24;
        assign string[9] = 8'd66;

    always @(posedge clk_25mhz or posedge reset) begin
        if(reset) begin
            delay_counter <= 8'b0;
            counter <= 8'b0;
        end else begin
            if(delay_counter<8'hfe) begin
                delay_counter <= delay_counter + 8'd1;
            end else begin
                if(counter<max_size) begin
                    data<=string[counter];
                    counter<=counter+1;
                end else begin
                    data<=0;
                end
            end
        end
    end

endmodule
