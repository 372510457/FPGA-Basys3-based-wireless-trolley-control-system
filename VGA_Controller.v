`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/23 02:18:10
// Design Name: Xingyifei
// Module Name: VGA_Controller
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


module VGA_Controller(                                     
    input CLK,                                             
    input RESET,                                           
    input BUS_WE,                                                                                          
    output HS,                                             
    output VS,                                             
    output [7:0] COLOUR_OUT,                               
    inout [7:0] BUS_DATA,                                  
    input [7:0] BUS_ADDR                                   
    );                                                     

    parameter [7:0] VGABaseAddress = 8'hB0;

    wire [14:0]VGA_ADDR;                                   
    wire B_DATA;                                           
    wire DPR_CLK;                                                                                                
    
    reg FrameBuffer_WE;         
    reg [14:0] ADDR_FB;                                    
    reg Pixel_data;      
    
    wire [15:0] CONFIG_COLOUR = {8'hF8, 8'h00};                                                                                                              
    //wire [15:0] CONFIG_COLOUR;// = 8'hF8 ;                    
    //wire [7:0] CONFIG_COLOUR;// =  8'h00;         
    
    wire [14:0] ADDR_connect;               
    
    wire Data_FB_VGA;                          
    wire Data_FB;                              
                            
     Frame_Buffer fb (                          
         .A_CLK(CLK),                           
         .A_ADDR(ADDR_FB),                      
         .A_DATA_IN(Pixel_data),     //Pixel Data in      
         .A_DATA_OUT(Data_FB),                  
         .A_WE(FrameBuffer_WE),                 
         .B_CLK(DPR_CLK),                       
         .B_ADDR(ADDR_connect),     //Pixel Data out
         .B_DATA(Data_FB_VGA)                   
     );                                         
                                            
     VGA_Sig_Gen sig (                           
         .CLK(CLK),                             
         .RESET(RESET),                         
         .CONFIG_COLOURS(CONFIG_COLOUR),        
         .DPR_CLK(DPR_CLK),                     
         .VGA_ADDR(ADDR_connect),            
         .VGA_DATA(Data_FB_VGA),                
         .VGA_HS(HS),                           
         .VGA_VS(VS),                           
         .VGA_COLOUR(COLOUR_OUT)                
     );        
     
     reg VGABusWE;
     reg [7:0] Out;
     assign BUS_DATA = (VGABusWE) ? Out : 8'hZZ;
                                      
                                            
    always@(posedge CLK) begin                
        if (BUS_WE) begin
            VGABusWE <= 1'b0;                         
            // hs
            if (BUS_ADDR == VGABaseAddress) begin          
                FrameBuffer_WE <= 1'b0;           
                ADDR_FB[7:0] <= BUS_DATA;         
            end                                                     
            // vs
            else if (BUS_ADDR == VGABaseAddress + 1) begin  
                FrameBuffer_WE <= 1'b0;        
                ADDR_FB[14:8] <=  120 - BUS_DATA ;   
            end                                
            //Pixel_data
            else if (BUS_ADDR == VGABaseAddress +2) begin  
                FrameBuffer_WE <= 1'b1;        
                Pixel_data <= BUS_DATA[0];     
            end                                
            else                               
                FrameBuffer_WE <= 1'b0;
        end else begin
            // Enable the VGA module to write to bus (if the address is right)
                if (BUS_ADDR >= VGABaseAddress & BUS_ADDR < VGABaseAddress + 3)
                    VGABusWE <= 1'b1;
                else
                    VGABusWE <= 1'b0;
                        
                // Processor is not writing, so disable writing to frame buffer
                FrameBuffer_WE <= 1'b0;
            end     
            Out <= Data_FB;
   end
endmodule

