`include "defines.v"

module(
	input wire rst,

	input wire stall_if,
	input wire stall_id,
	input wire stall_ex,
	input wire stall_mem,

	output reg[5:0] stall,
);

always @ (*) begin
	if (rst == `RstEnable) begin
		stall <= 6'b000000;
	end else if (stall_if == `STOP) begin
		stall <= 6'b001111;
	end else if (stall_id == `STOP) begin
		stall <= 6'b000111;
	end else if (stall_ex == `STOP) begin
		stall <= 6'b000011;
	end else if (stall_mem == `STOP) begin
		stall <= 6'b000001;
	end else begin
		stall <= 6'b000000;
	end
end

endmodule
