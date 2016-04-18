
/*
 * Opcodes {aaa, cc}
 */

parameter
  ORA = 5'b000_01,
  AND = 5'b001_01,
  EOR = 5'b010_01,
  ADC = 5'b011_01,
  STA = 5'b100_01,
  LDA = 5'b101_01,
  CMP = 5'b110_01,
  SBC = 5'b111_01,

  ASL = 5'b000_10,
  ROL = 5'b001_10,
  LSR = 5'b010_10,
  ROR = 5'b011_10,
  STX = 5'b100_10,
  LDX = 5'b101_10,
  DEC = 5'b110_10,
  INC = 5'b111_10,

  BRK = 5'b000_00,
  BIT = 5'b001_00,
  JMP = 5'b010_00,
  JMP_abs = 5'b011_00,
  STY = 5'b100_00,
  LDY = 5'b101_00,
  CPY = 5'b110_00,
  CPX = 5'b111_00;



parameter
	ALU_ADD = 0,
	ALU_AND = 1,
	ALU_OR  = 2,
	ALU_EOR = 3,
	ALU_SR  = 4,
   ALU_SUB = 5
;

/*
 * Addressing Modes
 */

// TODO

module cpu (input clk,
			input rst,
			input [7:0] d_in,
			output [7:0] d_out,
			output [15:0] addr);

   logic [7:0] pcl; // Program counter low
   logic [7:0] pch; // Program counter high

   logic [15:0] pc_temp = {pch, pcl};
   logic [7:0] status; // Processor flags
   logic [7:0] acc; // Accumulator

   logic [7:0] alu_a; // ALU A register
   logic [7:0] alu_b; // ALU B register

   logic [4:0] alu_mode;
   logic [4:0] alu_instruction;

   logic [7:0] IR; // instruction register


   /*
    * Decode instruction
    */

	assign alu_instruction = {d_in[7:5], d_in[1:0]};
	
initial
   assign acc = 1;

	logic temp =  1; // NO IDEA IF THIS IS OK

   alu ALU(
		.alu_a(alu_a),
	   .alu_b(alu_b),
		.mode(alu_mode),
	   .carry_in(temp),
	   .alu_out(d_out),
	   .carry_out(status[0]),
		.overflow(status[6]),
		.zero(status[1]),
		.sign(status[7]));


   // TODO: MISSING!!!!!!
   // alu_b needs to get data from other places
   // like X, Y, PCL/PCH????

	always_ff @(posedge clk) begin

   //$display("alu_instruction: %b", alu_instruction);
		//if (alu_instruction == ADC)
		
		case (alu_instruction)
			AND: alu_mode <= ALU_AND;
			ADC: alu_mode <= ALU_ADD;
			//ORA: alu_mode <= ALU_OR;
			//EOR: alu_mode <= ALU_EOR;
			//SBC: alu_mode <= ALU_SUB;
			default: alu_mode <= 49;
		endcase
		//else
			//alu_mode <= ALU_AND;
		//$display("alu_mode: %d", alu_mode);

		alu_b <= d_in;
      alu_a <= acc;
      acc   <= d_out;
	end

   /*
    *  Processor status flags
	*  C - Carry
	*  Z - Zero Result
	*  I - Interrupt Disable
	*  D - Decimal Mode
	*  B - Break Command
	*  X - Nothing
	*  V - Overflow
	*  N - Negative Result
	*/

   /*
    * Instruction Fields
    */

   logic [2:0] aaa;
   logic [2:0] bbb;
   logic [1:0] cc;
   assign {aaa, bbb, cc} = IR;

   /*
    * Controller FSM
    */

   enum {T0, T1, T2, T3, T4, T5, T6} state;
   initial state = T0;

   parameter
     INX = 3'b000,
     ZPG = 3'b001,
     IMM = 3'b010,
     ABS = 3'b011,
     INY = 3'b100,
     ZPX = 3'b101,
     ABY = 3'b110,
     ABX = 3'b111;

//   logic mode = 2'b01;

   always_ff @ (posedge clk) begin

      case (state)
        T0:
          begin
             state <= T1;
             IR <= d_in;
          end
        T1: state <= (bbb == IMM) ? T0 : T2;
        T2: state <= (bbb == ZPG) ? T0 : T3;
        T3:
          if (bbb == ABS || bbb == ZPX)
            state <= T0;
          else if ((bbb == ABX || bbb == ABY) && !status[0])
            state <= T0;
          else
            state <= T4;
        T4:
          if (bbb == ABX || bbb == ABY)
            state <= T0;
          else if (bbb == INY && !status[0])
            state <= T0;
          else
            state <= T5;
        T5: state <= T0;
        default: state <= T0;
      endcase

//      $display("state: T%.1d", state);
//      $display("IR: %x", IR);

   end

   /*
    * Program Counter Logic
    */

   assign d_out = 0;
   assign addr = 0;
   assign pc_rst = 0;

   // TODO: account for not incrementing on single-byte instruction

   pc PC( .clk(clk),
          .rst(pc_rst),
          .pc_in(pc_temp),
          .pc_out(pc_temp));
   assign addr = pc_temp;

endmodule // cpu
