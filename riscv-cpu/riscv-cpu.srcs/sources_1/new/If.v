
`include "define.v"

module If (
	input wire clk,
	input wire rst,

	input wire stall[5:0];
	input wire jump_flag_i,
	input wire[`InstAddr] jump_addr_i,

	input wire[`InstData] mem_i,
	output wire[`InstAddr] mem_o,

	output wire[`InstAddr] pc_o,
	output reg[`InstData] inst_o,
	output reg stall_o;
	output reg rec_o;
);

reg stall_i = stall[4];
reg[`InstAddr] pc0, pc1;

always @ (posedge clk or posedge rst) begin
	if (rst) begin
		pc0 <= `ZeroWord - 4;
	end else begin
		pc0 <= pc1;
	end
end

always @ (*) begin
	if (rst_in) begin
		pc1 = `ZeroWord;
		inst_o = `ZeroWord;
		rec_o = 1'b0;
		stall_o = stall_i;
	end else begin
		rec_o = 1'b1;
		inst_o = mem_i;
		if (jump_flag_i) begin
			pc1 = jump_addr_i;
			stall_o = 1'b0;
		end else begin
			stall_o = stall_i;
			if (stall_i) begin
				pc1 = pc0;
			end else begin
				pc1 = pc0 + 32'h4;
			end
		end
	end
end

assign mem_o = pc1;
assign pc_o = pc1;

endmodule

