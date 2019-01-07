`include "defines.v"

module id(
	input wire rst,
	input wire[`InstAddrBus] pc_i,
	input wire[`InstBus] inst_i,

	input wire[`RegBus] reg1_data_i,
	input wire[`RegBus] reg2_data_i,

	output reg reg1_read_o,
	output reg reg2_read_o,
	output reg[`RegAddrBus] reg1_addr_o,
	output reg[`RegAddrBus] reg2_addr_o,

	output reg[`AluOpBus] aluop_o,
	output reg[`AluSelBus] alusel_o,
	output reg[`RegBus] reg1_o,
	output reg[`RegBus] reg2_o,
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o

	output reg jump_flag_o;
	output reg[`RegBus] jump_addr_o;
);

wire[6:0] op = inst_i[6:0];
wire[2:0] funct3 = inst_i[14:12];
wire[6:0] funct7 = inst_i[31:25];

reg[`RegBus] imm;

reg instvalid;

// 1st-stage: decode

always @ (*) begin
	if (rst == `RstEnable) begin
		aluop_o <= `EXE_NOP_OP;
		alusel_o <= `EXE_RES_NOP;
		wd_o <= `NOPRegAddr;
		wreg_o <= `WriteDisable;
		instvalid <= `InstValid;
		reg1_read_o <= 1'b0;
		reg2_read_o <= 1'b0;
		reg1_addr_o <= `NOPRegAddr;
		reg2_addr_o <= `NOPRegAddr;
		imm <= 32'h0;
	end else begin
		reg1_read_o = 1'b0;
		reg2_read_o = 1'b0;
		reg1_addr_o = inst_i[19:15];
		reg2_addr_o = inst_i[24:20];
		instvalid = `InstValid;
		wreg_o = `WriteEnable;
		wd_o = inst_i[11:7];

		case (op)
			`EXE_LUI: begin
				aluop_o <= `EXE_OR_OP;
				alusel_o <= `EXE_RES_LOGIC;
				imm <= {inst_i[31:12],12'h0};
			end
			`EXE_AUIPC: begin
				aluop_o <= `EXE_OR_OP;
				alusel_o <= `EXE_RES_LOGIC;
				imm <= pc_i + {inst_i[31:12],12'h0};
			end
			`EXE_JAL: begin
				aluop_o <= `EXE_JAL_OP;
				alusel_o <= `EXE_RES_JUMP;
				imm <= {{12{inst_i[31]}},
					inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};
				jump_flag_o <= `JUMP;
				jump_addr_o <= {{12{inst_i[31]}},
					inst_i[19:12],inst_i[20],inst_i[30:21],1'b0};
			end
			`EXE_JALR: begin
				reg1_read_o <= 1'b1;
				aluop_o <= `EXE_JALR_OP;
				alusel_o <= `EXE_RES_JUMP;
				imm <= pc_i + 32'h4;
				jump_flag_o <= `JUMP;
				jump_addr_o <= ({20{inst_i[31]},inst_i[31:20]} >> 1) << 1;
			end
			`EXE_BXX: begin
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b1;
				imm <= {20{inst_i[31]},
					inst_i[7], inst[11:8], inst_i[30:25], 1'b0};
				jump_flag_o <= `NOJUMP;
				jump_addr_o <= {20{inst_i[31]},
					inst_i[7], inst[11:8], inst_i[30:25], 1'b0};
				wreg_o = `WritedDisable;
				case (funct3)
					`EXE_BEQ: begin
						aluop_o <= `EXE_BEQ_OP;
						alusel_o <= `EXE_RES_JUMP;
						jump_flag_o <= (reg1_data_i == reg2_data_i);
					end
					`EXE_BNE: begin
						aluop_o <= `EXE_BNE_OP;
						alusel_o <= `EXE_RES_JUMP;
						jump_flag_o <= (reg1_data_i != reg2_data_i);
					end
					`EXE_BLT: begin
						aluop_o <= `EXE_BLT_OP;
						alusel_o <= `EXE_RES_JUMP;
						jump_flag_o <=
							($signed(reg1_data_i) < $signed(reg2_data_i));
					end
					`EXE_BGE: begin
						aluop_o <= `EXE_BGE_OP;
						alusel_o <= `EXE_RES_JUMP;
						jump_flag_o <=
							($signed(reg1_data_i) >= $signed(reg2_data_i));
					end
					`EXE_BLTU: begin
						aluop_o <= `EXE_BLTU_OP;
						alusel_o <= `EXE_RES_JUMP;
						jump_flag_o <= (reg1_data_i < reg2_data_i);
					end
					`EXE_BGEU: begin
						aluop_o <= `EXE_BGEU_OP;
						alusel_o <= `EXE_RES_JUMP;
						jump_flag_o <= (reg1_data_i >= reg2_data_i);
					end
				endcase
			end
			`EXE_LOAD: begin
				reg1_read_o <= 1'b1;
				imm <= {20{inst_i[31]},inst_i[31:20]};
				alusel_o <= `EXE_RES_LOAD_STORE;
				case (funct3)
					`EXE_LB: begin
						aluop_o <= `EXE_LB_OP; // 8-bit
					end
					`EXE_LH: begin
						aluop_o <= `EXE_LH_OP; // 16-bit
					end
					`EXE_LW: begin
						aluop_o <= `EXE_LW_OP; // 32-bit
					end
					`EXE_LBU: begin
						aluop_o <= `EXE_LBU_OP; // 8-bit unsigned-extended
					end
					`EXE_LHU: begin
						aluop_o <= `EXE_LHU_OP; // 16-bit unsigned-extended
					end
				endcase
			end
			`EXE_SAVE: begin
				reg1_read_o <= 1'b1;
				reg2_read_o <= 1'b1;
				imm <= {20{inst_i[31]},inst_i[31:25], inst_i[11:7]};
				alusel_o <= `EXE_RES_LOAD_STORE;
				wreg_o <= `WriteDisable; // TODO check
				case (funct3)
					`EXE_SB: begin
						aluop_o <= `EXE_SB_OP; // low 8-bit, [7:0]
					end
					`EXE_SH: begin
						aluop_o <= `EXE_SH_OP; // low 16-bit, [15:0]
					end
					`EXE_SW: begin
						aluop_o <= `EXE_SW_OP; // 32-bit
					end
				endcase
			end
			`EXE_IMM: begin
				reg1_read_o <= 1'b1;
				imm <= {20{inst_i[31]},inst_i[31:20]};
				case (funct3)
					`EXE_ADDI: begin
						aluop_o <= `EXE_ADD_OP;
						alusel_o <= `EXE_RES_CALC;
					end
					`EXE_SLTI: begin
						aluop_o <= `EXE_SLT_OP;
						alusel_o <= `EXE_RES_CALC;
					end
					`EXE_SLTIU: begin
						aluop_o <= `EXE_SLTU_OP;
						alusel_o <= `EXE_RES_CALC;
					end
					`EXE_XORI: begin
						aluop_o <= `EXE_XOR_OP;
						alusel_o <= `EXE_RES_LOGIC;
					end
					`EXE_ORI: begin
						aluop_o <= `EXE_OR_OP;
						alusel_o <= `EXE_RES_LOGIC;
					end
					`EXE_ANDI: begin
						aluop_o <= `EXE_AND_OP;
						alusel_o <= `EXE_RES_LOGIC;
					end
					`EXE_SLLI: begin
						aluop_o <= `EXE_SLL_OP;
						alusel_o <= `EXE_RES_SHIFT;
					end
					`EXE_SRXX: begin
						case (funct7)
							`EXE_SRLI: begin
								aluop_o <= `EXE_SRL_OP;
								alusel_o <= `EXE_RES_SHIFT;
							end
							`EXE_SRAI: begin
								aluop_o <= `EXE_SRA_OP;
								alusel_o <= `EXE_RES_SHIFT;
							end
						endcase
					end
				endcase
			end
			`EXE_TWO: begin
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b1;

				case (funct3)
					`EXE_ADD_OR_SUB: begin
						case (funct7)
							`EXE_ADD: begin
								aluop_o <= `EXE_ADD_OP;
								alusel_o <= `EXE_RES_CALC;
							end
							`EXE_SUB: begin
								aluop_o <= `EXE_SUB_OP;
								alusel_o <= `EXE_RES_CALC;
							end
						endcase
					end
					`EXE_SLL: begin
						aluop_o <= `EXE_SLL_OP;
						alusel_o <= `EXE_RES_SHIFT;
					end
					`EXE_SLT: begin
						aluop_o <= `EXE_SLT_OP;
						alusel_o <= `EXE_RES_CALC;
					end
					`EXE_SLTU: begin
						aluop_o <= `EXE_SLTU_OP;
						alusel_o <= `EXE_RES_CALC;
					end
					`EXE_XOR: begin
						aluop_o <= `EXE_XOR_OP;
						alusel_o <= `EXE_RES_LOGIC;
					end
					`EXE_SRX: begin
						case (funct7)
							`EXE_SRL: begin
								aluop_o <= `EXE_SRL_OP;
								alusel_o <= `EXE_RES_SHIFT;
							end
							`EXE_SRA: begin
								aluop_o <= `EXE_SRA_OP;
								alusel_o <= `EXE_RES_SHIFT;
							end
						endcase
					end
					`EXE_OR: begin
						aluop_o <= `EXE_OR_OP;
						alusel_o <= `EXE_RES_LOGIC;
					end
					`EXE_AND: begin
						aluop_o <= `EXE_AND_OP;
						alusel_o <= `EXE_RES_LOGIC;
					end
				endcase
			end
			default: begin
				aluop_o <= `EXE_NOP_OP;
				alusel_o <= `EXE_RES_NOP;
				wd_o <= inst_i[11:7];
				wreg_o <= `WriteDisable;
				instvalid <= `InstInvalid;
				reg1_addr_o <= inst_i[24:20];
				reg2_addr_o <= inst_i[19:15];
				imm <= `ZeroWord;
			end
		endcase
	end
end

// 2nd get operands

always @ (*) begin
	if (rst == `RstEnable) begin
		reg1_o <= `ZeroWord;
	end else if (reg1_read_o == 1'b1) begin
		reg1_o <= reg1_data_i;
	end else if (reg1_read_o == 1'b0) begin
		reg1_o <= imm;
	end else begin
		reg1_o <= `ZeroWord;
	end
end

always @ (*) begin
	if (rst == `RstEnable) begin
		reg2_o <= `ZeroWord;
	end else if (reg2_read_o == 1'b1) begin
		reg2_o <= reg2_data_i;
	end else if (reg2_read_o == 1'b0) begin
		reg2_o <= imm;
	end else begin
		reg2_o <= `ZeroWord;
	end
end

endmodule
