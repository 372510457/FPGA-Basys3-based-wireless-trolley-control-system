`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/03/18 12:32:22
// Design Name: 
// Module Name: Seg7Peripheral
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


module Seg7Peripheral(
    input CLK,
    input RESET,
    input [7:0] BUS_ADDR,
    input [7:0] BUS_DATA,
    input BUS_WE,
    output [7:0] HEX_OUT, 
    output [3:0] SEG_SELECT
    );
    
    parameter [7:0] Seg7BaseAddress = 8'hD0;
    reg [15:0] ValueIn;
    wire [1:0] StrobeCount;
    wire [4:0] MuxOut;
    wire Bit17TriggOut;
    
    always@(posedge CLK) begin
        if (RESET)
            ValueIn <= 0; 
        else if (BUS_WE) begin
            if (BUS_ADDR == Seg7BaseAddress)
                ValueIn[15:8] <= BUS_DATA; 
            else if (BUS_ADDR == Seg7BaseAddress + 1)
                ValueIn[7:0] <= BUS_DATA;
        end
    end
        
//In 7-segment all four digits should be driven once every 
//1 to 16ms, for a refresh frequency of about 1 KHz to 60Hz. 100000
Generic_counter # (
     .COUNTER_WIDTH(17),
     .COUNTER_MAX(99999)
      )
        Bit17 (
            .RESET(0),
            .CLK(CLK),
            .ENABLE(1),
            .COUNT(),
            .TRIGGER_OUT(TriggOut)
    );
    
//SEG_SELECT_IN need 4 digits output:00,01,10,11
    Generic_counter # (
     .COUNTER_WIDTH(2),
     .COUNTER_MAX(3))
        Bit2 (
            .RESET(0),
            .CLK(CLK),
            .ENABLE(TriggOut),
            .COUNT(StrobeCount),
            .TRIGGER_OUT()
    ); 
    
    // Multiplexer to choose segment on 7-seg display
    Multiplexer_4 mul (
        .CONTROL(StrobeCount),
        .IN0({1'b0, ValueIn[3:0]}),
        .IN1({1'b0, ValueIn[7:4]}),
        .IN2({1'b1, ValueIn[11:8]}),
        .IN3({1'b0, ValueIn[15:12]}),
        .OUT(MuxOut)
    );
    
    seg7decoder decoder(
        .SEG_SELECT_IN(StrobeCount),
        .BIN_IN(MuxOut[3:0]),
        .DOT_IN(MuxOut[4]),
        .SEG_SELECT_OUT(SEG_SELECT),
        .HEX_OUT(HEX_OUT)
    );
    
endmodule