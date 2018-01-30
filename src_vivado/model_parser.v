`timescale 1ns / 1ps

// model_parser mp(.clk_25mhz(),.reset(),.data_in(),.data_step(),.index(),.c_ast(),.c_str(),.main(),.data_ast(),.data_str());
module model_parser(
    input wire clk_25mhz,               // clock
    input wire clk_io,                  // io clock
    input wire reset,                   // reset
    input wire [15:0] data_in,          // input:  token stream [7:0] [15:8]
    output reg [7:0] data_step,         // output: the steps of the read pointer 

    input wire [11:0] index,            // index
    output reg [11:0] c_ast,c_str,      // count of ast and str table
    output reg [11:0] main,             // output: main item
    output reg [31:0] data_ast,         // output: ast_item
    output reg [47:0] data_str          // output: string
);

    parameter token_null = 0;
    parameter token_identifier = 65;
    parameter token_lbrace = 66;
    parameter token_rbrace = 67;
    parameter token_lambda = 68;
    parameter token_dot = 69;
    parameter token_eq = 70;
    parameter token_set = 71;
    parameter token_end = 72;
    
    parameter state_ready = 0;
    parameter state_first = 1;
    parameter state_ready_eq = 2;
    parameter state_error = 3;
    parameter state_strcpy = 4;
    parameter state_strcpy_loop = 5;
    parameter state_expr = 6;
    parameter state_expr_brace = 7;
    parameter state_expr_lambda1 = 8;
    parameter state_expr_lambda2 = 9;
    parameter state_expr_identifier = 10;
    parameter state_expr_apply1 = 11;
    parameter state_expr_apply2 = 12;

    parameter max_identifier = 8;
    parameter max_buffer_size = 128;
    parameter max_stack_size = 128;

    parameter ast_abstraction = 8'd3;
    parameter ast_application = 8'd4;
    parameter ast_item = 8'd5;
    parameter ast_error = 8'hff;

    parameter no_more_item = 12'hfff;
    // state
    reg [11:0] state;
    
    reg [11:0] var[1:16];
    reg [11:0] brace_count;

    // tables
    reg [47:0] str_io;
    reg [31:0] ast_io;
    reg ast_en,str_en;
    reg [11:0] str_addr;
    reg [11:0] ast_addr;

    reg [47:0] string_table[0:max_buffer_size-1];                       // char
    reg [31:0] ast_table[0:max_buffer_size-1];                          // [31:20] index2; [19:8] index1; [7:0] type;

    // stacks
    reg [11:0] call_stack[0:max_stack_size-1];     // call stack
    reg [11:0] var_stack[0:max_stack_size-1];      // varaibles stack
    reg [31:0] ast_stack[0:max_stack_size-1];      // ast item stack
    reg [11:0] call_stack_top,var_stack_top,ast_stack_top;

    // for debug
    wire [7:0] token1,token2;
    assign token1 = data_in[7:0];
    assign token2 = data_in[15:8];
    // integer i=0;

    always @ (posedge clk_25mhz) begin
        if(reset) begin
            // for debug
            // i=0;

            data_step <= 0;
            c_str <= 0;
            c_ast <= 0;
            main <= no_more_item;

            state <= state_ready;
            call_stack_top <= 0;
            var_stack_top <= 0;
            ast_stack_top <= 0;
            brace_count <= 0;

            var[1]<=0;
            var[2]<=0;
            var[3]<=0;
            var[4]<=0;
            var[5]<=0;
            var[6]<=0;
            var[7]<=0;
            var[8]<=0;
            var[9]<=0;
            var[10]<=0;
            var[11]<=0;
            var[12]<=0;
            var[13]<=0;
            var[14]<=0;
            var[15]<=0;
            var[16]<=0;

            ast_addr <= 0;
            str_addr <= 0;
            ast_io <= 32'd0;
            str_io <= 48'd0;
            ast_en <= 1;
            str_en <= 1;
        end else begin
            if(clk_io) begin
                data_ast <= (state==state_ready && index<c_ast)?ast_table[index]:32'd0;
                data_str <= (state==state_ready && index<c_str)?string_table[index]:48'd0;
                
                if(ast_en) begin
                    ast_table[ast_addr] <= ast_io;
                    ast_en <= 0;
                end

                if(str_en) begin
                    string_table[str_addr] <= str_io;
                    str_en <= 0;
                end

            end else begin
                case(state)
                    /*
                    * used variables
                    *      var[1] var[2]: for calling strcpy
                    *      var[6]: storage the query data
                    * specification
                    *      start parser
                    */
                    state_ready:
                    begin
                        // done
                        if(c_ast) begin
                            data_step <= 0;
                            main <= var[4];

                            // for debug
                            /*
                            if(i==0) begin
                                for(i=0;i<c_ast;i=i+1) begin
                                    $display("%d:%s %d %d",i,ast_table[i][7:0]==3?"abstract":ast_table[i][7:0]==4?"apply":ast_table[i][7:0]==16?"nothing":"item",ast_table[i][19:8],ast_table[i][31:20]);                        
                                end
                                $display("main:%d",var[4]);
                            end*/
                        end else begin
                            if(data_in[7:0]) begin
                                data_step<=0;
                                state <= state_first;
                            end
                        end
                    end

                    state_first:
                    begin
                        if(data_in[7:0]&&data_in[15:8]) begin                    
                            if(data_in[7:0]==token_set && data_in[15:8]==token_identifier) begin
                                data_step <= 2;
                                call_stack[call_stack_top] <= state_ready_eq;
                                call_stack_top <= call_stack_top + 1;
                                state <= state_strcpy;                                  // strcpy
                            end else begin
                                data_step <= 0;
                                c_str <= c_str+1;
                                call_stack[call_stack_top] <= state_ready;              // after calling: go to end parse
                                call_stack_top <= call_stack_top+1;
                                state <= state_expr;                                    // expression
                            end   
                        end
                    end

                    state_ready_eq:
                    begin
                        if(data_in[7:0]) begin
                            if(data_in[7:0]==token_eq) begin
                                data_step <= 1;
                                call_stack[call_stack_top] <= state_ready;      // after calling: go to ready
                                call_stack_top <= call_stack_top+1;
                                state <= state_expr;
                            end else begin
                                state <= state_error;
                            end
                        end
                    end

                    state_error:
                    begin
                        ast_io[7:0] <= ast_error;
                        ast_addr <= 0;
                        ast_en <= 1;
                        state <= state_ready;
                        data_step <= 0;                    
                    end

                    /*
                    * used variables
                    *      var[1]: count for copy, should be reseted before calling                     
                    *      var[2]: index in string table(as return)
                    * specification
                    *      copy a string from lexical stream, stop at other tokens
                    */
                    state_strcpy:
                    begin
                        data_step <= 0;                             // don't move
                        var[1] <= 0;                                // index for copy
                        var[2] <= c_str;                            // index in string table
                        c_str <= c_str + 1;                         // index in string table
                        state <= state_strcpy_loop;                 // goto loop
                    end

                    state_strcpy_loop:
                    begin
                        if(var[1]<max_identifier) begin
                            if(data_in[7:0]) begin
                                if(data_in[7:0]<=8'd64) begin
                                    data_step <= 8'd1;
                                    case(var[1])
                                    0:str_io[5:0] <= data_in[5:0];
                                    1:str_io[11:6] <= data_in[5:0];
                                    2:str_io[17:12] <= data_in[5:0];
                                    3:str_io[23:18] <= data_in[5:0];
                                    4:str_io[29:24] <= data_in[5:0];
                                    5:str_io[35:30] <= data_in[5:0];
                                    6:str_io[41:36] <= data_in[5:0];
                                    7:str_io[47:42] <= data_in[5:0];
                                    endcase
                                end else begin
                                    data_step <= 8'd0;
                                    case(var[1])
                                    0:str_io[5:0] <= 6'd0;
                                    1:str_io[11:6] <= 6'd0;
                                    2:str_io[17:12] <= 6'd0;
                                    3:str_io[23:18] <= 6'd0;
                                    4:str_io[29:24] <= 6'd0;
                                    5:str_io[35:30] <= 6'd0;
                                    6:str_io[41:36] <= 6'd0;
                                    7:str_io[47:42] <= 6'd0;
                                    endcase
                                end
                                var[1] <= var[1]+1;
                            end
                        end else begin
                            str_addr <= var[2];
                            str_en <= 1;
                            data_step <= 0;
                            state <= call_stack[call_stack_top-1];  // return
                            call_stack_top <= call_stack_top-1;
                        end
                    end



                    /*
                    * used variables
                    *      var[1] var[2]: for calling strcpy
                    *      var[4]: index in ast table(as return); var[4]==no_more_item means no more item
                    * specification
                    *      get a expr,and store the id into expression column     
                    */
                    state_expr:
                    begin
                        if(data_in[7:0] && data_in[15:8]) begin
                            data_step <= 1;
                            var[4] <= c_ast;
                            case(data_in[7:0])
                                token_null:
                                begin
                                    var[4] <= no_more_item;
                                    state <= call_stack[call_stack_top-1];                  // return
                                    call_stack_top <= call_stack_top-1;
                                end
                                
                                token_end:
                                begin
                                    var[4] <= no_more_item;

                                    ast_io[7:0] <= ast_item;
                                    ast_io[19:8] <= c_str;
                                    ast_addr <= c_ast;
                                    ast_en <= 1;
                                    c_ast <= c_ast+1;

                                    str_io  <= 1;
                                    str_en <= 1;
                                    str_addr <= c_str;
                                    c_str <= c_str+1;

                                    state <= call_stack[call_stack_top-1];                  // return
                                    call_stack_top <= call_stack_top-1;
                                end
                                
                                token_lbrace:
                                begin
                                    call_stack[call_stack_top] <= state_expr_brace;         // after calling: go to brace
                                    call_stack_top <= call_stack_top+1;
                                    brace_count <= brace_count+1;
                                end

                                token_rbrace:
                                begin
                                    if(brace_count>=1) begin
                                        var[4] <= no_more_item;
                                        brace_count <= brace_count-1;
                                        state <= call_stack[call_stack_top-1];               // return
                                        call_stack_top <= call_stack_top-1;
                                    end else begin
                                        state <= state_error;
                                    end
                                end

                                token_identifier:
                                begin
                                    c_ast <= c_ast+1;
                                    call_stack[call_stack_top] <= state_expr_identifier;     // after calling: go to identifier
                                    call_stack_top <= call_stack_top+1;
                                    state <= state_strcpy;
                                end

                                token_lambda:
                                begin
                                    c_ast <= c_ast+1;
                                    if(data_in[15:8]==token_identifier) begin
                                        data_step <= 2;
                                        call_stack[call_stack_top] <= state_expr_lambda1;
                                        call_stack_top <= call_stack_top+1;
                                        state <= state_strcpy;
                                    end else begin
                                        state <= state_error;
                                    end
                                end
                            endcase
                        end
                    end

                    state_expr_brace:
                    begin                    
                        data_step <= 0;                                             // use var[4] as return value
                        state <= state_expr_apply1;                                 // complete a expr
                    end

                    state_expr_lambda1:
                    begin
                        if(data_in[7:0]) begin
                            if(data_in[7:0]==token_dot) begin                      
                                data_step <= 1;
                                // var[4]
                                ast_stack[ast_stack_top] <= {12'd0,var[2],ast_abstraction}; // type = abstraction;index1 = var[2]: index in string table
                                ast_stack_top <= ast_stack_top+1;
                                call_stack[call_stack_top] <= state_expr_lambda2;       // after calling: go to lambda2
                                call_stack_top <= call_stack_top+1;
                                var_stack[var_stack_top] <= var[4];                     // push var[4]
                                var_stack_top <= var_stack_top+1;
                                state <= state_expr;                                    // get a expression
                            end else begin
                                state <= state_error;
                            end
                        end
                    end
                    
                    state_expr_lambda2:
                    begin
                        data_step <= 0;
                        ast_io[19:0]  <= ast_stack[ast_stack_top-1][19:0];
                        ast_stack_top <= ast_stack_top-1;
                        ast_io[31:20] <= var[4];                        // index2 = var[4]: index in ast table
                        ast_en <= 1;
                        ast_addr <= var_stack[var_stack_top-1]; 
                        var[4] <= var_stack[var_stack_top-1];
                        var_stack_top <= var_stack_top-1;               // pop var[4]
                        state <= state_expr_apply1;                     // complete a expr
                    end

                    state_expr_identifier:
                    begin
                        data_step <= 0;
                        ast_io[7:0] <= ast_item;                        // type   = item
                        ast_io[19:8] <= var[2];                         // index1 = var[2]: index in string table
                        ast_addr <= var[4];
                        ast_en <=1;
                        state <= state_expr_apply1;                     // complete a expr
                    end

                    state_expr_apply1:
                    begin
                        data_step <= 0;
                        var_stack[var_stack_top] <= var[4];                         // push var[4]
                        var_stack_top <= var_stack_top+1;
                        call_stack[call_stack_top] <= state_expr_apply2;            // after calling: go to apply2
                        call_stack_top <= call_stack_top+1;
                        state <= state_expr;
                    end

                    state_expr_apply2:
                    begin
                        data_step <= 0;                
                        if(var[4]!=no_more_item) begin
                            c_ast <= c_ast+1;
                            ast_addr <= c_ast;
                            ast_io[7:0]  <= ast_application;
                            ast_io[19:8] <= var_stack[var_stack_top-1];
                            ast_io[31:20] <= var[4];
                            ast_en <= 1;
                            var_stack_top <= var_stack_top-1;
                            var[4] <= c_ast;
                        end else begin
                            var[4] <= var_stack[var_stack_top-1];
                            var_stack_top <= var_stack_top-1;
                        end
                        state <= call_stack[call_stack_top-1];                     // return
                        call_stack_top <= call_stack_top-1;
                    end
                endcase
            end
        end
    end

endmodule
