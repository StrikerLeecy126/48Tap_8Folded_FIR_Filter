# 48-Tap 8-Fold FIR Filter
Course Project. 8-Fold 48-Tap, 12-bit Fixed Point FIR Filter Designed by our team using Verilog. 

Note: This is the DSP Architecture course project that is expected to be examed in 26th May 2022, designed by LWX's team during March and April 2022, if you are also doing this course project, you may only want to learn the idea from it. Any similar code found during the examination will be supposed as plagiarism and will affect the final result. This line of comment expires after 26th May 2022.

## Quantize Filter Taps and create .coe File for Filter Input
Use "filterDesigner" tools in MATLAB to create a FIR filter you need, export the tap to MATLAB workspace.

In "CalcFIXPointTap_Sample_WriteCOE.m" file, load your tap .mat file, then execute the script to get quantized filter taps and sampled and quantized input signal.

## Vivado IP Core 
Two IP cores are used in the project

&nbsp;&nbsp;-Block Memory Generator  
&nbsp;&nbsp;&nbsp;&nbsp;-Read/Write Width: 12bits  
&nbsp;&nbsp;&nbsp;&nbsp;-Read/Write Depth: According to your sampled points  
&nbsp;&nbsp;&nbsp;&nbsp;-Memory Initialization: Load your .coe file.  
&nbsp;&nbsp;-ILA  
&nbsp;&nbsp;&nbsp;&nbsp;-Probe0: Input Signal 12bits  
&nbsp;&nbsp;&nbsp;&nbsp;-Probe1: Output Signal 12bits  

## Add Filter Taps
In the source file, where few rows after comment  
    "// Tap Parameters"  
are where your filter tap located, e.g.:  
    wire signed [11:0]h0 = 12'b111111111111;  
    wire signed [11:0]h1 = 12'b111111111111;  
    wire signed [11:0]h2 = 12'b111111111111;  
    wire signed [11:0]h3 = 12'b000000000000;  
    wire signed [11:0]h4 = 12'b000000000000;  
    wire signed [11:0]h5 = 12'b000000000010;  
    wire signed [11:0]h6 = 12'b000000000011;  
    wire signed [11:0]h7 = 12'b000000000110;  
    
changing the bits will change the tap parameters.

## Filter Architecture:
One Folded Filter Instance:  
![FoldFilt1](https://user-images.githubusercontent.com/76428637/168465958-694b64b0-917f-4d43-a647-4f19762556d5.png)

Overall Filter Architecture:
![FoldFilt2](https://user-images.githubusercontent.com/76428637/168465970-6d13f414-e152-428c-94a0-1ec72c90cb23.png)

Implementation with Digilent Basys3 FPGA Board:
![P%0%0R(27~R542 EWO0GVIJ](https://user-images.githubusercontent.com/76428637/168466018-73eaaef9-f737-47cd-b19a-02f542920d18.jpg)

## Filter Result
<img width="584" alt="Data" src="https://user-images.githubusercontent.com/76428637/168472758-d0ade4d8-b45e-46bf-b418-cfc764a550e0.png">
