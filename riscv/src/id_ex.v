`include "defines.v"

module id_ex(
	input wire clk,
	input wire rst,

	input wire[`AluOpBus] id_aluop,
	input wire[`AluSelBus] id_alusel,
	input wire[`RegBus] id_reg1,
	input wire[`RegBus] id_reg2,
	input wire[`RegAddrBus] id_wd,
	input wire id_wreg,

	input wire id_jump_flag,
	input wire[`RegBus] id_jump_addr,

	output reg[`AluOpBus] ex_aluop,
	output reg[`AluSelBus] ex_alusel,
	output reg[`RegBus] ex_reg1,
	output reg[`RegBus] ex_reg2,
	output reg[`RegAddrBus] ex_wd,
	output reg ex_wreg

	output reg ex_jump_flag,
	output reg[`RegBus] ex_jump_addr,

);

always @ (posedge clk) begin
	if (rst == `RstEnable) begin
		ex_aluop <= `EXE_NOP_OP;
		ex_alusel <= `EXE_RES_NOP;
		ex_reg1 <= `ZeroWord;
		ex_reg2 <= `ZeroWord;
		ex_wd <= `NOPRegAddr;
		ex_wreg <= `WriteDisable;
	end else begin
		ex_aluop <= id_aluop;
		ex_alusel <= id_alusel;
		ex_reg1 <= id_reg1;
		ex_reg2 <= id_reg2;
		ex_wd <= id_wd;
		ex_wreg <= id_wreg;
	end
end

endmodule

