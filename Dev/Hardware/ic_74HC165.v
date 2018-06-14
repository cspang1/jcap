// File:	74HC165.v
// Author:	Connor Spangler
// Date:	05/24/2017
// Version:	3.0
// Description: 
// 		This file contains the verilog specification for the
//		74HC165 8-bit serial or parallel-in/serial-out shift
//		register. 

`timescale 1 ns/1 ns

module ic_74HC165 (
		PL_n, CP, Q7_n, Q7, DS, DN, CE_n
	);

	// Pin definitions
	input wire PL_n;		// Asynchronous parallel load input (active low)
	input wire CP;			// Clock input
	input wire DS;			// Serial data input
	input wire [7:0] DN;		// Parallel data inputs
	input wire CE_n;		// Clock enable input (active low)
	output wire Q7_n;		// Complimentary serial output
	output wire Q7;			// Serial output
	
	// Timing characteristics
	parameter T_PD_C_Q7 = 16;								// CP/CE_n to Q7/Q7_n propogation delay
	parameter T_PD_PL_Q7 = 15;								// PL_n to Q7/Q7_n propogation delay
	parameter T_PD_D7_Q7 = 11;								// D7 to Q7/Q7_n propogation delay
	parameter T_PD_PL_D7 = T_PD_PL_Q7 - T_PD_D7_Q7;						// PL_n to D7 propogation delay

	// Functional characteristics
	reg [7:0] shift_reg;								// Internal shift register
	assign #T_PD_D7_Q7 Q7 = shift_reg[7];		// Output MSB of shift register
	assign #T_PD_D7_Q7 Q7_n = ~shift_reg[7];	// Output complimentary MSB of shift register
	
	always @ (posedge CP or negedge PL_n) begin	// Pos clock edge triggered/async parallel load
		if (!PL_n) begin
			#T_PD_PL_D7 shift_reg = DN;	// Load parallel inputs into internal shift register
		end else if (!CE_n) begin				// Active low clock enable
			shift_reg = shift_reg << 1;	// Shift internal register
			shift_reg[0] = DS;				// Shift in from serial in 
		end
	end

endmodule
