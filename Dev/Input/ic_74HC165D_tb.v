`timescale 1 ns/1 ns

module ic_74HC165D_tb;
	reg PL_n;
	reg clk;
	reg [7:0] DN1, DN2;
	reg CE_n;
	wire out1;
	wire out2;
	
	parameter min_per = 9;
	parameter t_W_pl = 16;
	parameter t_su_ds_c = 16;
	parameter t_su_c = 16;
	parameter t_su_dn_pl = 16;
	parameter t_h_ds_c = 5;
	parameter t_h_dn_pl = 5;
	parameter t_h_c = 5;
	parameter t_rec_pl_c = 20;

	ic_74HC165D sreg1(
		.PL_n(PL_n),
		.CP(clk),
		.DS(1'b0),
		.DN(DN1),
		.CE_n(CE_n),
		.Q7_n(),
		.Q7(out1)
	);
	
	ic_74HC165D sreg2(
		.PL_n(PL_n),
		.CP(clk),
		.DS(out1),
		.DN(DN2),
		.CE_n(CE_n),
		.Q7_n(),
		.Q7(out2)
	);
	
	initial begin
		clk = 0;
		CE_n = 1;
		PL_n = 1;
		DN1 = 8'b10101010;
		DN2 = 8'b10101010;
		#t_su_dn_pl
		PL_n = 0;
		#t_W_pl
		PL_n = 1;
		#t_rec_pl_c
		CE_n = 0;
		clk = !clk;
		repeat (29) begin
			#min_per
			clk = !clk;
		end
		DN1 = 8'b01010101;
		DN2 = 8'b01010101;
		#t_su_dn_pl
		PL_n = 0;
		#t_W_pl
		PL_n = 1;
		#t_rec_pl_c
		clk = !clk;
		repeat (29) begin
			#min_per
			clk = !clk;
		end
		DN1 = 8'b11110000;
		DN2 = 8'b11110000;
		#t_su_dn_pl
		PL_n = 0;
		#t_W_pl
		PL_n = 1;
		#t_rec_pl_c
		clk = !clk;
		repeat (29) begin
			#min_per
			clk = !clk;
		end
		DN1 = 8'b00001111;
		DN2 = 8'b00001111;
		#t_su_dn_pl
		PL_n = 0;
		#t_W_pl
		PL_n = 1;
		#t_rec_pl_c
		clk = !clk;
		repeat (30) begin
			#min_per
			clk = !clk;
		end
	end

endmodule
