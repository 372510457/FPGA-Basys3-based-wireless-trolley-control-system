`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/02/08 17:10:13
// Design Name: 
// Module Name: TenHz_cnt
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a ten Hz counter to generate the signal of SEND_PACKET.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module TenHz_cnt(
    input CLK,
    input RESET,
    output reg SEND_PACKET
    );
    
	reg [23:0] COUNT;	
	
	initial begin
		COUNT <= 0;					
	end
		
	always@ (posedge CLK) begin
		if (RESET) 		
			COUNT <= 0;
		else begin
				if (COUNT == 10000000)	
					COUNT <= 0;
				else 
					COUNT <= COUNT + 1;	
		end
	end
	
	always @(posedge CLK) begin
		if (RESET)					
			SEND_PACKET <= 0;
		else begin
			if (COUNT == 10000000)
				SEND_PACKET <= 1;
			else						
				SEND_PACKET <= 0;	
		end
	end

endmodule
