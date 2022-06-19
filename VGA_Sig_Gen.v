`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 02:16:26
// Design Name: Xingyifei
// Module Name: VGA_Sig_Gen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module VGA_Sig_Gen(
    input CLK,
    input RESET,
    //Colour Configuration Interface
    input [15:0] CONFIG_COLOURS,
    // Frame Buffer (Dual Port memory) Interface
    output DPR_CLK,
    output [14:0] VGA_ADDR,
    input VGA_DATA,
    //VGA Port Interface
    output reg VGA_HS,
    output reg VGA_VS, 
    output [7:0] VGA_COLOUR
 );
    //Halve the clock to 25MHz to drive the VGA display (dev by 100MHz)
    reg [1:0] CLK_Counter;
    reg VGA_CLK;
    //initial begin
    //    CLK_Counter <= 0;
    //    VGA_CLK <= 0;
    //end 
    always@(posedge CLK) begin
        if(RESET) begin
            VGA_CLK <= 0;
            CLK_Counter <= 0;
        end
        else begin
            if (CLK_Counter == 1) begin
                VGA_CLK <= ~VGA_CLK;
                CLK_Counter <= 0;
            end
            else
                CLK_Counter <= CLK_Counter + 1;
        end 
    end
/*
Define VGA signal parameters e.g. Horizontal and Vertical display time, pulse widths, front and back 
porch widths etc. 
*/
    // Use the following signal parameters
    parameter HTs = 800;    // Total Horizontal Sync Pulse Time
    parameter HTpw = 96;    // Horizontal Pulse Width Time 
    parameter HTDisp = 640; // Horizontal Display Time
    parameter Hbp = 48;     // Horizontal Back Porch Time
    parameter Hfp = 16;     // Horizontal Front Porch Time
    
    parameter VTs = 521;    // Total Vertical Sync Pulse Time
    parameter VTpw = 2;     // Vertical Pulse Width Time
    parameter VTDisp = 480; // Vertical Display Time
    parameter Vbp = 29;     // Vertical Back Porch Time
    parameter Vfp = 10;     // Vertical Front Porch Time



    
    // Define Horizontal and Vertical Counters to generate the VGA signals
    reg [9:0] HCounter;
    reg [9:0] VCounter;
/*
Create a process that assigns the proper horizontal and vertical counter values for raster scan of the 
display. 
*/
    initial begin
        HCounter <= 0;
        VCounter <= 0;
    end
    // Line sync counter
    always @(posedge VGA_CLK) begin
        if (RESET)
            HCounter <= 0;
        else begin
            if (HCounter == HTs - 1)
                HCounter <= 0;
            else
                HCounter <= HCounter + 1;
        end
    end
    
    // Field sync counter
    always @(posedge VGA_CLK) begin
        if (RESET)
            VCounter <= 0;
        else begin
            if (HCounter == HTs - 1) begin
                if (VCounter == VTs - 1)
                    VCounter <= 0;
                else
                    VCounter <= VCounter + 1;
            end
            else
                VCounter <= VCounter;
        end  
    end  
/*
Need to create the address of the next pixel. Concatenate and tie the look ahead address to the frame 
buffer address.
*/
    assign DPR_CLK = VGA_CLK;
    assign VGA_ADDR = {VCounter[8:2], HCounter[9:2]};
/*
Create a process that generates the horizontal and vertical synchronisation signals, as well as the pixel 
colour information, using HCounter and VCounter. Do not forget to use CONFIG_COLOURS input to 
display the right foreground and background colours.
*/
    
    // Line sync signal
    always @(posedge VGA_CLK) begin
        if (HCounter >= (HTDisp + Hfp - 1) && HCounter < (HTDisp + Hfp + HTpw - 1))
            VGA_HS <= 0;
        else
            VGA_HS <= 1;
    end
    
    // Field sync signal
    always @(posedge VGA_CLK) begin
        if (VCounter >= (VTDisp + Vfp - 1) && VCounter < (VTDisp + Vfp + VTpw - 1))
            VGA_VS <= 0;
        else
            VGA_VS <= 1;
    end
    


/*
Finally, tie the output of the frame buffer to the colour output VGA_COLOUR. 
*/
    reg [7:0] COLOUR_REG;
    always@(posedge VGA_CLK)begin
        if(HCounter < HTDisp && VCounter < VTDisp)begin
            if(VGA_DATA)
                COLOUR_REG <= CONFIG_COLOURS[15:8];
            else
                COLOUR_REG <= CONFIG_COLOURS[7:0];
        end
        else
            COLOUR_REG <= 8'h00;
    end

    assign VGA_COLOUR = COLOUR_REG;

endmodule
