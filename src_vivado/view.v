`timescale 1ns / 1ps

// view(.clk_25mhz(),.clk_1s(),.reset(),.r(),.g(),.b(),.hs(),.vs(),.busy(),.data(),.pg_up(),.pg_down());

// append mode

module view(
    // interaction with hardware
    input clk_50mhz,            // data
    input clk_25mhz,            // I/O
    input clk_1s,               // cursor
    input reset,                // reset
    output wire [3:0] r,g,b,    // rgb
    output wire hs,vs,          // horizontal and vertical synchronization

    // interaction with models and controllers
    input wire [7:0] cmd,       // command
    input wire [5:0] data       // data for appending: 0 for nothing input
);
    // cmd
    wire busy,pg_up,pg_down,backspace,breakline;
    assign busy = cmd[0];
    assign pg_up = cmd[1];
    assign pg_down = cmd[2];
    assign backspace = cmd[3];
    assign breakline = cmd[4];
    assign reserved = cmd[7];

    // vga
    wire [9:0] x;               // pixel:0-799 char: 16*50 = 800
    wire [8:0] y;               // pixel:0-524 char: 16*32 = 512
    wire video;
    reg px;                     // 0 for black,1 for white


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

    vga mv(
        .clk_25mhz(clk_25mhz),
        .reset(reset),
        .y(y),.x(x),
        .rdn(video),
        .r(r),.g(g),.b(b),
        .hs(hs),.vs(vs),
        .px(px)
        );
    
    // rom : storage the font table
    reg [9:0] rom_addr;
    wire [0:15] rom_data;
    font_rom mrom(.clka(clk_25mhz),.addra(rom_addr),.douta(rom_data),.ena(1'b1));

    // v for virtual; d for display; m for memory
    parameter font_size = 16;                               // the size of a character
    parameter col_count = 36;                               // number of characters in a line
    parameter line_count = 28;                              // number of lines
    parameter d_char_count = col_count*line_count;          // number of characters
    parameter m_char_count = d_char_count*4;                // number of characters in memory
    wire [31:0] v_index_x,v_index_y;                        // indices
    wire [31:0] d_index_x,d_index_y,offset_x,offset_y;      // indices
    wire [31:0] d_addr,v_addr,m_addr;                       // linear addrress of character
    wire [31:0] d_cursor,m_cursor;                          // cursor
    reg  [31:0] v_cursor;                                   // virtual cursor
    reg  [31:0] d_base_line;                                // base number of line
    wire [31:0] d_base,m_base;                              // base number of chars
    reg  [5:0]  m_ascii_ram [0:m_char_count-1];             // storage the ascii code
    reg  [11:0] m_write_addr;
    reg         m_write_en;
    reg  [5:0]  m_write_data;

    initial begin
        v_cursor <= 32'b0;
        d_base_line <= 32'b0;
    end

    // display address: current position in screen
    assign offset_x = x%font_size;                          // the offset of x
    assign offset_y = y%font_size;                          // the offset of y
    assign d_index_x = x/font_size;                         // the index of x
    assign d_index_y = y/font_size;                         // the index of y
    assign d_cursor = v_cursor-d_base;                      // display cursor
    assign d_addr = v_addr-d_base;                     
    assign d_base = d_base_line*col_count;                  // display [d_base,d_base+d_char_count] of virtual address

    // virtual address: virtual or logical position
    assign v_index_x = d_index_x;
    assign v_index_y = d_base_line + d_index_y;
    assign v_addr = v_index_y*col_count + v_index_x;

    // memory address: acutal address in memory
    assign m_addr = v_addr%m_char_count;                     // !! memory map : scroll memory
    assign m_cursor = v_cursor%m_char_count;                 // !! memory map : scroll memory

    // remove
    reg [31:0] remove_start,remove_end;
    reg [1:0] clear;

    // setup the pixel
    reg s_font,s_cursor;

    always @ (posedge clk_1s) begin
        if(busy) begin
            s_cursor <= 1'b0;
        end else begin
            s_cursor <= ~s_cursor;
        end
    end

    // handle the ram
    always @ (posedge clk_50mhz) begin
        if(reset) begin
            v_cursor <= 32'd0;
            d_base_line <= 32'd0;
            clear <= 0;
            remove_start <= 0;
            remove_end <= m_char_count-1;
            m_write_en <= 0;
        end else begin
            if(clk_25mhz) begin
                if(data!=8'd0) begin
                    m_write_addr <= m_cursor;
                    m_write_data <= data;
                    m_write_en   <= 1;
                    v_cursor <= v_cursor+32'd1;
                end else if(breakline) begin
                    remove_start <= v_cursor;
                    remove_end <= (v_cursor/col_count)*col_count+col_count;
                    v_cursor <= (v_cursor/col_count)*col_count+col_count;
                end else if(backspace && v_cursor>32'd0) begin
                    v_cursor <= v_cursor-32'd1;
                end else if(pg_up && d_base_line>=32'd1) begin
                    d_base_line <= d_base_line - 32'd1;
                end else if(pg_down) begin
                    d_base_line <= d_base_line + 32'd1;
                end else begin
                    // clear
                    if(remove_start<remove_end) begin
                        m_write_addr <= remove_start;
                        remove_start <= remove_start+1;
                        m_write_data <= 0;
                        m_write_en   <= 1;
                    end else begin
                        m_write_addr <= m_cursor;
                        m_write_data <= 0;
                        m_write_en   <= 1;
                        remove_start <= 0;
                        remove_end <= 0;
                    end
                end

                // roll a line
                if(d_cursor==d_char_count) begin
                    d_base_line <= d_base_line + 32'd1;
                end

                // setup the pixel
                if(y>line_count*font_size) begin
                    s_font <= 1'b0;
                end else begin
                    s_font <= rom_data[offset_x];
                end
                if(video && x>=0 && x<=col_count*font_size && y>=0 && y<=line_count*font_size)
                    px <= (s_cursor && offset_x==32'd0 && d_addr == d_cursor) || s_font;
                else
                    px <= 0;
            end else begin
                // write ram
                if(m_write_en) begin
                    m_ascii_ram[m_write_addr] <= m_write_data;
                    m_write_en <= 0;
                end
                
                // read the ram and rom
                rom_addr <= (v_addr<v_cursor?m_ascii_ram[m_addr]:6'd0)*font_size+ offset_y;
            end
        end
    end
endmodule