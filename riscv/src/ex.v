`include "defines.v"

module ex(
	input wire rst,

	input wire[`AluOpBus] aluop_i,
	input wire[`AluSelBus] alusel_i,
	input wire[`RegBus] reg1_i,
	input wire[`RegBus] reg2_i,
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,

	input wire jump_flag_i,
	input wire jump_addr_i,
	input wire rd_i,

	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o
);

reg[`RegBus] logic_out;
reg[`RegBus] shift_out;
reg[`RegBus] calc_out;
reg[`RegBus] jump_out;

// LOGIC operation

always @ (*) begin
	if (rst == `RstEnable) begin
		logic_out <= `ZeroWord;
	end else begin
		case (aluop_i)
			`EXE_OR_OP: begin
				logic_out <= reg1_i | reg2_i;
			end
			`EXE_AND_OP: begin
				logic_out <= reg1_i & reg2_i;
			end
			`EXE_XOR_OP: begin
				logic_out <= reg1_i ^ reg2_i;
			end
			default: begin
				logic_out <= `ZeroWord;
			end
		endcase
	end
end

// SHIFT operation

always @ (*) begin
	if (rst == `RstEnable) begin
		shift_out <= `ZeroWord;
	end else begin
		case (aluop_i)
			`EXE_SLL_OP: begin
				shift_out <= reg1_i << reg2_i[4:0];
			end
			`EXE_SRL_OP: begin
				shift_out <= reg1_i >> reg2_i[4:0];
			end
			`EXE_SRA_OP: begin
				shift_out <= $signed(reg1_i) >>> reg2_i[4:0];
			end
		endcase
	end
end

// CALC operation

always @ (*) begin
	if (rst == `RstEnable) begin
		calc_out <= `ZeroWord;
	end else begin
		case (aluop_i)
			`EXE_ADD_OP: begin
				calc_out <= reg1_i + reg2_i;
			end
			`EXE_SUB_OP: begin
				calc_out <= reg1_i - reg2_i;
			end
			`EXE_SLT_OP: begin
				calc_out <= ($signed(reg1_i) < $signed(reg2_i));
			end
			`EXE_SLTU_OP: begin
				calc_out <= (reg1_i < reg2_i);
			end
		endcase
	end
end

// JUMP operation

always @ (*) begin
	if (rst == `RstEnable) begin
		jump_out <= `ZeroWord;
	end else begin
		case (aluop_i)
			`EXE_JAL_OP: begin
				jump_out <= rd_i;
			end
			`EXE_JALR_OP: begin
				jump_out <= rd_i;
			end
			default: begin
				jump_out <= `ZeroWord;
			end
		endcase
	end
end

// LOAD STORE

always @ (*) begin
	if (rst == `RstEnable) begin
		  <= `ZeroWord;
	end else if (alusel_i == `EXE_RES_LOAD_STORE) begin
		if (aluop_i <= 3'b100) begin
			wdata_o <= rd_i;
		end else begin
			wdata_o <= reg1_i + reg2_i;
		end
	end
end

always @ (*) begin
	wd_o <= wd_i;
	wreg_o <= wreg_i;
	case (alusel_i)
		`EXE_RES_LOGIC: begin
			wdata_o <= logic_out;
		end
		`EXE_RES_SHIFT: begin
			wdata_o <= shift_out;
		end
		`EXE_RES_CALC: begin
			wdata_o <= calc_out;
		end
		`EXE_RES_JUMP: begin
			wdata_o <= jump_out;
		end
		default: begin
			wdata_o <= `ZeroWord;
		end
	endcase
end

endmodule
