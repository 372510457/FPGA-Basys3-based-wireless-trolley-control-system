`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University of Edinburgh
// Engineer: Hanlin WANG
// 
// Create Date: 2022/02/24 14:51:34
// Design Name: Mouse
// Module Name: MouseTransceiver
// Project Name: Mouse
// Target Devices: BASYS 3
// Tool Versions: 
// Description: This is the transceiver of the PS/2 mouse module.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MouseTransceiver(
    //Standard Inputs
	input RESET,
	input CLK,
    //IO - Mouse side
	inout CLK_MOUSE,
	inout DATA_MOUSE,
    // Mouse data information
	output reg [7:0] MouseStatus,
	output reg [7:0] MouseX,
	output reg [7:0] MouseY,
	output INTERRUPT,
	output [7:0] MouseDX,
    output [7:0] MouseDY
    );
    //  Define the direction of X and Y.
      
    // X, Y Limits of Mouse Position e.g. VGA Screen with 160 x 120 resolution
    parameter [7:0] MouseLimitX = 160;
    parameter [7:0] MouseLimitY = 120;

    initial begin
        MouseStatus <= 0;
        MouseX <= MouseLimitX/2;
        MouseY <= MouseLimitY/2;
    end
/////////////////////////////////////////////////////////////////////
    //TriState Signals
    //Clk
    reg ClkMouseIn;
    wire ClkMouseOutEnTrans;
    //Data
    wire DataMouseIn;
    wire DataMouseOutTrans;
    wire DataMouseOutEnTrans;

    //Clk Output - can be driven by host or device
    assign CLK_MOUSE = ClkMouseOutEnTrans ? 1'b0 : 1'bz;
    //Clk Input
    assign DataMouseIn = DATA_MOUSE;
    //Clk Output - can be driven by host or device
    assign DATA_MOUSE = DataMouseOutEnTrans ? DataMouseOutTrans : 1'bz;
/////////////////////////////////////////////////////////////////////
    //This section filters the incoming Mouse clock to make sure that 
    //it is stable before data is latched by either transmitter
    //or receiver modules
    reg [7:0]MouseClkFilter;
         always@(posedge CLK) begin
          if(RESET) 
            ClkMouseIn <= 1'b0;
          else begin
//A simple shift register
            MouseClkFilter[7:1] <= MouseClkFilter[6:0];
            MouseClkFilter[0] <= CLK_MOUSE;
//falling edge
            if(ClkMouseIn & (MouseClkFilter == 8'h00))
            ClkMouseIn <= 1'b0;
//rising edge
            else if(~ClkMouseIn & (MouseClkFilter == 8'hFF))
            ClkMouseIn <= 1'b1;
            end
         end
///////////////////////////////////////////////////////
    //Instantiate the Transmitter module
    wire SendByteToMouse;
    wire ByteSentToMouse;
    wire [7:0] ByteToSendToMouse;


MouseTransmitter T(
//Standard Inputs
.RESET (RESET),
.CLK(CLK),
//Mouse IO - CLK
.CLK_MOUSE_IN(ClkMouseIn),
.CLK_MOUSE_OUT_EN(ClkMouseOutEnTrans),
//Mouse IO - DATA
.DATA_MOUSE_IN(DataMouseIn),
.DATA_MOUSE_OUT(DataMouseOutTrans),
.DATA_MOUSE_OUT_EN(DataMouseOutEnTrans),
//Control
.SEND_BYTE(SendByteToMouse),
.BYTE_TO_SEND(ByteToSendToMouse),
.BYTE_SENT(ByteSentToMouse)
);
///////////////////////////////////////////////////////
    //Instantiate the Receiver module

    wire [3:0] MasterStateCode;
    wire ReadEnable;
    wire [7:0] ByteRead;
    wire [1:0] ByteErrorCode;
    wire ByteReady;

MouseReceiver R(
//Standard Inputs
.RESET(RESET),
.CLK(CLK),
//Mouse IO - CLK
.CLK_MOUSE_IN(ClkMouseIn),
//Mouse IO - DATA
.DATA_MOUSE_IN(DataMouseIn),
//Control
.READ_ENABLE (ReadEnable),
.BYTE_READ(ByteRead),
.BYTE_ERROR_CODE(ByteErrorCode),
.BYTE_READY(ByteReady)

);

///////////////////////////////////////////////////////
//Instantiate the Master State Machine module
    wire [7:0] MouseStatusRaw;
    wire [7:0] MouseDxRaw;
    wire [7:0] MouseDyRaw;
    wire SendInterrupt;

MouseMasterSM MSM(
//Standard Inputs
.RESET(RESET),
.CLK(CLK),
//Transmitter Interface
.SEND_BYTE(SendByteToMouse),
.BYTE_TO_SEND(ByteToSendToMouse),
.BYTE_SENT(ByteSentToMouse),
//Receiver Interface
.READ_ENABLE (ReadEnable),
.BYTE_READ(ByteRead),
.BYTE_ERROR_CODE(ByteErrorCode),
.BYTE_READY(ByteReady),
//Data Registers
.MOUSE_STATUS(MouseStatusRaw),
.MOUSE_DX(MouseDxRaw),
.MOUSE_DY(MouseDyRaw),
.SEND_INTERRUPT(SendInterrupt),
.CURR_STATE(MasterStateCode)
);

/*ila_0 your_instance_name (
	.clk(CLK), // input wire clk


	.probe0(RESET), // input wire [0:0]  probe0  
	.probe1(CLK_MOUSE), // input wire [0:0]  probe1 
	.probe2(DATA_MOUSE), // input wire [0:0]  probe2 
	.probe3(ByteErrorCode), // input wire [1:0]  probe3 
	.probe4(MasterStateCode), // input wire [3:0]  probe4 
	.probe5(ByteToSendToMouse), // input wire [7:0]  probe5 
	.probe6(ByteRead) // input wire [7:0]  probe6
);*/
//Pre-processing - handling of overflow and signs.
//More importantly, this keeps tabs on the actual X/Y
//location of the mouse.
    assign MouseDX = MouseDxRaw;
    assign MouseDY = MouseDyRaw;
    assign INTERRUPT = SendInterrupt;

    wire signed [8:0] MouseDx;
    wire signed [8:0] MouseDy;
    wire signed [8:0] MouseNewX;
    wire signed [8:0] MouseNewY;
//DX and DY are modified to take account of overflow and direction
    assign MouseDx = (MouseStatusRaw[6]) ? (MouseStatusRaw[4] ? {MouseStatusRaw[4],8'h00} : 
{MouseStatusRaw[4],8'hFF} ) : {MouseStatusRaw[4],MouseDxRaw[7:0]};


// assign the proper expression to MouseDy
// My code:
    assign MouseDy = (MouseStatusRaw[7]) ? (MouseStatusRaw[5] ? {MouseStatusRaw[5],8'h00} : {MouseStatusRaw[5],8'hFF} ) : {MouseStatusRaw[5], MouseDyRaw[7:0]};

 // calculate new mouse position

    assign MouseNewX = {1'b0,MouseX} + MouseDx;
    assign MouseNewY = {1'b0,MouseY} + MouseDy; 

	
    always@(posedge CLK) begin
              if(RESET) begin
                  MouseStatus <= 0;
                  MouseX <= MouseLimitX/2;
                  MouseY <= MouseLimitY/2;
              end else if (SendInterrupt) begin
//Status is stripped of all unnecessary info
                  MouseStatus <= MouseStatusRaw;
//X is modified based on DX with limits on max and min
                  if(MouseNewX < 0)
                      MouseX <= 0;
                  else if(MouseNewX > (MouseLimitX-1))
                      MouseX <= MouseLimitX-1;
                  else
                      MouseX <= MouseNewX[7:0];

//Y is modified based on DY with limits on max and min
//My code:
                  if (MouseNewY < 0)
                      MouseY <= 0;
                  else if (MouseNewY > (MouseLimitY-1))
                      MouseY <= MouseLimitY-1;
                  else
                      MouseY <= MouseNewY[7:0];

                  end
end
endmodule
