//Coded by Daniel Felipe Acosta Castro 
//Last update 27/04/2025
//Design task (week 3) Digital Design 
//Module: Up/Down 8 bit ripple counter with parallel load and synchronous reset

module Up_Donw_8bit (
	input wire clk,		//Clok - 1 bit
	input wire rt,		//Synchronous Reset - 1 bit
	input wire Up_Down,	//Direction Control -1 bit (1=Up, 0=Down)
	input wire ld,		//Load Eneable
	input wire [7:0] D,	//Data input - 8 bit
	output wire [7:0] Q,	//Output - 8 bit
);
	reg [7:0] Q_reg;

	always @(posedge clk) begin
		if (rt) begin
			Q_reg <= 8'b0;		//synchronous reset
		if (ld) begin
			Q_reg <= D;		//Carga de valor
		end else if (Up_Down) begin
			Q_reg <= Q_reg + 1;	//Conteo Ascendente
		end else
			Q_reg <= Q_reg - 1;	//Conteo Descendente
	end

	assign Q = Q_reg;			//Connect register to output
endmodule
