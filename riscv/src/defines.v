`timescale 1ns / 1ps

// global defines

`define	RstEnable		1'b1
`define	RstDisable		1'b0
`define	ZeroWord		32'h00000000
`define	WriteEnable		1'b1
`define	WriteDisable	1'b0
`define	ReadEnable		1'b0
`define	ReadDisable		1'b0
`define	AluOpBus		7:0
`define	AluSelBus		2:0
`define	InstValid		1'b0
`define	InstInvalid		1'b1
`define	True_v			1'b1
`define	False_v			1'b0
`define	ChipEnable		1'b1
`define	ChipDisable		1'b0

// defines for instructions 

`define EXE_NOP 7'b0000000

`define EXE_LUI 7'b0110111
`define EXE_AUIPC 7'b0010111
`define EXE_JAL 7'b1101111
`define EXE_JALR 7'b1100111
`define EXE_BXX 7'b1100011
	`define EXE_BEQ 3'b000
	`define EXE_BNE 3'b001
	`define EXE_BLT 3'b100
	`define EXE_BGE 3'b101
	`define EXE_BLTU 3'b110
	`define EXE_BGEU 3'b111
`define EXE_LOAD 7'b0000011
	`define EXE_LB 3'b000
	`define EXE_LH 3'b001
	`define EXE_LW 3'b010
	`define EXE_LBU 3'b100
	`define EXE_LHU 3'b101
`define EXE_SAVE 7'b0100011
	`define EXE_SB 3'b000
	`define EXE_SH 3'b001
	`define EXE_SW 3'b010
`define EXE_IMM 7'b0010011
	`define EXE_ADDI 3'b000
	`define EXE_SLTI 3'b010
	`define EXE_SLTIU 3'b011
	`define EXE_XORI 3'b100
	`define EXE_ORI 3'b110
	`define EXE_ANDI 3'b111
	`define EXE_SLLI 3'b001
	`define EXE_SRXX 3'b101
		`define EXE_SRLI 7'b0000000
		`define EXE_SRAI 7'b0100000
`define EXE_TWO 7'b0110011
	`define EXE_ADD_OR_SUB 3'b000
		`define EXE_ADD 7'b0000000
		`define EXE_SUB 7'b0100000
	`define EXE_SLL 3'b001
	`define EXE_SLT 3'b010
	`define EXE_SLTU 3'b011
	`define EXE_XOR 3'b100
	`define EXE_SRX 3'b101
		`define EXE_SRL 7'b0000000
		`define EXE_SRA 7'b0100000
	`define EXE_OR 3'b110
	`define EXE_AND 3'b111
`define EXE_FENCE 7'b0001111
	`define EXE_FENCE_I 3'b001

// AluOp
`define EXE_NOP_OP	8'b00000000

// AluSel
`define EXE_RES_LOGIC	3'b001
`define EXE_RES_NOP		3'b000

// for ROM
`define InstAddrBus		31:0
`define InstBus			31:0
`define InstMemNum		131071
`define InstMemNumLog2	17

// for Regfile
`define RegAddrBus		4:0
`define RegBus			31:0
`define RegWidth		32
`define DoubleRegWidth	64
`define DoubleRegBus	63:0
`define RegNum			32
`define RegNumLog2		5
`define NOPRegAddr		5'b00000

// for ctrl
`define STOP 1'b1
`define NOSTOP 1'b0
