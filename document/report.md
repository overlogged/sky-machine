  # 无类型lambda演算机的设计与实现

  交叉创新平台1601班 隆晋威 3160104343

  > There may, indeed, be other applications of the system than its use as a logic. —Alonzo Church, 1932



  ## 一、无类型Lambda演算简介

  #### 简介(Introduction)

  lambda 演算是最小的通用程序设计语言，由Alonzo Church 和 Stephen Cole Kleene 在20世纪三十年代提出。它是一套用于研究函数定义、函数应用和函数递归的形式系统。

  #### 语法定义(Grammer Definition)

  lambda表达式的巴科斯范式(BNF)定义如下：

      <expr> ::= <identifier>
      <expr> ::= (λ <identifier> . <expr>)
      <expr> ::= (<expr> <expr>)

  一个单独的标识符(term)是一个lambda表达式；` (λ <identifier> . <expr>)`定义了一个函数(lambda abstraction)，它的变量是`<identifier>`，值是`<expr>`；`<expr> <expr>`表示把前一个函数应用(lambda application)到后一个自变量上。

  对lambda表达式进行化简的过程称为规约(reduction)。在 lambda 演算中存在两种规约，一种叫$\alpha$变换(alpha conversion)，简单地说即为函数变换自变量名称，函数不发生改变，例如$\lambda x.f\;x$和$\lambda y.f \; y$即为$\alpha$等价。另一种规约叫$\beta$规约(beta reduction)，不严格地说即函数应用等价于将自变量带入函数，例如$(\lambda x.f \; x) \; y$可规约为$f \; y$

  注：lambda演算中的函数应用为左结合，但在本次实验中，函数应用为右结合。

  #### 邱奇编码(Church encoding)

  lambda 演算只有简单的几条规则，那么怎么用它来编写程序呢。邱奇提出了一些用 lambda 表达式来编码数据结构和操作的方法。

  例如: 

  对分支语句进行编码
  ```
  $true=\a.\b.a
  $false=\a.\b.b
  $and=\p.\q.(p q) p
  $or=\p.\q.(p p) q
  $if=\p.\a.\b.(p a) b
  ```

  对自然数进行编码(也叫做邱奇计数 Church numerals)
  ```
  $zero=\f.\x.x
  $one=\f.\x.f x
  $two=\f.\x.f (f x)

  $succ=\n.\f.\x.f ((n f) x)
  $add=\m.\n.\f.\x.(m f) ((n f) x)
  $mult=\m.\n.\f.\x.(m (n f)) x
  $exp=\m.\n.\f.\.((n m) f) x
  ```

  对代数数据类型(algebraic data types)和递归类型(recursive type)的编码在此不再赘述。





  ## 二、架构设计

  整个项目采用MVC设计模式进行设计

  #### Model

  * editor

      editor是文本编辑器，负责接收输入，缓存输入，在用户按下回车后调用lambda演算机进行演算并输出演算结果。输入为字符流，输出为追加到显示器的字符流和控制命令流。

  * lambda calculus machine

      lambda演算机模型，输入为待解析的字符流，输出为演算结果的字符流。

  * lexer

      词法解析器，输入为待解析的连续字符流，输出为词法解析后的符号(token)流。

  * parser

      语法解析器，输入为不连续token流，输出为抽象语法树(abstract syntax tree)

  #### View

  * view

      view是文本显示控制模块，输入为追加的字符流和控制命令流，内部实现了显示字符的缓存、分页等功能。
  * vga

      vga驱动模块，负责和硬件交互，并给view提供接口。


  #### Controller

  * keyboard

      ps2驱动模块，从键盘接收数据并输出字符流。

      ​

  ## 三、算法层面实现细节

  #### Model

  * 在 MVC 架构中，Model 架构负责保存数据，并对数据进行处理。在这个项目中，Model 负责保持lambda演算机的运行环境，并处理新提交 lambda 演算请求。


  * 4个 Model 模块采用两个相同的时钟信号，一个是clk_25mhz，一个是 clk_io，其中 clk_io 的频率为12.5mhz，在 clk_io 为1时处理和读写 RAM、ROM 有关的操作，在 clk_io 为0时处理程序控制逻辑。

  * 文本编辑器(Editor)直接与 Controller、View交互，它从 Controller 读取输入的数据，存在缓存中，在用户按下回车键后，将缓存中的 lambda 表达式传给 lexer、parser、interpreter 进行处理。Editor 还有控制文本输出和光标闪烁、给 View 发换行、滚屏指令等功能。

    ```verilog
    module model_editor(
        input wire clk_25mhz,               // clock
        input wire clk_io,                  // io clock
        input wire [7:0] ch_input,          // input of keyboard
        input wire reset,                   // reset
        output reg [5:0] ch_append,         // data for appending: 0 for nothing input
        output reg [7:0] cmd                // commmand
    );
    ```

  * 词法分析器(Lexer)为一个有限状态自动机(DFA)，用简单的状态变量和if语句即可实现。它读取editor 传入的字符流，并转化为符号(token)流。

    ```verilog
    module model_lexer(
        input wire clk_25mhz,               // clock
        input wire clk_io,                  // io clock
        input wire reset,                   // reset
        input wire [7:0] data_in,           // input:  byte stream
        input wire [7:0] data_step,         // input:  output stream's move step
        output reg [15:0] data_out          // output: token stream (look ahead 2 characters)
    );
    ```

  * 语法分析器(Parser)为一个下推自动机(Pushdown Automation)，它的实现较为复杂。

    ```verilog
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
    ```

    * 用一个状态变量 state 来标记当前状态。

    * 代码标签的模拟：汇编语言中可以实现代码块之间的跳转或调用，定义代码块用的是标签，在verilog 中，我们可以这样模拟 label。先预定义 state 列表，再在 alway 语句块中，用 case 语句判断当前处于哪个 state，对应 state 的处理代码即为对应标签的代码。如果想实现跳转，只需将 state 赋值为想跳转的 state

    * 函数调用的模拟：我们可以用调用栈来模拟函数调用，在 Parser 中，call_stack 用来保存返回地址，var_stack 用来保存临时变量。调用前压栈保护现场，调用后弹栈恢复现场。例如：

      标签 expr_lambda1 的处理程序

      ```verilog
      state_expr_lambda1:
      begin
        if(data_in[7:0]) begin
          if(data_in[7:0]==token_dot) begin                      
            data_step <= 1;
            ast_stack[ast_stack_top] <= {12'd0,var[2],ast_abstraction}; 
            ast_stack_top <= ast_stack_top+1;
            call_stack[call_stack_top] <= state_expr_lambda2;	// call_stack 
            call_stack_top <= call_stack_top+1;
            var_stack[var_stack_top] <= var[4];               // var_stack
            var_stack_top <= var_stack_top+1;
            state <= state_expr;                   			// jmp
          end else begin
            state <= state_error;
          end
        end
      end
      ```

      注释中的 call_stack 处，程序将函数调用的返回地址入栈了，在 var_stack 处，程序将当前使用的变量 var[4]压入栈中进行保护，在jmp 处，state 发生改变，下一次时钟周期时，代码将从 state_expr 处开始执行。

      ```verilog
      token_null:
      begin
        var[4] <= no_more_item;
        state <= call_stack[call_stack_top-1];                  // return
        call_stack_top <= call_stack_top-1;
      end
      ```

      函数返回时，将 call_stack 栈顶的地址赋给 state，然后弹栈。这样，在下一个时钟周期时，代码将跳转到上次调用函数时压入的地址处。然而这并不是传统意义上的函数返回。因为在x86等指令集中，函数调用时压入的地址是当前的代码的地址。所以如果把调用栈看作函数调用的参数的话，这种实现方式更像延续传递风格(CPS，continuation passing style)，函数调用为尾调用。函数的传参和返回值均使用寄存器。

    * 字符串保存在 string_table 里

    * 抽象语法树保存在 ast_table 里，使用下标代替指针，以实现树形结构。

      expr_id 表示表达式在 ast_table 里的下标

      string_id 表示字符串在 string_table 里的下标

      抽象语法树节点各字段的意义如下表：

      | [7:0] type  | [19:8] index1       | [31:20] index2      |
      | ----------- | ------------------- | ------------------- |
      | item        | [string_id]字符串下标    |                     |
      | abstraction | [string_id]自变量字符串下标 | [expr_id]返回表达式的下标   |
      | application | [expr_id]函数的下标      | [expr_id]被应用的自变量的下标 |

  * 解释器(Interpreter)

    ```verilog
    module model_lambda_calculus(
        input wire clk_25mhz,        
        input wire clk_io,
        input wire reset,               // reset
        input wire [7:0] data_in,       // input: byte stream
        output reg [5:0] data_out       // output: output stream
    );
    ```

    * 解释器的设计方式和语法分析器的方式相似，在检测到 Parser 解析出 AST 节点后，将节点通过Parser 提供的接口复制到解释器自己的运行时 RAM 中。
    * 在复制字符串的过程中，同时判断字符串与当前上下文(Context)中的字符串是否相等，若相等，则共用同一个 string index。上下文(Context)包含当前表达式的所有字符串和符号表中的所有字符串。
    * 解释器的设计采用了函数式编程风格，即变量不变性(immutable)，在 evaluate 一个 lambda expression 时不改变这个expression，而是产生一个新的 expression，这样可以解决很多由深拷贝和浅拷贝的差别而带来的bug，缺点是占用空间较大，需要设计垃圾回收(gabage collection)算法进行空间回收。
    * 解释器解释 lambda 表达式采用的是按值传递(call-by-value)的求值顺序，即先递归地对参数进行求值，再对求值后的参数进行函数应用。

  * 模块间和模块内的数据传输和同步

    * 读写 RAM 和 ROM 需要消耗一个时钟周期，模块间的数据传输也要消耗一个时钟周期。为了解决数据同步问题，引入了一个全局 io 时钟信号 clk_io，它是对 clk_25mhz 分频一次后的结果，因此在各个模块内部的 clk_25mhz 时钟信号上升沿时处理框架大致如下：

      ```verilog
      always @(posedge clk_25mhz) begin
        if(reset) begin
          // reset
        end else if(clk_io) begin
          // handle with io/ram
        end else begin
          // main code
        end
      end
      ```

    * 模块间的数据传输有明确的结束信号(end signal)和阻塞信号(block signal)，例如lexer 和 parser 间的数据传输，code_null 表示阻塞信号，code_end 表示结束信号。

    * 因为阻塞信号和结束信号有明确的区别，因此整个处理流程是并行进行的，类似工厂流水线的设计模式。每个模块接收一个流，对流进行处理，并产生一个流。当前一个模块的输出流处于阻塞状态时，后一个模块轮空等待。

      以 lexer 和 parser 间的数据传输为例：

      lexer 里一次输出两个 token，由 done 寄存器来决定超出范围的内容是 null 还是 end。

      ```verilog
      if(clk_io) begin
        // output the token stream
        ptr_read <= ptr_read + data_step;
        data_out[7:0]  <= (ptr_read+data_step+0<ptr_write)?buffer[(ptr_read+data_step+0)%buffer_size]:(done?token_end:token_null);
        data_out[15:8] <= (ptr_read+data_step+1<ptr_write)?buffer[(ptr_read+data_step+1)%buffer_size]:(done?token_end:token_null);
      end
      ```

      state_first 是 parser 里某个需要往前看两个 token 的状态，处理函数开头判断先判断输入流是否都准备好，如果没准备好，那么就一直循环等待。

      ```verilog
      state_first:
      begin
        if(data_in[7:0]&&data_in[15:8]) begin                    
          if(data_in[7:0]==token_set && data_in[15:8]==token_identifier) begin
            data_step <= 2;
            call_stack[call_stack_top] <= state_ready_eq;
            call_stack_top <= call_stack_top + 1;
            state <= state_strcpy;                         // strcpy
          end else begin
            data_step <= 0;
            c_str <= c_str+1;
            call_stack[call_stack_top] <= state_ready;     // after calling: go to end parse
            call_stack_top <= call_stack_top+1;
            state <= state_expr;                           // expression
          end   
        end
      end
      ```


  #### View

  * 在MVC 架构中，View 负责将数据渲染成用户可见的模式。
  * vga 模块

  ```verilog
  module vga(
      input wire clk_25mhz,           // clock
      input wire reset,               // reset
      output reg [8:0] y,             // y
      output reg [9:0] x,             // x
      output reg rdn,                 // read pixel RAM (active_low)
      output wire [3:0] r,g,b,        // rgb
      output reg hs,vs,               // horizontal and vertical synchronization
      input wire px                   // px
      );
  ```

  vga 模块直接与硬件接口交互，x,y为当前坐标，px为当前颜色(0为黑，1为白)。

  维护一个800*525的循环计数器，用来表示行和列。

  ```verilog
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
  ```

  因为有 vga 扫描存在消隐期，因此我们需要对800*525的计数器进行偏移，经验值为x从143 -> 782，y从35 -> 514

  ```verilog
  // handle offset
  assign y = v_count - 10'd35;             // pixel ram row addr 
  assign x = h_count - 10'd143;            // pixel ram col addr 
  assign rdn = (h_count > 10'd142) &&         // 143 -> 782
    (h_count < 10'd783) &&         //        640 pixels
    (v_count > 10'd34)  &&         // 35 -> 514
    (v_count < 10'd515);           //        480 lines
  ```

  核心驱动代码如下

  ```verilog
  // vga signals
  always @(posedge clk_25mhz) begin
    rdn  <=  read;                  // read pixel (active low)
    hs   <=  (h_count > 10'd95);    // horizontal synchronization
    vs   <=  (v_count > 10'd1);     // vertical   synchronization
  end
  ```

  * view 模块处理字符显示

    * 字 Controller 读取输入的数据，存在缓存中，在用户按下回车键后，将缓存中的 lambda 表达式传给 lexer、parser、interpreter 进行处理。Editor 还有控制文本输出和光标闪烁、给View 发换行、滚屏指令等功能。符编码并未采用 ASCII 编码，而是采用了自定义的6位编码，共编码了60个可显示的字符。ROM 中的字体是16*16点阵字体。

    * view 模块采用三级地址映射的方式进行设计。

      * display address

        表示当前屏幕上扫描到的地址，有如下参数。

        ```verilog
        assign offset_x = x%font_size;                          // the offset of x
        assign offset_y = y%font_size;                          // the offset of y
        assign d_index_x = x/font_size;                         // the index of x
        assign d_index_y = y/font_size;                         // the index of y
        assign d_cursor = v_cursor-d_base;                      // display cursor
        assign d_addr = v_addr-d_base;                     
        assign d_base = d_base_line*col_count;                 
        ```

        offset 为偏移量，index 为行或列坐标（以一个字为一个单位，即16*16像素）

        cursor 为闪烁的光标的位置，d_addr为二维坐标到一维坐标的线性映射。d_base是当前显示地址在虚拟地址中的基地址，即当前屏幕显示的内容为虚拟地址为[d_base,d_base+total_size]的内容

      * virtual address

        在假设显存无限的情况下的一个虚拟地址。

        ```verilog
        assign v_index_x = d_index_x;
        assign v_index_y = d_base_line + d_index_y;
        assign v_addr = v_index_y*col_count + v_index_x;
        ```

      * memory address

        然而实际上显存不可能无限，只能采用滚动内存的方法对虚拟地址进行映射

        ```verilog
        assign m_addr = v_addr%m_char_count;       // !! memory map : scroll memory
        assign m_cursor = v_cursor%m_char_count;   // !! memory map : scroll memory
        ```

      * 有了以上三个地址的映射，view模块的逻辑就变得非常清晰了，处理和ram相关的事务时用memory address，处理显示相关的用display address，处理逻辑相关的用virtual address。

        例如，处理退格只需`v_cursor <= v_cursor-32'd1;`  ，处理下滑一行只需`d_base_line <= d_base_line + 32'd1;`  

  #### Controller

  * 在MVC架构中，Controller 接收用户输入，在进行简单的处理后，交给Model进行处理。

  * Keyboard 模块从键盘接收输入，传递给 Model Editor

  * trans_code 模块将键位码转化成自定义的6位编码。

  * 利用高频时钟对 clk 和 data 两条线的数据进行滤波

    filter 模块对数据进行滤波，利用移位寄存器将串行输入转化为并行输出，并判断并行输出是否全为0或全为1，将稳定的结果输出。

  ```verilog
  module filter(
      input wire clk_25mhz,
      input wire data_in,
      output reg data_out
  );

      reg [31:0] buffer;
      initial begin
          buffer <= 32'd0;
      end

      always @ (posedge clk_25mhz) begin
          buffer[31] <= data_in;
          buffer[30:0] <= buffer[31:1];
          if(buffer==32'hffffffff) begin
              data_out <= 1;
          end else if(buffer==32'h00000000) begin
              data_out <= 0;
          end
      end

  endmodule
  ```

  * 在 clk 时钟下降沿将 data_bit 中的数据输入移位寄存器 word1 和 word2 中

    ```verilog
    always @(negedge clk_bit) begin
      word1 <= {data_bit, word1[10:1]};
      word2 <= {word1[0], word2[10:1]};
    end
    ```

  * 在进行奇校验之后，对键位码进行处理，block 寄存器用来保证一个键只输出一次。

    ```verilog
    wire check_1 = word1[1]^word1[2]^word1[2]^word1[3]^word1[4]^word1[5]^word1[6]^word1[7]^word1[8]^word1[9];    
    wire check_2 = word2[1]^word2[2]^word2[2]^word2[3]^word2[4]^word2[5]^word2[6]^word2[7]^word2[8]^word2[9];    

    always @(posedge clk_25mhz) begin
      if(check_1 && check_2 && word1[10] && word2[10] && word1[0]==0 && word2[0]==0) begin
        if (word2[8:1] != 8'hF0) begin
          pre[7:0] <= word1[8:1];
          if(trans_c) block<=1;
        end else begin
          block <= 0;
          pre[7:0] <= 8'h00;
        end
        if(pre==word1[8:1]) begin
          hold_counter = hold_counter + 1;
        end else begin
          hold_counter = 8'b0;
        end
      end
    end
    ```

  ## 四、核心模块激励波形图

  因为逻辑比较复杂，并且输入输出都是文本，所以采用了 verilog testbench 提供的 $display 函数进行仿真激励。

  对核心逻辑处理模块 editor 进行激励，激励代码由Haskell 脚本生成，用于模拟键盘输入。输出则由$display 函数打印到 console。

  从 console 中提取的 char_append[5:0] 的非零输出序列

  ```
  [57,59,59,57,53,9,4,59,56,58,24,60,24,54,58,24,60,24,55,57,54,58,24,24,60,24,24,55,59,1,1,57,9,4,59,25,25,25,25,25,25,57,53,20,18,21,5,56,58,1,60,58,2,60,1,54,58,1,60,54,58,2,60,1,55,55,57,53,6,1,12,19,5,56,58,1,60,58,2,60,2,54,58,1,60,54,58,2,60,2,55,55,57,20,18,21,5,54,58,1,60,54,58,2,60,1,55,55,57,53,26,5,18,15,56,58,6,60,58,24,60,24,54,58,6,60,54,58,24,60,24,55,55,57,53,15,14,5,56,58,6,60,58,24,60,6,59,24,54,58,6,60,54,58,24,60,54,6,59,24,55,55,55,57,53,20,23,15,56,58,6,60,58,24,60,6,59,54,6,59,24,55,54,58,6,60,54,58,24,60,54,6,59,54,6,59,24,55,55,55,55,57,53,19,21,3,3,56,58,14,60,58,6,60,58,24,60,6,59,54,54,14,59,6,55,59,24,55,54,58,14,60,54,58,6,60,54,58,24,60,54,6,59,54,54,14,59,6,55,59,24,55,55,55,55,55,57,53,20,23,15,56,19,21,3,3,59,15,14,5,54,58,6,60,54,58,24,60,54,6,59,54,6,59,24,55,55,55,55,57,53,20,8,18,5,5,56,19,21,3,3,59,20,23,15,54,58,6,60,54,58,24,60,54,6,59,54,6,59,54,6,59,24,55,55,55,55,55]
  ```

  由脚本转码后显示为

  ```
  >  
  >$id =\x.x
  (\x.x)
  >(\xx.xx) a
  a
  >id yyy
  yyy
  >$true=\a.\b.a
  (\a.(\b.a))
  >$false=\a.\b.b
  (\a.(\b.b))
  >true
  (\a.(\b.a))
  >$zero=\f.\x.x
  (\f.(\x.x))
  >$one=\f.\x.f x
  (\f.(\x.(f x)))
  >$two=\f.\x.f (f x)
  (\f.(\x.(f (f x))))
  >$succ=\n.\f.\x.f ((n f) x)
  (\n.(\f.(\x.(f ((n f) x)))))
  >$two=succ one
  (\f.(\x.(f (f x))))
  >$three=succ two
  (\f.(\x.(f (f (f x)))))
  ```

  ## 五、调试过程分析和实验体会

  一开始我就确定了这个工程用 MVC 架构，确定好架构后，就开始分别写 Model，View 和 Controller。最开始写的部分是 view，即文本输出模块。最开始写的时候选择的方案是用显存(MRAM)保存每个字的 ascii 码，然后将它输出到屏幕上。但是这样做，滚屏会变得非常麻烦，因为要将整个显存向前移动一行。于是我想到用滚动内存，这样滚屏就只需要改变地址映射关系。但还是很麻烦，直到最后想到用虚拟地址作为内存地址和显示地址的中间量才解决了问题。

  Model 是最困难的，因为在 verilog 里没有函数调用，没有子程序，而且对于 RAM 的读取不如高级语言那么容易，而且模块间还不能共享寄存器。然而， parser 和 interpreter 的很多函数都是递归定义的，没有递归调用不可能实现功能。

  最初想用完全的 continuation-passing-style 来设计，但设计到后面，continuation 越来越大，逻辑就变得越来越混乱了。这是 model 的第一次重构，重构后我选择了传统的x86架构的函数调用的解决方案，使用调用栈。但因为 verilog 不能记录当前的返回地址，因此最终的解决方案介于调用栈和 cps 之间。

  后来仔细想了一下， continuation-passing-style 实现起来比较复杂的原因是没有 first-class-function。要在硬件层面实现 first-class-function 是比较困难的事情，多半要设计一个简单的解释器，一个方便的参数传递方式和一个简单闭包表示方法。再看x86架构，它首先实现了解释器，让指令一条一条地分开，这点写 verilog 很难做到，在这个工程里只做到了函数粒度的跳转，无法做到指令粒度的跳转。这使得“代码即数据”很难实现。

  第二个比较困难的问题是模块间不能共享寄存器数组。最开始的解决方案是 interpreter 从 paser 中读取数据，再在自己的模块里处理，并将处理后的结果存入自己的 ram。由于数据传输和数据处理没有分开，导致逻辑非常混乱，最后我选择了先进行数据传输，再进行数据处理。这就是 model 的第二次重构。

  第三个比较困难的问题是，在 interpreter 对 lambda 表达式进行 evaluate 的过程中，出现了表达式所有权不清晰的问题。因为抽象语法树是用线性表模拟的树形结构。因此每个节点上存的都不是完整的子节点，而是子节点的序号，有时会有两个节点共用同一个子节点的情况，这时如果对一个节点进行 evaluate，会导致另一个节点发生变化。一开始我选择的是有副作用(side-effect)的求值方式，最终我决定用函数式的编程风格，求值不改变原有节点，而是产生一个新的节点。这时 model 的第三次重构。

  第四个问题是 RAM 的实现问题。我使用的 RAM 并不是由 ipcore 生成的，而是自己定义的 reg 数组。使用的时候也是按照高级语言的习惯，需要的时候直接用。但是在综合的时候就遇到了大麻烦，不仅综合时间变得非常长，而且综合的结果也很糟糕，很多 RAM 的实现方式是 1-bit-register，读取和写入 RAM 由多路复用器来控制。在某次综合报告中，我看到这个工程一共花费了10万多三态门，这是很糟糕的实现方法。

  后来我发现在一个时序里 reg 数组的下标有几个，RAM 就需要几个port，实验板上的 RAM block 通常有2 ports或4 ports，并且 RAM 要求它的读写代码必须写在时序代码块中。只有满足了 RAM 的条件，大 reg 数组才会被综合成 RAM。因此我引入了全局 io 时钟，由 io 时钟控制，统一对 RAM 进行处理。这是 Model 的第四次重构。

  其余的一些逻辑 bug 就比较小了，大都是一些笔误。利用 ISE 提供的仿真激励进行单步调试，很容易发现 bug，这和高级语言差别不大。



  ## 六、经验与总结

  我总结了一些利用 verilog 维护复杂工程的经验。

  * verilog 是硬件描述语言，千万不能带着高级语言的思维去写。心里要装着硬件，要关心代码是怎么被映射到硬件的
  * 函数式的编程范式在简化系统的复杂度上有很大的优势，缺点是资源占用较多
  * 建模要清晰，该分离的逻辑一定要分离
  * verilog 语言没有类型系统，对代码的静态约束太少，这会导致很多由笔误导致的 bug 难以发现



  我觉得可能需要设计一种比 verilog 更现代的语言，辅以静态分析的工具，这会大大提高 FPGA 工程师的工作效率。



  ## 七、附录

  参数配置

  | 文件                      | 大小                      | 说明                                       |
  | ----------------------- | ----------------------- | ---------------------------------------- |
  | model_editor.v          | max_buffer_size = 256;  | 输入的lambda表达式最长的字符数                       |
  | model_lambda_claculus.v | max_str_buffer = 512;   | 输出字符串缓冲                                  |
  | model_lambda_claculus.v | max_symbol_size = 512;  | 符号数                                      |
  | model_lambda_claculus.v | max_buffer_size = 4096; | ast_table和string_table的大小                |
  | model_lambda_claculus.v | max_stack_size = 512;   | 栈大小                                      |
  | model_lambda_calculus.v | max_str_size = 256;     | 字符串标最大长度                                 |
  | model_lexer.v           | buffer_size = 256;      | 输入的lambda表达式的最长的字符数                      |
  | model_parser.v          | max_identifier = 8;     | 标识符的最长长度(同时会影响lambda calculus里的string表位宽) |
  | model_parser.v          | max_buffer_size = 128;  | 在parser里ast_table和string_table的大小        |
  | model_parser.v          | max_stack_size = 128;   | 栈大小                                      |

  用于处理字体的matlab代码

  ```matlab
  new_code = [0 97 98 99 100 101 102 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 36 40 41 61 62 92 32 46 0 0 0];
  result = [];
  for c = new_code
      if c>=32
          p = c-32;
      else
          p = 0;
      end
      x = mod(p,20);
      y = fix(p/20);
      b = M(y*16+1:(y+1)*16,x*16+1:(x+1)*16);
      result = [result;b];
  end
  result
  ```

  生成测试代码的Haskell脚本

  ```haskell
  import Data.Char
  import Data.List
  import Text.Printf

  f::Int->Int
  f x
          | x==0 = 0
          | x>=ord 'a'&&x<=ord 'z' = x-ord 'a'+1
          | x>=ord 'A'&&x<=ord 'Z' = x-ord 'A'+27
          | x==ord '\n' = 66
          | otherwise = sum $ map (\(c,i)->if x==ord c then i else 0) (zip "$()=>\\ ." [53..60])
          
  invf::Int->Int
  invf t = head [x|x<-[0..255],f x ==t]

  s = 
      let strs= [" ",
                  "$id =\\x.x","(\\xx.xx) a",
                  "id yyy",
                  "$true=\\a.\\b.a",
                  "$false=\\a.\\b.b",
                  "true",
                  "$zero=\\f.\\x.x",
                  "$one=\\f.\\x.f x",
                  "$two=\\f.\\x.f (f x)",
                  "$succ=\\n.\\f.\\x.f ((n f) x)",
                  "$two=succ one","$three=succ two"
              ] in sequence_ $ (map putStr ["parameter count = ",(show (length strs)),";\n","wire [7:0] string [0:count-1][0:max_size-1];\n"]) ++ map (\(index,tstr)->let str=tstr++"\n" in sequence_ $ map putStr $ ["/*",tstr,"*/\n"] ++ [printf "assign string[%d][%d] = 8'd%d;\n" index (fst t::Int) (f (ord (snd t))::Int) ::String | t<-zip [0..] str] ++ [printf "assign string[%d][%d] = 8'd0;\n" index (length str)]) (zip ([0..]::[Int]) strs)

  t = sequence_ $ map (\(i,x)->putStrLn $ (printf "\tassign string[%d] = 8'd%d;" (i::Int) x::String)) $ zip [0..] (map (f.ord) "$id =\\x.x\n")

  {- [0,255]->[0,63] -}
  showc s = map (\x->chr $ head [c|c<-[0..255],f c==x]) s
  ```

