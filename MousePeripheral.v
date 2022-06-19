`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/15 11:21:45
// Design Name: 
// Module Name: MousePeripheral
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

module MousePeripheral(
    input CLK,
    input RESET,
    
    // mouse signals
    inout DATA_MOUSE,
    inout CLK_MOUSE,
    
    // bus signals
    output [7:0] BUS_DATA,
    input [7:0] BUS_ADDR,
    input BUS_WE,
    
    // interrupt signals
    output BUS_INTERRUPT_RAISE,
    input BUS_INTERRUPT_ACK
    );
    
    wire [7:0] MouseStatus;
    wire [7:0] MouseX;
    wire [7:0] MouseY;
    wire [7:0] MouseDX;
    wire [7:0] MouseDY;
    wire SendInterrupt;
    parameter [7:0] MouseBaseAddr = 8'hA0;
    reg [7:0] Out;
    reg MouseBusWE;
    reg Interrupt;
    wire [7:0] mousebytes [4:0];  // 2D array for holding mouse bytest;
    
    MouseTransceiver mouse(
        .RESET(RESET),
        .CLK(CLK),
        .CLK_MOUSE(CLK_MOUSE),
        .DATA_MOUSE(DATA_MOUSE),
        .MouseStatus(MouseStatus),
        .MouseX(MouseX),
        .MouseY(MouseY),
        .INTERRUPT(SendInterrupt),
        .MouseDX(MouseDX),
        .MouseDY(MouseDY)
    );
    
    // Raise interrupt signal if mouse sends an interrupt
  always@(posedge CLK) begin
        if(RESET)
            Interrupt <= 1'b0;
        else if(SendInterrupt)
            Interrupt <= 1'b1;
        else if(BUS_INTERRUPT_ACK)
            Interrupt <= 1'b0;
  end
    
//Only place data on the bus if the processor is NOT writing, and it is addressing the correct address
assign BUS_DATA = (MouseBusWE) ? Out : 8'hZZ;
assign BUS_INTERRUPT_RAISE = Interrupt;
assign mousebytes[0] = MouseStatus;
assign mousebytes[1] = MouseX;
assign mousebytes[2] = MouseY;
assign mousebytes[3] = MouseDX;
assign mousebytes[4] = MouseDY;
    
    // Write to bus
  always@(posedge CLK) begin
       if((BUS_ADDR >= MouseBaseAddr) & (BUS_ADDR < MouseBaseAddr + 5)) begin
           if (BUS_WE)
                MouseBusWE <= 1'b0;
           else
                MouseBusWE <= 1'b1;
       end 
           else
               MouseBusWE <= 1'b0;
               Out <= mousebytes[BUS_ADDR[3:0]];
    end    
endmodule