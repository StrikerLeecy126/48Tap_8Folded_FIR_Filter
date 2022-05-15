`timescale 1ns / 1ps

// Suppose (1,0,11) 12-bit data, 1 sign, 0 integer, 11 float, fixed point decimal.

module FoldedFilter(                        // Filter Instance
        input clk,rst,
        output [11:0]X_out);                // IO        
        
        // Connected Wires
        wire [11:0]X_in;                    // Input Signal                        
        wire [11:0]S12,S23,S321,S322,S211,S212,S331,S332,X_out1;    // Wires Between Black Boxes
        wire clk_8;                         // 1/8 Clock Frequency Signal
    
        reg [14:0]addr;                         // RAM Address Counter, Count 0-20000
        reg [2:0]control;                       // Control Counter, Count 0-7
        
        always@(posedge clk_8 or posedge rst)   // Address Register, +1 every 8 Clock Cycles
        begin
        if(rst==1)                              // reg ini
            addr<=15'd0;
        else if(addr == 15'd20001)              // Data Overflow, Address Reset
            addr<=15'd0;
        else                  
            addr<=addr+1'b1;                    // reg+1
        end
        
       always@(posedge clk or posedge rst)      // Folding Case Register
       begin
       if(rst==1)
            control<=3'b0;
        else 
            control<=control+1'b1;
        end
        
        // RAM .coe Instance
        blk_mem_gen_1 U0(
        .addra(addr),           // Memory Address 
        .clka(clk),             // Data Read Clock
        .douta(X_in),           // Data Output
        .wea(1'b0)              // Write Enable LOW
        );

        // ILA Instance
        ila_0 U4(
        .clk(clk),
        .probe0(X_in),          // Monitor Input Signal
        .probe1(X_out)          // Monitor Output Signal
        );
        
        // Other Instances
        Filter1 U1(30'b0,S212,X_in,control,S12,X_out1,clk,rst);
        Filter2 U2(S12,S322,X_in,control,S23,S211,clk,rst);
        Filter3 U3(S23,S332,X_in,control,S331,S321,clk,rst);
        control_reg0 R1(S331,S332,control,rst,clk);
        control_reg1 R2(S321,S322,control,rst,clk);
        control_reg1 R3(S211,S212,control,rst,clk);
        control_reg1 R4(X_out1,X_out,control,rst,clk);
        clkdiv C1(clk,rst,clk_8);
        
endmodule


// Register Between Filter 3 Out1 and In2
module control_reg0(
        input [11:0]in, 
        output reg [11:0]out, 
        input [2:0]control, 
        input rst,clk);

        always @(posedge clk or posedge rst)
            begin
            if(rst==1)
                out<=12'b0;
            else if(control==3'b000)        // Output at Case 0
                out<=in;
            end
endmodule


// Other Registers Between Instances
module control_reg1(
        input [11:0]in, 
        output reg [11:0]out,  
        input [2:0]control, 
        input rst,clk);
                 
        reg[11:0] mid;      // 2 Stage Delay
        always @(posedge clk or posedge rst)
            begin
            if(rst==1)
                begin
                mid<=12'b0;
                out<=12'b0;
                end
            else
            if(control==3'b001)             // Output at Case 3
                begin
                mid<=in;
                out<=mid;
                end
            end
endmodule

// Float Point Multiplier
module fpmul                                
    #(parameter IW = 1,                     // Sign Bit, 1
    parameter FW = 11 )                     // Decimal Bits, 11
    (                                       // c=a*b
    input signed[IW+FW-1:0] a,
    input signed[IW+FW-1:0] b,
    output signed[IW+FW-1:0] c
    );
    
    (* multstyle = "dsp" *) wire signed [IW*2+FW*2-1 : 0] long;
    assign long = a * b;
    assign c = long >>> FW;                 // Discard 11 LSBs
endmodule

// Clock Divider f_clk_8=1/8*f_clk
module clkdiv(
    input clk,rst,
    output clk_8);
    
    reg clk_div2_r ;
    always @(posedge clk or posedge rst) 
    begin
    if (rst)
     clk_div2_r<='b0;
    else
     clk_div2_r<=~clk_div2_r;
    end
    assign clk_div2= clk_div2_r ;

    reg clk_div4_r;
    always @(posedge clk_div2 or posedge rst) 
    begin
      if (rst)
        clk_div4_r<= 'b0;
      else
        clk_div4_r<= ~clk_div4_r;
    end
    assign clk_div4=clk_div4_r;
    
   reg clk_div8_r;
   always @(posedge clk_div4 or posedge rst) 
   begin
      if (rst)
        clk_div8_r<= 'b0;
      else
        clk_div8_r<= ~clk_div8_r;
   end
   assign clk_8=clk_div8_r;
endmodule

module Filter1(
    input [11:0]IN1,IN2,
    input signed[11:0]SigIn,
    input [2:0]control,
    output reg[11:0]OUT1,OUT2,
    input clk,rst);
    
    // Tap Parameters
    wire signed [11:0]h0 = 12'b111111111111;
    wire signed [11:0]h1 = 12'b111111111111;
    wire signed [11:0]h2 = 12'b111111111111;
    wire signed [11:0]h3 = 12'b000000000000;
    wire signed [11:0]h4 = 12'b000000000000;
    wire signed [11:0]h5 = 12'b000000000010;
    wire signed [11:0]h6 = 12'b000000000011;
    wire signed [11:0]h7 = 12'b000000000110;


    reg [11:0] D1,D4;               // Reg connected to OUT1 and OUT2 resp.
    reg [11:0] D2[1:8];             // Reg with 8 delays
    reg [11:0] D3[1:6];             // Reg with 6 delays
    reg [11:0] h;                   // Tap Register
    reg signed[11:0] S1,S2;         // Sum Register
    wire signed[11:0] Mul;          // Multiply Out Signal
    
    integer k1,k2;                  // Register convey variable
    
    fpmul M1(SigIn,h,Mul);          // Multiplier Instance

    always @(posedge clk or posedge rst)
    begin
        if (rst == 1)               // LOW to reset
            begin                   // Initialisation
                {D1,D4}                                           <= 24'b0;
                {S1,S2}                                           <= 24'b0;
                {D2[1],D2[2],D2[3],D2[4],D2[5],D2[6],D2[7],D2[8]} <= 96'b0;
                {D3[1],D3[2],D3[3],D3[4],D3[5],D3[6]}             <= 72'b0;
                h                                                 <= 12'b0;
                OUT1                                              <= 12'b0;
                OUT2                                              <= 12'b0;
            end
        else
            begin
                // Folding Cases
                case (control)      // control to set the cases 
                    3'b000:
                    begin
                        h    <= h0;
                        S1   <= IN1;
                        S2   <= D3[6];
                        OUT1 <= D1;
                    end
                    3'b001:
                    begin
                        h    <= h1;
                        S1   <= D2[8];
                        S2   <= D3[6];
                        OUT2 <= D4;
                    end
                    3'b010:
                    begin
                        h  <= h2;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b011:
                    begin
                        h  <= h3;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b100:
                    begin
                        h  <= h4;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b101:
                    begin
                        h  <= h5;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b110:
                    begin
                        h  <= h6;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b111:
                    begin
                        h  <= h7;
                        S1 <= D2[8];
                        S2 <= IN2;
                    end
                endcase
            
            // Data Convey Through Registers
            D1<=Mul+S1;
            D4<=Mul+S2;

            D2[1] <= D1;
            D3[1] <= D4;

            for(k1 = 2;k1<9;k1 = k1+1) D2[k1]<= D2[k1-1];
            for(k2 = 2;k2<7;k2 = k2+1) D3[k2]<= D3[k2-1];
        end
    end
endmodule


// Filter 2 and 3 are same as Filter 1 except tap parameters
module Filter2(
    input [11:0]IN1,IN2,
    input signed[11:0]SigIn,
    input [2:0]control,
    output reg [11:0]OUT1,OUT2,
    input clk,rst);

    wire signed [11:0]h0 = 12'b000000001010;
    wire signed [11:0]h1 = 12'b000000001110;
    wire signed [11:0]h2 = 12'b000000010100;
    wire signed [11:0]h3 = 12'b000000011010;
    wire signed [11:0]h4 = 12'b000000100010;
    wire signed [11:0]h5 = 12'b000000101010;
    wire signed [11:0]h6 = 12'b000000110011;
    wire signed [11:0]h7 = 12'b000000111100;

    reg [11:0] D1,D4;
    reg [11:0] D2[1:8];
    reg [11:0] D3[1:6];
    reg [11:0] h;
    reg signed[11:0] S1,S2;
    wire signed[11:0] Mul;
    
    integer k1,k2;
    
    fpmul M2(SigIn,h,Mul);
 
    always @(posedge clk or posedge rst)
    begin
        if (rst == 1)
            begin
                {D1,D4}                                           <= 24'b0;
                {S1,S2}                                           <= 24'b0;
                {D2[1],D2[2],D2[3],D2[4],D2[5],D2[6],D2[7],D2[8]} <= 96'b0;
                {D3[1],D3[2],D3[3],D3[4],D3[5],D3[6]}             <= 72'b0;
                h                                                 <= 12'b0;
                OUT1                                              <= 12'b0;
                OUT2                                              <= 12'b0;
            end
        else
            begin
                case (control)
                    3'b000:
                    begin
                        h    <= h0;
                        S1   <= IN1;
                        S2   <= D3[6];
                        OUT1 <= D1;
                    end
                    3'b001:
                    begin
                        h    <= h1;
                        S1   <= D2[8];
                        S2   <= D3[6];
                        OUT2 <= D4;
                    end
                    3'b010:
                    begin
                        h  <= h2;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b011:
                    begin
                        h  <= h3;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b100:
                    begin
                        h  <= h4;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b101:
                    begin
                        h  <= h5;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b110:
                    begin
                        h  <= h6;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b111:
                    begin
                        h  <= h7;
                        S1 <= D2[8];
                        S2 <= IN2;
                    end
                endcase
            
            D1<=Mul+S1;
            D4<=Mul+S2;

            D2[1] <= D1;
            D3[1] <= D4;            

            for(k1 = 2;k1<9;k1 = k1+1) D2[k1]<= D2[k1-1];
            for(k2 = 2;k2<7;k2 = k2+1) D3[k2]<= D3[k2-1];
        end
    end
endmodule

module Filter3(
    input [11:0]IN1,IN2,
    input signed[11:0]SigIn,
    input [2:0]control,
    output reg [11:0]OUT1,OUT2,
    input clk,rst);
                 
                 
    wire signed [11:0]h0 = 12'b000001000101;
    wire signed [11:0]h1 = 12'b000001001111;
    wire signed [11:0]h2 = 12'b000001010111;
    wire signed [11:0]h3 = 12'b000001011111;
    wire signed [11:0]h4 = 12'b000001100101;
    wire signed [11:0]h5 = 12'b000001101011;
    wire signed [11:0]h6 = 12'b000001101110;
    wire signed [11:0]h7 = 12'b000001110000;
    
    reg [11:0] D1,D4;
    reg [11:0] D2[1:8];
    reg [11:0] D3[1:6];
    reg [11:0] h;
    reg signed[11:0] S1,S2;
    wire signed[11:0] Mul;
    
    integer k1,k2;

    fpmul M3(SigIn,h,Mul);

    always @(posedge clk or posedge rst)
    begin
        if (rst == 1)
            begin
                {D1,D4}                                           <= 24'b0;
                {S1,S2}                                           <= 24'b0;
                {D2[1],D2[2],D2[3],D2[4],D2[5],D2[6],D2[7],D2[8]} <= 96'b0;
                {D3[1],D3[2],D3[3],D3[4],D3[5],D3[6]}             <= 72'b0;
                h                                                 <= 12'b0;
                OUT1                                              <= 12'b0;
                OUT2                                              <= 12'b0;
            end
        else
            begin
                case (control)
                    3'b000:
                    begin
                        h    <= h0;
                        S1   <= IN1;
                        S2   <= D3[6];
                        OUT1 <= D1;
                    end
                    3'b001:
                    begin
                        h    <= h1;
                        S1   <= D2[8];
                        S2   <= D3[6];
                        OUT2 <= D4;
                    end
                    3'b010:
                    begin
                        h  <= h2;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b011:
                    begin
                        h  <= h3;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b100:
                    begin
                        h  <= h4;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b101:
                    begin
                        h  <= h5;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b110:
                    begin
                        h  <= h6;
                        S1 <= D2[8];
                        S2 <= D3[6];
                    end
                    3'b111:
                    begin
                        h  <= h7;
                        S1 <= D2[8];
                        S2 <= IN2;
                    end
                endcase

            D1<=Mul+S1;
            D4<=Mul+S2;

            D2[1] <= D1;
            D3[1] <= D4;

            for(k1 = 2;k1<9;k1 = k1+1) D2[k1]<= D2[k1-1];
            for(k2 = 2;k2<7;k2 = k2+1) D3[k2]<= D3[k2-1];
        end
    end
endmodule

// Test Bench, Delete/Comment when using FPGA
module TB;
    reg clock, reset;
    wire [11:0]X_out;

    FoldedFilter V1(clock, reset, X_out);      // Connect clock reset X_out counter to the Product

    initial
    begin: clock_start
        clock =1'b0;
        forever #50 clock = ~clock;                     // Clock Period: 100 unit time
    end 

    initial
    begin: control
        reset = 1'b1;                                   // Reset
        #100 reset = 1'b0;                              // 100 unit time Reset Complete
    end
endmodule