`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/02/08 17:04:02
// Design Name: 
// Module Name: IRTransmitterSM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is the IR transmitter state machine.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module IRTransmitterSM(
    input CLK,
    input RESET,
    input SEND_PACKET,
    input [3:0] COMMAND,
    output reg IR_LED
    );
       
    reg TRI_OUT1;
    reg CLK_PU = 0;
     
    parameter COUNTER_WIDTH = 12;	
	parameter COUNTER_MAX = 1387;		
	reg [COUNTER_WIDTH-1:0] COUNT;	
    
    //Bule car parameters
    parameter StartBurstSize        = 191;
    parameter GapSize               = 25;
    parameter CarSelectBurstSize    = 47;
    parameter AssertBurstSize       = 47;
    parameter DeassertBurstSize     = 22;
  
    
    //state machine parameter
    reg [3:0] CurrentState;
	reg [3:0] CurrentCommand;
	reg PACKET_COUNT_R;
	
	parameter COUNTER_MAX2 = 192;
	parameter COUNTER_WIDTH2 = 8;	
	reg [COUNTER_WIDTH2 -1:0] COUNT2;
	reg OUT;
	reg [3:0] STATE_OUT;
	
    initial begin
		COUNT <= 0;					
	end
		
	always@ (posedge CLK) begin
		if (RESET) 		
			COUNT <= 0;
		else begin
				if (COUNT == COUNTER_MAX)	// When the count reaches its maximum, set it to zero
					COUNT <= 0;
				else 
					COUNT <= COUNT + 1;	//otherwise continue counting.
			end
		end
	
	
	always @(posedge CLK) begin
		if (RESET)					
			TRI_OUT1 <= 0;
		else begin
			   if (COUNT == COUNTER_MAX)
				TRI_OUT1 <= 1;
			   else						
				TRI_OUT1 <= 0;	
		end
	end

    
    always@(posedge TRI_OUT1)
     CLK_PU <= ~CLK_PU;
    
    initial begin
		COUNT2 <= 0;					
	end
     always@ (posedge CLK_PU) begin
		if (PACKET_COUNT_R) 		
			COUNT2 <= 0;
		else begin
				if (COUNT2 == COUNTER_MAX2)	
					COUNT2 <= 0;
			
				else 
					COUNT2 <= COUNT2 + 1;
				end
		end
	  
    initial begin
    OUT <= 0;
    end
    always@(posedge CLK_PU or posedge SEND_PACKET)begin
      if(RESET || SEND_PACKET)begin
        CurrentState <= 0;
        CurrentCommand <= COMMAND;
        PACKET_COUNT_R <= 1;
        OUT <= 0;
        end
        else begin
          case (CurrentState)
          
         //StartBurst
          4'b0000: begin if(COUNT2 == StartBurstSize -1) begin 
                            CurrentState <= 4'b0001;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                             else begin
                             PACKET_COUNT_R <= 0;
                             OUT <= 1;
                             end
                      end
         //Gap 1             
          4'b0001: begin if(COUNT2 == GapSize  - 1) begin 
                            CurrentState <= 4'b0010;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 0;
                              end
                       end
          // CarSelectBurst           
          4'b0010: begin if(COUNT2 == CarSelectBurstSize- 1) begin 
                            CurrentState <= 4'b0011;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 1;
                              end
                       end
          //Gap 2             
          4'b0011: begin if(COUNT2 == GapSize  - 1) begin 
                            CurrentState <= 4'b0100;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 0;
                              end
                       end
          // If car turn right or not        
          4'b0100: begin if(CurrentCommand[0] ==1)begin
                          if(COUNT2 == AssertBurstSize  - 1) begin 
                            CurrentState <= 4'b0101;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 1;
                              end
                       end
                       else begin if(COUNT2 == DeassertBurstSize  - 1) begin 
                            CurrentState <= 4'b0101;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 1;
                              end   
                          end        
                   end    
           // gap 3           
           4'b0101: begin if(COUNT2 == GapSize  - 1) begin 
                            CurrentState <= 4'b0110;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 0;
                              end
                       end  
          // If car turn left or not          
           4'b0110: begin if(CurrentCommand[1] ==1)begin
                          if(COUNT2 == AssertBurstSize  - 1) begin 
                            CurrentState <= 4'b0111;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 1;
                              end
                       end
                       else begin if(COUNT2 == DeassertBurstSize  - 1) begin 
                            CurrentState <= 4'b0111;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 1;
                              end   
                          end  
                     end  
           //gap 4
           4'b0111: begin if(COUNT2 == GapSize  - 1) begin 
                            CurrentState <= 4'b1000;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 0;
                              end
                       end
           //If car go back or not            
           4'b1000: begin if(CurrentCommand[2] ==1)begin
                          if(COUNT2 == AssertBurstSize  - 1) begin 
                            CurrentState <= 4'b1001;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 1;
                              end
                       end
                       else begin if(COUNT2 == DeassertBurstSize  - 1) begin 
                            CurrentState <= 4'b1001;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 1;
                              end   
                          end  
                     end  
           // gap 5          
           4'b1001: begin if(COUNT2 == GapSize  - 1) begin 
                            CurrentState <= 4'b1010;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 0;
                              end
                     end
          //If car turn forward or not           
           4'b1010: begin if(CurrentCommand[3] ==1)begin
                          if(COUNT2 == AssertBurstSize  - 1) begin 
                            CurrentState <= 4'b1011;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 1;
                              end
                       end
                       else begin if(COUNT2 == DeassertBurstSize  - 1) begin 
                            CurrentState <= 4'b1011;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 1;
                              end   
                          end  
                     end 
           //gap 6           
           4'b1011: begin if(COUNT2 == GapSize  - 1) begin 
                            CurrentState <= 4'b1100;
                            PACKET_COUNT_R <= 1;
                            OUT <= 0;
                            end
                              else begin
                              PACKET_COUNT_R <= 0;
                              OUT <= 0;
                              end
                     end        
            4'b1100: begin
                OUT <= 0;
            end
           default: CurrentState <= 4'b0000;
           endcase
       end
       
   end   
    
    always@(posedge CLK) IR_LED <= CLK_PU && OUT;
       
endmodule
