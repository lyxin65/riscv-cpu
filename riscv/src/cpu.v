// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "defines.v"

module cpu(
	input  wire                 clk,			// system clock signal
	input  wire                 rst,			// reset signal
	input  wire                 rdy,			// ready signal, pause cpu when low

	input  wire [ 7:0]          mem_din,		// data input bus
	output wire [ 7:0]          mem_dout,		// data output bus
	output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
	output wire                 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

localparam READ = 0;
localparam WRITE = 1;
localparam NONE = 0;
localparam STATE_READ = 1;
localparam STATE_WRITE = 2;
localparam INVALID_STATE = 32'h3f3f3f3f;

reg[7:0] out;
reg[31:0] addr;
reg tag;
reg[31:0] debug;

assign mem_dout = out;
assign mem_a = addr;
assign mem_wr = tag;
assign dbgreg_dout = debug;

reg[3:0] i;
reg[31:0] inst;
reg[31:0] pc;
reg[31:0] pc0;
reg[31:0] newpc;
reg[31:0] R[0:31];

wire[6:0] op;
wire[4:0] rd;
wire[2:0] funct3;
wire[4:0] rs1;
wire[4:0] rs2;
wire[6:0] funct7;
reg[31:0] imm;

assign op = inst[6:0];
assign rd = inst[11:7];
assign funct3 = inst[14:12];
assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign funct7 = inst[31:25];

reg[1:0] mem_state;
reg[2:0] mem_cnt;
reg is_signed;
reg[31:0] mem_addr;
reg[4:0] reg_addr;
reg[31:0] mem_data;

always @(posedge clk) begin
	if (rst) begin
		i = 0;
		pc = 0;
		mem_state = 0;
		R[0] = 0; // TODO
	end else if (!rdy) begin
		// pause
	end else begin
		case (i)
			0: begin
				pc0 = pc;
				addr = pc;
				tag = READ;
				pc = pc + 1;
				i = i + 1;
			end
			1: begin
				addr = pc;
				tag = READ;
				pc = pc + 1;
				i = i + 1;
			end
			2: begin
				inst[7:0] = mem_din;
				addr = pc;
				tag = READ;
				pc = pc + 1;
				i = i + 1;
			end
			3: begin
				inst[15:8] = mem_din;
				addr = pc;
				tag = READ;
				pc = pc + 1;
				i = i + 1;
			end
			4: begin
				inst[23:16] = mem_din;
				i = i + 1;
			end
			5: begin
				inst[31:24] = mem_din;
				i = i + 1;
			end
			6: begin
				mem_state = NONE;
				mem_cnt = 0;

				case (op)
					`EXE_LUI: begin
						R[rd] = {inst[31:12],12'b0};
					end
					`EXE_AUIPC: begin
						R[rd] = pc0 + {inst[31:12],12'b0};
					end
					`EXE_JAL: begin
						if (rd) R[rd] = pc;
						pc = pc0 + {{{12{inst[31]}},
							inst[19:12],inst[20],inst[30:21],1'b0}};
					end
					`EXE_JALR: begin
						if (rd) R[rd] = pc;
						pc = (R[rs1] + ({{20{inst[31]}},inst[31:20]})) & 32'hFFFFFE; // TODO
					end
					`EXE_BXX: begin
						newpc = pc0 + {{20{inst[31]}},
							inst[7], inst[30:25], inst[11:8], 1'b0};
						case (funct3)
							`EXE_BEQ: begin
								if (R[rs1] == R[rs2])
									pc = newpc;
							end
							`EXE_BNE: begin
								if (R[rs1] != R[rs2])
									pc = newpc;
							end
							`EXE_BLT: begin
								if ($signed(R[rs1]) < $signed(R[rs2]))
									pc = newpc;
							end
							`EXE_BGE: begin
								if ($signed(R[rs1]) >= $signed(R[rs2]))
									pc = newpc;
							end
							`EXE_BLTU: begin
								if (R[rs1] < R[rs2])
									pc = newpc;
							end
							`EXE_BGEU: begin
								if (R[rs1] >= R[rs2])
									pc = newpc;
							end
						endcase
					end
					`EXE_LOAD: begin
						mem_state = STATE_READ;
						imm = {{20{inst[31]}},inst[31:20]};
						mem_addr = R[rs1] + imm;
						reg_addr = rd;
						case (funct3)
							`EXE_LB: begin
								is_signed = 0;
								mem_cnt = 1;
							end
							`EXE_LH: begin
								is_signed = 0;
								mem_cnt = 2;
							end
							`EXE_LW: begin
								is_signed = 0;
								mem_cnt = 4;
							end
							`EXE_LBU: begin
								is_signed = 1;
								mem_cnt = 1;
							end
							`EXE_LHU: begin
								is_signed = 1;
								mem_cnt = 2;
							end
						endcase
					end
					`EXE_SAVE: begin
						mem_state = STATE_WRITE;
						imm = {{20{inst[31]}},inst[31:25],inst[11:7]};
						mem_addr = R[rs1] + imm;
						reg_addr = rs2;
						case (funct3)
							`EXE_SB: begin
								mem_cnt = 1; // low 8-bit, [7:0]
							end
							`EXE_SH: begin
								mem_cnt = 2; // low 16-bit, [15:0]
							end
							`EXE_SW: begin
								mem_cnt = 4; // 32-bit
							end
						endcase
					end
					`EXE_IMM: begin
						imm = {{20{inst[31]}},inst[31:20]};
						case (funct3)
							`EXE_ADDI: begin
								R[rd] = R[rs1] + imm;
							end
							`EXE_SLTI: begin
								R[rd] = $signed(R[rs1]) < $signed(imm);
							end
							`EXE_SLTIU: begin
								R[rd] = R[rs1] < imm;
							end
							`EXE_XORI: begin
								R[rd] = R[rs1] ^ imm;
							end
							`EXE_ORI: begin
								R[rd] = R[rs1] | imm;
							end
							`EXE_ANDI: begin
								R[rd] = R[rs1] & imm;
							end
							`EXE_SLLI: begin
								R[rd] = R[rs1] << imm[4:0];
							end
							`EXE_SRXX: begin
								case (funct7)
									`EXE_SRLI: begin
										R[rd] = R[rs1] >> imm[4:0];
									end
									`EXE_SRAI: begin
										R[rd] = $signed(R[rs1]) >>> imm[4:0];
									end
								endcase
							end
						endcase
					end
					`EXE_TWO: begin
						case (funct3)
							`EXE_ADD_OR_SUB: begin
								case (funct7)
									`EXE_ADD: begin
										R[rd] = R[rs1] + R[rs2];
									end
									`EXE_SUB: begin
										R[rd] = R[rs1] - R[rs2];
									end
								endcase
							end
							`EXE_SLL: begin
								R[rd] = R[rs1] << R[rs2][4:0]; // TODO
							end
							`EXE_SLT: begin
								R[rd] = $signed(R[rs1]) < $signed(R[rs2]);
							end
							`EXE_SLTU: begin
								R[rd] = R[rs1] < R[rs2];
							end
							`EXE_XOR: begin
								R[rd] = R[rs1] ^ R[rs2];
							end
							`EXE_SRX: begin
								case (funct7)
									`EXE_SRL: begin
										R[rd] = R[rs1] >> R[rs2][4:0];
									end
									`EXE_SRA: begin
										R[rd] = $signed(R[rs1]) >>> R[rs2][4:0];
									end
								endcase
							end
							`EXE_OR: begin
								R[rd] = R[rs1] | R[rs2];
							end
							`EXE_AND: begin
								R[rd] = R[rs1] & R[rs2];
							end
						endcase
					end
					default: begin
						imm = `ZeroWord;
						debug = INVALID_STATE;
					end
				endcase
				i = i + 1;
				if (mem_cnt == 0) begin
					i = 0;
					mem_state = NONE;
				end
			end
			7: begin
				addr = mem_addr;
				if (mem_state == NONE) begin
				end if (mem_state == STATE_READ) begin
					tag = READ;
					i = i + 1;
				end else if (mem_state == STATE_WRITE) begin
					tag = WRITE;
					i = i + 1;
					out = R[reg_addr][7:0];
					mem_cnt = mem_cnt - 1;
					if (mem_cnt == 0) begin
						i = 0;
						mem_state = NONE;
					end
				end else begin
					debug = INVALID_STATE;
				end
			end
			8: begin
				addr = mem_addr + 1;
				if (mem_state == NONE) begin
				end if (mem_state == STATE_READ) begin
					tag = READ;
					i = i + 1;
					if (mem_cnt == 1) begin
						addr = mem_addr;
					end
				end else if (mem_state == STATE_WRITE) begin
					tag = WRITE;
					i = i + 1;
					out = R[reg_addr][15:8];
					mem_cnt = mem_cnt - 1;
					if (mem_cnt == 0) begin
						i = 0;
						mem_state = NONE;
					end
				end else begin
					debug = INVALID_STATE;
				end
			end
			9: begin
				addr = mem_addr + 2;
				if (mem_state == NONE) begin
				end if (mem_state == STATE_READ) begin
					tag = READ;
					i = i + 1;
					mem_data[7:0] = mem_din;
					mem_cnt = mem_cnt - 1;
					if (mem_cnt == 1) begin
					   addr = mem_addr + 1;
					end
					if (mem_cnt == 0) begin
						if (is_signed) begin
								R[reg_addr] = {{24{mem_data[7]}}, mem_data[7:0]};
						end else begin
								R[reg_addr] = {{24{1'b0}}, mem_data[7:0]};
						end
						i = 0;
						mem_state = NONE;
					end
				end else if (mem_state == STATE_WRITE) begin
					tag = WRITE;
					i = i + 1;
					out = R[reg_addr][23:16];
					mem_cnt = mem_cnt - 1;
					if (mem_cnt == 0) begin
						i = 0;
						mem_state = NONE;
					end
				end else begin
					debug = INVALID_STATE;
				end
			end
			10: begin
				addr = mem_addr + 3;
				if (mem_state == NONE) begin
				end if (mem_state == STATE_READ) begin
					tag = READ;
					i = i + 1;
					mem_data[15:8] = mem_din;
					mem_cnt = mem_cnt - 1;
					if (mem_cnt == 0) begin
						if (is_signed) begin
								R[reg_addr] = {{16{mem_data[15]}}, mem_data[15:0]};
						end else begin
								R[reg_addr] = {{16{1'b0}}, mem_data[15:0]};
						end
						i = 0;
						mem_state = NONE;
					end
				end else if (mem_state == STATE_WRITE) begin
					tag = WRITE;
					i = i + 1;
					out = R[reg_addr][31:24];
					mem_cnt = mem_cnt - 1;
					if (mem_cnt == 0) begin
						i = 0;
						mem_state = NONE;
					end
				end else begin
					debug = INVALID_STATE;
				end
			end
			11: begin
				if (mem_state == STATE_READ) begin
                    tag = READ;
                    addr = mem_addr + 3;
					mem_data[23:16] = mem_din;
					i = i + 1;
					mem_cnt = mem_cnt - 1;
					if (mem_cnt == 0) begin
						i = 0;
						debug = INVALID_STATE;
						mem_state = NONE;
					end
				end else begin
					debug = INVALID_STATE;
				end
			end
			12: begin
				if (mem_state == STATE_READ) begin
					mem_data[31:24] = mem_din;
					i = i + 1;
					mem_cnt = mem_cnt - 1;
					if (mem_cnt == 0) begin
						R[reg_addr] = mem_data;
					end
					i = 0;
					mem_state = NONE;
				end else begin
					debug = INVALID_STATE;
				end
			end
			default: begin
				debug = INVALID_STATE;
			end
		endcase
	end
end

endmodule
