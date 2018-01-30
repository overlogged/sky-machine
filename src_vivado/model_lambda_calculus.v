`timescale 1ns / 1ps

// model_lambda_calculus ml(.clk_25mhz(),.reset(),.data_in(),.data_out());

module model_lambda_calculus(
    input wire clk_25mhz,        
    input wire clk_io,
    input wire reset,               // reset
    input wire [7:0] data_in,       // input: byte stream
    output reg [5:0] data_out       // output: output stream
);
    // ast
    parameter ast_abstraction = 8'd3;
    parameter ast_application = 8'd4;
    parameter ast_item = 8'd5;
    parameter ast_error = 8'hff;

    parameter no_more_item = 12'hfff;

    parameter max_identifier = 8;
    parameter max_buffer_size = 4096;
    parameter max_str_buffer = 256;
    parameter max_symbol_size = 128;
    parameter max_stack_size = 256;

    reg [31:0] ast_table_ram[0:max_buffer_size-1];          // [31:20] index2; [19:0] index1; [7:0] type;
    reg [23:0] symbol_table_ram[0:max_symbol_size-1];       // symbol table
    reg [47:0] str_table_ram[0:max_buffer_size-1];          // string table
    reg [11:0] ast_pos,str_pos,symbol_pos,buf_pos;
    reg [5:0] str_buffer[0:max_str_buffer-1];
    
    // varaiables 
    reg  [11:0] var[1:16]; 
    reg  [31:0] var_ast[1:3];             

    // stacks
    reg [7:0] call_stack[0:max_stack_size-1];
    reg [11:0] var_stack[0:max_stack_size-1];
    reg [11:0] call_stack_top,var_stack_top;

    wire [5:0] str_var4_15;
    assign str_var4_15  =   (var[4]==0)?str_io[5:0]:
                            (var[4]==1)?str_io[11:6]:
                            (var[4]==2)?str_io[17:12]:
                            (var[4]==3)?str_io[23:18]:
                            (var[4]==4)?str_io[29:24]:
                            (var[4]==5)?str_io[35:30]:
                            (var[4]==6)?str_io[41:36]:
                            (var[4]==7)?str_io[47:42]:6'b0;

    // handle with ram
    reg [11:0] ast_read_addr,ast_write_addr;
    reg ast_en_w,ast_en_r,ast_en_wr;
    reg [31:0] read_ast,write_ast;

    reg [11:0] str_addr;
    reg str_en_w,str_en_r;
    reg [47:0] str_io;

    // lexer & parser
    wire [7:0] data_step;
    wire [15:0] token_stream;
    reg [11:0] index;
    wire [11:0] c_ast,c_str;
    wire [31:0] data_ast;
    wire [47:0] data_str;
    reg lexer_reset,parser_reset;
    wire [11:0] main_item;


    // parser
    model_parser mp(
        .clk_25mhz(clk_25mhz),
        .clk_io(clk_io),
        .reset(reset|parser_reset),
        .data_in(token_stream),
        .data_step(data_step),
        .index(index),
        .c_ast(c_ast),.c_str(c_str),
        .main(main_item),
        .data_ast(data_ast),
        .data_str(data_str));

    model_lexer ml(
        .clk_25mhz(clk_25mhz),
        .clk_io(clk_io),
        .reset(reset|lexer_reset),
        .data_in(data_in),
        .data_step(data_step),
        .data_out(token_stream));


    // code
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

    // states
    reg [7:0] state;
    parameter state_start_lexer = 0;
    parameter state_start_parser = 1;
    parameter state_start_porter = 2;
    parameter state_porter_first = 3;
    parameter state_porter = 4;
    parameter state_porter_str = 5;
    parameter state_porter_str_symbol = 6;
    parameter state_start_interpreter = 7;
    parameter state_eval = 8;
    parameter state_eval_begin = 9;
    parameter state_ast_application1 = 10;
    parameter state_ast_application2 = 11;
    parameter state_ast_application2_body = 12;
    parameter state_ast_application3 = 13;
    parameter state_ast_application3_body = 14;
    parameter state_ast_application4 = 15;
    parameter state_ast_abstraction = 16;
    parameter state_ast_item = 17;
    parameter state_error = 18;
    parameter state_end_interpret = 19;
    parameter state_show_expr = 20;
    parameter state_show_expr_body = 21;
    parameter state_show_application1 = 22;
    parameter state_show_application2 = 23;
    parameter state_show_abstraction1 = 24;
    parameter state_show_abstraction2 = 25;
    parameter state_show_str = 26;
    parameter state_output = 27;
	 parameter state_porter_str_symbol_body = 28;
	 
    // for debug
    // integer i=0;

    always @ (posedge clk_25mhz) begin
        if(reset) begin
            // restart
            ast_pos <= 0;
            symbol_pos <= 0;
            str_pos <= 0;

            // prepare for next
            data_out <= 0;
            buf_pos <= 0;
            var[16] <=0;

            state <= state_start_lexer;

            call_stack_top <= 0;
            var_stack_top <= 0;

            parser_reset <= 0;
            lexer_reset <= 0;

            index <= 12'd0;

            ast_en_r<= 0;
            ast_en_w<= 0;
            ast_en_wr<=0;
            str_en_w<=0;
            str_en_r<=0;
            
        end else begin
            if(clk_io) begin
                data_out <= code_null;
                if(ast_en_w) begin
                    ast_table_ram[ast_write_addr] <= write_ast;
                    ast_en_w <= 0;
                end
                if(ast_en_r) begin
                    read_ast <= ast_table_ram[ast_read_addr];
                    ast_en_r <= 0;
                end
                if(ast_en_wr) begin
                    ast_table_ram[ast_write_addr] <= ast_table_ram[ast_read_addr];
                    ast_en_wr <= 0;
                end

                if(str_en_r) begin
                    str_io <= str_table_ram[str_addr];
                    str_en_r <= 0;
                end else if(str_en_w) begin
                    str_table_ram[str_addr] <= str_io;
                    str_en_w <= 0;
                end
            end else begin
                case(state)

                // start lexer
                state_start_lexer:
                begin
                    if(data_in) begin
                        lexer_reset <= 1;
                        parser_reset <= 1;
                        state <= state_start_parser;
                    end
                end

                // start parser
                state_start_parser:
                begin
                    lexer_reset <= 0;
                    parser_reset <= 0;
                    if(token_stream) begin
                        state <= state_start_porter;
                    end
                end

                // start porter
                // var[13] tmp string index
                state_start_porter:
                begin
                    if(data_ast) begin
                        var[1] <= str_pos;
                        var[13] <= str_pos;
                        state <= state_porter_first;
                    end
                end

                // symbol binding
                state_porter_first:
                begin
                    var[13] <= var[13]+1;
                    str_addr <= var[13];
                    str_io <= data_str;
                    str_en_w <= 1;
                    symbol_table_ram[symbol_pos][23:12] <= var[13];
                    state <= state_porter;
                end

                // porter
                state_porter:
                begin
                    if(index<c_ast) begin
                        if(data_ast[7:0]) begin    

                            // write a new ast item
                            ast_write_addr <= ast_pos+index;
                            ast_en_w <= 1;
    
                            case(data_ast[7:0])
                            
                            ast_error:
                            begin
                                state<=state_error;
                            end

                            ast_item:
                            begin
                                write_ast <= data_ast;

                                var_stack[var_stack_top] <= index;
                                var_stack_top <= var_stack_top+1;
                                
                                str_addr <= str_pos;
                                str_en_r <= 1;
                                index <= data_ast[19:8];
                                state <= state_porter_str;
                            end

                            ast_abstraction:
                            begin
                                write_ast[19:0] <= data_ast[19:0];
                                write_ast[31:20] <= data_ast[31:20] + ast_pos;

                                var_stack[var_stack_top] <= index;
                                var_stack_top <= var_stack_top+1;
                                
                                index <= data_ast[19:8];
                                str_addr <= str_pos;
                                str_en_r <= 1;
                                state <= state_porter_str;
                            end

                            ast_application:
                            begin
                                write_ast[7:0] <= ast_application;
                                write_ast[19:8] <= data_ast[19:8]+ast_pos;
                                write_ast[31:20] <= data_ast[31:20]+ast_pos;
                                
                                index <= index+1;
                            end

                            endcase
                        end
                    end else begin
                        index <= 0;
                        ast_pos <= ast_pos+c_ast;
                        if(main_item!=no_more_item) begin
                            var[2] <= ast_pos+main_item;
                            state <= state_start_interpreter;
                        end else begin
                            str_buffer[4'd0]<=code_space;
                            buf_pos <=1;
                            state <= state_output;
                        end
                    end
                end

                // copy str
                // copy str
                // str_addr index
                state_porter_str:
                begin
                    if(data_str[7:0]) begin
                        if(str_io!=data_str && str_addr<var[13]) begin
                            str_addr <= str_addr+1;
                            str_en_r <= 1;
                        end else if(str_io==data_str) begin
                            // found
                            write_ast[19:8] <= str_addr;
                            ast_en_w <= 1;

                            index <= var_stack[var_stack_top-1]+1;
                            var_stack_top <= var_stack_top-1;
                            state <= state_porter;                    
                        end else begin
                            // not found: try symbol context
                            var[1] <= 0;
                            str_en_r <= 1;
                            state <= state_porter_str_symbol;
                        end
                    end
                end
                state_porter_str_symbol:
                begin
                    str_addr <= symbol_table_ram[var[1]][23:12];
                    str_en_r <= 1;
                    state<= state_porter_str_symbol_body;
                end

                state_porter_str_symbol_body:
                begin
                    if(str_io!=data_str && var[1]<symbol_pos) begin
                        var[1] <= var[1]+1;
                        state <= state_porter_str_symbol;
                    end else begin
                        ast_en_w <= 1;
                        if(var[1]==symbol_pos) begin
                            // not found
                            var[13] <= var[13]+1;

                            str_addr <= var[13];
                            str_en_w <= 1;
                            str_io <= data_str;
                            
                            write_ast[19:8] <= var[13];
                        end else begin
                            write_ast[19:8] <= symbol_table_ram[var[1]][23:12];
                        end
                        index <= var_stack[var_stack_top-1]+1;
                        var_stack_top <= var_stack_top-1;
                        state <= state_porter; 
                    end
                end

                // start interpreter
                // var[2]: first expression
                // var[3]: expr to eval
                state_start_interpreter:
                begin
                    // for debug
                    /*for(i=0;i<ast_pos;i=i+1) begin
                        $display("%d:%s %d %d",i,ast_table_ram[i][7:0]==3?"abstract":ast_table_ram[i][7:0]==4?"apply":"item",ast_table_ram[i][19:8],ast_table_ram[i][31:20]); 
                    end*/

                    // code
                    str_pos<=var[13];
                    call_stack[call_stack_top]<= state_end_interpret;
                    call_stack_top<=1;
                    var_stack_top<=0;
                    var[3] <= var[2];
                    state <= state_eval;
                end

                // evaluate an expression
                // var[3]: expr to eval
                // var[14]: string index
                // var[8]: return new index
                state_eval:
                begin
                    ast_en_r <= 1;
                    ast_read_addr <= var[3];
                    state <= state_eval_begin;
                end

                state_eval_begin:
                begin
                    case(read_ast[7:0])

                    ast_item:
                    begin
                        var[4] <= 0;                            // counter
                        var[14] <= read_ast[19:8];              // string index
                        state <= state_ast_item;                // return var[8]:sym.eval() or initial identifier
                    end

                    ast_abstraction:
                    begin
                        var_stack[var_stack_top]<= read_ast[19:8];              // first
                        var_stack_top <= var_stack_top+1;
                        var[3] <= read_ast[31:20];                              // eval the second
                        call_stack[call_stack_top] <= state_ast_abstraction;    // return in ast abstraction
                        call_stack_top <= call_stack_top+1;
                        state<=state_eval;                                      
                    end

                    ast_application:
                    begin
                        // eval first;eval second;application
                        // eval first
                        var[3] <= read_ast[19:8];
                        var_stack[var_stack_top] <= read_ast[31:20];
                        var_stack_top <= var_stack_top+1;
                        call_stack[call_stack_top] <= state_ast_application1;
                        call_stack_top <= call_stack_top+1;
                        state <= state_eval;
                    end

                    endcase
                end

                // var[3]: expr index
                // var[8]: first.eval()
                // stack[0]: second -> first.eval()
                state_ast_application1:
                begin
                    var[3] <= var_stack[var_stack_top-1];
                    var_stack[var_stack_top-1] <= var[8];
                    call_stack[call_stack_top] <= state_ast_application2;
                    call_stack_top <= call_stack_top+1;
                    state <= state_eval;
                end

                
                // stack[0]:first.eval()
                // var[8]:second.eval()
                state_ast_application2:
                begin
                    ast_read_addr <= var_stack[var_stack_top-1];
                    ast_en_r <= 1;
                    state <= state_ast_application2_body;
                end

                state_ast_application2_body:
                begin
                    if(read_ast[7:0]==ast_abstraction) begin
                        var_stack[var_stack_top-1] <= read_ast[31:20];
                        var_stack[var_stack_top] <= read_ast[31:20];
                        var[10] <= var_stack_top;
                        var_stack_top <= var_stack_top+1;
                        var[9] <= read_ast[19:8];            // variable
                        state <= state_ast_application3;
                    end else begin
                        // can't eval,return
                        state <= state_ast_application4;
                    end
                end

                // var[10]: store the stack_top
                // var[8]: replace item
                // var[9]: string index
                // search
                state_ast_application3:
                begin
                    if(var_stack_top>var[10]) begin
                        ast_read_addr <= var_stack[var_stack_top-1];
                        ast_en_r <= 1;
                        state <= state_ast_application3_body;
                    end else begin
                        // after replace:eval again
                        var[3] <= var_stack[var_stack_top-1];
                        var_stack_top <= var_stack_top-1;
                        state <= state_eval;                                // return in eval
                    end
                end

                // search and replace
                state_ast_application3_body:
                begin
                    case(read_ast[7:0])
                    
                    ast_item:
                    begin
                        if(var[9]==read_ast[19:8]) begin
                            var_stack[var_stack_top-1] <= ast_read_addr;
                            ast_write_addr <= ast_read_addr;
                            ast_read_addr <= var[8];
                            ast_en_wr <= 1;
                        end else begin
                            var_stack_top <= var_stack_top-1;
                        end
                        state <= state_ast_application3;
                    end

                    ast_abstraction:
                    begin
                        var_stack[var_stack_top-1] <= read_ast[31:20];
                        state <= state_ast_application3;
                    end

                    ast_application:
                    begin
                        var_stack[var_stack_top-1] <= read_ast[19:8];
                        var_stack[var_stack_top] <= read_ast[31:20];
                        var_stack_top <= var_stack_top + 1;
                        state <= state_ast_application3;
                    end

                    endcase

                end

                // no eval or no replace
                state_ast_application4:
                begin
                    ast_pos <= ast_pos+1;
                    ast_write_addr <= ast_pos;
                    write_ast[7:0] <= ast_application;
                    write_ast[19:8] <= var_stack[var_stack_top-1];
                    write_ast[31:20] <= var[8];
                    ast_en_w <= 1;

                    var[8] <= ast_pos;
                    state <= call_stack[call_stack_top-1];
                    call_stack_top <= call_stack_top-1;
                    var_stack_top <= var_stack_top-1;
                end

                // var[3]: expr index
                // var[8]: return item
                // stack[0]:string index
                state_ast_abstraction:
                begin
                    ast_pos <= ast_pos+1;
                    ast_write_addr <= ast_pos;
                    write_ast[7:0] <= ast_abstraction;
                    write_ast[19:8] <= var_stack[var_stack_top-1];    // string index
                    write_ast[31:20] <= var[8];
                    ast_en_w<=1;
                    var[8] <= ast_pos;
                    state <= call_stack[call_stack_top-1];                      // return
                    var_stack_top <= var_stack_top-1;
                    call_stack_top <= call_stack_top-1;
                end

                // var[3]:expr index
                // var[4]:counter
                // var[8]:return item
                state_ast_item:
                begin
                    if(var[4]<symbol_pos && symbol_table_ram[var[4]][23:12]==var[14]) begin
                        // found
                        var[3] <= symbol_table_ram[var[4]][11:0];                   // eval the symbol
                        state <= state_eval;                                        // return in eval
                    end else if(var[4]==symbol_pos) begin
                        // not found
                        ast_pos <= ast_pos+1;
                        ast_write_addr <= ast_pos;
                        write_ast <= read_ast;
                        ast_en_w <= 1;
                        var[8] <= ast_pos;
                        state <= call_stack[call_stack_top-1];                      // return
                        call_stack_top <= call_stack_top-1;
                    end else begin
                        var[4] <= var[4]+1;
                    end                    
                end

                // error 
                state_error:
                begin
                    str_buffer[4'd0] <=  code_a+"e"-"a";
                    str_buffer[4'd1] <=  code_a+"r"-"a";
                    str_buffer[4'd2] <=  code_a+"r"-"a";
                    str_buffer[4'd3] <=  code_a+"o"-"a";
                    str_buffer[4'd4] <=  code_a+"r"-"a";
                    buf_pos <= 5;
                    state <= state_output;
                end

                // output: output eval result
                // var[8]: result
                state_end_interpret:
                begin
                    symbol_table_ram[symbol_pos][11:0] <= var[8];
                    symbol_pos <= symbol_pos+1;
                    call_stack[call_stack_top] <= state_output;
                    call_stack_top <= call_stack_top+1;
                    state <= state_show_expr;
                end
                // var[8]: item index
                state_show_expr:
                begin
                    ast_read_addr <= var[8];
                    ast_en_r <= 1;
                    state<=state_show_expr_body;
                end

                state_show_expr_body:
                begin
                    case(read_ast[7:0])
                    
                    ast_item:
                    begin
                        var[4]<=0;
                        str_addr<=read_ast[19:8];
                        str_en_r<=1;
                        state<=state_show_str;
                    end

                    ast_abstraction:
                    begin
                        str_buffer[buf_pos+0] <= code_lbrace;
                        str_buffer[buf_pos+1] <= code_lambda;
                        buf_pos <= buf_pos+2;

                        str_addr <= read_ast[19:8];
                        str_en_r <= 1;
                        var_stack[var_stack_top] <= read_ast[31:20];
                        var_stack_top <= var_stack_top+1;
                        var[4] <= 0;

                        call_stack[call_stack_top] <= state_show_abstraction1;
                        call_stack_top <= call_stack_top+1;
                        state <= state_show_str;
                    end
                    
                    ast_application:
                    begin
                        str_buffer[buf_pos] <= code_lbrace;
                        buf_pos <= buf_pos+1;

                        var[8] <= read_ast[19:8];
                        var_stack[var_stack_top] <= read_ast[31:20];
                        var_stack_top <= var_stack_top+1;
                        call_stack[call_stack_top] <= state_show_application1;
                        call_stack_top <= call_stack_top+1;
                        state <= state_show_expr;
                    end

                    default:state <= state_error;

                    endcase 
                end

                state_show_application1:
                begin
                    var[8]<=var_stack[var_stack_top-1];
                    var_stack_top <= var_stack_top-1;
                    call_stack[call_stack_top] <= state_show_application2;
                    call_stack_top <= call_stack_top+1;
                    str_buffer[buf_pos] <= code_space;
                    buf_pos <= buf_pos+1;
                    state<=state_show_expr;
                end

                state_show_application2:
                begin
                    str_buffer[buf_pos] <= code_rbrace;
                    buf_pos <= buf_pos+1;
                    state <= call_stack[call_stack_top-1];
                    call_stack_top <= call_stack_top-1;
                end

                state_show_abstraction1:
                begin
                    str_buffer[buf_pos] <= code_dot;
                    buf_pos <= buf_pos+1;
                    var[8] <= var_stack[var_stack_top-1];
                    var_stack_top <= var_stack_top-1;
                    call_stack[call_stack_top] <= state_show_abstraction2;
                    call_stack_top <= call_stack_top+1;
                    state<=state_show_expr;
                end

                state_show_abstraction2:
                begin
                    str_buffer[buf_pos] <= code_rbrace;
                    buf_pos <= buf_pos+1;
                    state <= call_stack[call_stack_top-1];
                    call_stack_top <= call_stack_top-1;
                end

                // var[15]:string index
                // var[4]:counter
                state_show_str:
                begin
                    if(var[4]<max_identifier && str_var4_15) begin
                        str_buffer[buf_pos] <=  str_var4_15;
                        buf_pos <= buf_pos+1;
                        var[4] <= var[4]+1;
                    end else begin
                        var[4] <= 0;
                        state <= call_stack[call_stack_top-1];
                        call_stack_top <= call_stack_top-1;
                    end
                end

                // output
                state_output:
                begin
                    if(var[16]<buf_pos) begin
                        // for debug
                        // $display("%c",str_buffer[var[16]]);

                        data_out <= str_buffer[var[16]];
                        var[16] <= var[16]+1;
                    end else if(var[16]==buf_pos) begin
                        data_out <= code_end;
                        var[16] <= var[16]+1;
                    end else begin
                        // prepare for next
                        data_out <= 0;
                        buf_pos <= 0;
                        var[16] <=0;

                        state <= state_start_lexer;

                        call_stack_top <= 0;
                        var_stack_top <= 0;

                        parser_reset <= 0;
                        lexer_reset <= 0;

                        index <= 12'd0;

                        ast_en_r<= 0;
                        ast_en_w<= 0;
                        ast_en_wr<=0;
                        str_en_w<=0;
                        str_en_r<=0;
                    end 
                end

                default:state<=state_error;

                endcase
            end
        end
    end

endmodule