module DE2_RISCV_RV32I(

	//////////// CLOCK //////////
	input 		          		CLOCK_50,

	//////////// LED //////////
	output		     [8:0]		LEDG,
	output		    [17:0]		LEDR,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// SW //////////
	input 		    [17:0]		SW,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,
	output		     [6:0]		HEX6,
	output		     [6:0]		HEX7,

	//////////// GPIO, GPIO connect to GPIO Default //////////
	output 		    [35:0]		GPIO
);

assign reset = ~KEY[0];			
assign LEDG[0] = ~KEY[0];

/* KEY[3] GENERATES THE MAIN SYSTEM CLOCK  ================================== */

debounce UX(.clk(CLOCK_50), .reset(~KEY[1]),
				.sw(~KEY[3]), .db_level(dbl));

assign clk = dbl;	// or use CLOCK_50
assign LEDG[3] = dbl;
				
/* THIS IS OUR MAIN MEMORY ================================================== */

smem U_SMEM(.addr(address),
			.clk(clk),
			.din(ram_din),
			.we(wr_enable),
			.dout(ram_dout)
			); //

/* DEBUG RELATED============================================================= */

wire[31:0] xpc;

assign xpc = SW[17] ? pc : registers[SW[3:0]];

hexdec U0(.swt(xpc[ 3: 0]), .hex_out(HEX0));
hexdec U1(.swt(xpc[ 7: 4]), .hex_out(HEX1));
hexdec U2(.swt(xpc[11: 8]), .hex_out(HEX2));
hexdec U3(.swt(xpc[15:12]), .hex_out(HEX3));
hexdec U4(.swt(xpc[19:16]), .hex_out(HEX4));
hexdec U5(.swt(xpc[23:20]), .hex_out(HEX5));
hexdec U6(.swt(xpc[27:24]), .hex_out(HEX6));
hexdec U7(.swt(xpc[31:28]), .hex_out(HEX7));

/* ========================================================================= */

//REST IS THE RISCV RV32I. 
//IT IS BETTER TO MOVE THE REST TO A SEPERATE FILE. IT WILL LOOK MORE ORGANIZED
			
// STATE OF THE CPU
reg[31:0] registers[0:31];	//cpu registers
reg[31:0] pc	;				//program counter


// THESE ARE AUX REGISTERS or AUX MEMORY 
// THEY ARE USED FOR 2-CYCLE LOAD/STORE INSTRUCTIONS
reg[10:0] load;
reg[4:0] rd_load;
reg store;
reg[31:0] storeloadaddr;
reg[31:0] ram_din;

// THESE ARE JUST WIRES 
wire[31:0] ram_dout;
wire[11:0] imm;  
wire[11:0] imms; 
wire[11:0] immc; 
wire[11:0] immlui;
wire[4:0] rd;
wire[4:0] rs1;
wire[4:0] rs2;
wire[7:0] tmpof8;
wire[15:0] tmpof16;
wire[19:0] imm20;
wire[31:0] address;
wire wr_enable;
wire[2:0] func3;
wire[6:0] func7;
			
assign rd 		= ram_dout[11:7];
assign tmpof8	= ram_dout & 8'hff;
assign tmpof16	= ram_dout & 16'hffff;

assign address 	= (load || store) ? storeloadaddr : pc>>>2;
assign wr_enable	= store;

assign rs1		= ram_dout[19:15];
assign rs2		= ram_dout[24:20];
assign imms		= {ram_dout[31:25],ram_dout[11:7]};
assign immc		= {ram_dout[31],ram_dout[7],ram_dout[30:25],ram_dout[11:8]};
assign imm		= ram_dout[31:20];
assign imm20	= {ram_dout[31],ram_dout[19:12],ram_dout[20],ram_dout[30:21]};
assign immlui	= ram_dout[31:12];
assign func3	= ram_dout[14:12];
assign func7	= ram_dout[31:25];

always @(negedge clk)
begin

	if (reset) 
	begin
	
		registers[ 0]<=0;	registers[ 1]<=0;	registers[ 2]<=0;	registers[ 3]<=0;
		registers[ 4]<=0;	registers[ 5]<=0;	registers[ 6]<=0;	registers[ 7]<=0;
		registers[ 8]<=0;	registers[ 9]<=0;	registers[10]<=0;	registers[11]<=0;
		registers[12]<=0;	registers[13]<=0;	registers[14]<=0;	registers[15]<=0;
		registers[16]<=0;	registers[17]<=0;	registers[18]<=0;	registers[19]<=0;
		registers[20]<=0;	registers[21]<=0;	registers[22]<=0;	registers[23]<=0;
		registers[24]<=0;	registers[25]<=0;	registers[26]<=0;	registers[27]<=0;
		registers[28]<=0;	registers[29]<=0;	registers[30]<=0;	registers[31]<=0;
		
		pc<=0;

		load<=0;
		rd_load<=0;
		store<=0;
		storeloadaddr<=0;
		ram_din<=0;

	
	end
	else 
	begin
	
		/* BEGIN LOAD/STORE RELATED PART =============================================================== */			
	
	
		// PART-1
		// if the "previous" instruction was load data from memory  
		if(load)
		begin
				
				case(load)
						8:registers[rd_load]		<= {{24{tmpof8[7]}},tmpof8};
						16:registers[rd_load]	<= {{16{tmpof16[15]}},tmpof16};	
						32:registers[rd_load]	<= ram_dout;
						81:registers[rd_load]	<= ram_dout & 8'hff;
						161:registers[rd_load]	<= ram_dout & 16'hffff;
				endcase
				load	<= 0;
				pc		<= pc+4;
				 
		end

		// PART-2
		// if the "previous" instruction was store data in memory
		else if(store)
		begin
			store		<= 0;
			pc			<= pc+4;
		end

		// PART-3
		// "previous" of opcode is not store or load 
		else 
		begin
		 
			case(ram_dout[6:0])
			
				//Load Instructions   
				7'b0000011:begin
						 rd_load 		<= ram_dout[11:7];
						 storeloadaddr	<=	{{{20{imm[11]}}},imm} + registers[rs1];
						 case(func3)
							 //LB
							 3'b000:load<=8;
							 //LH		 
							 3'b001:load<=16;
							 //LW
							 3'b010:load<=32;
							 //LBU
							 3'b100:load<=81;
							 //LHU
							 3'b101:load<=161;		
						 endcase
				end
									 
				//Store Instructions
				7'b0100011:begin				 
						storeloadaddr	<=	{{{20{imms[11]}}},imms} + registers[rs1];
						store 			<= 1;
						case(func3)
							 //SB
							 3'b000:ram_din<=registers[rs2]&'hff;
							 //SH
							 3'b001:ram_din<=registers[rs2]&'hffff;
							 //SW
							 3'b010:ram_din<=registers[rs2];
						endcase
				end
			
		/* END LOAD/STORE RELATED PART ================================================================= */			
				
				//Integer Register-Immediate Instructions
				7'b0010011:begin
						 case(func3)
								//ADDI
								3'b000:registers[rd] <=	{{20{imm[11]}},imm} + registers[rs1];
								//SLTI
								3'b010:registers[rd] <=	$signed(registers[rs1]) < $signed({{20{imm[11]}},imm});	// Compare as signed numbers
								//SLTIU
								3'b011:registers[rd] <=	registers[rs1] < {{20{imm[11]}},imm};
								//XORI
								3'b100:registers[rd] <=	registers[rs1] ^ {{20{imm[11]}},imm};      		 
								//ORI
								3'b110:registers[rd] <=	registers[rs1] | {{20{imm[11]}},imm};
								//ANDI
								3'b111:registers[rd] <=	registers[rs1] & {{20{imm[11]}},imm};
								//SLLI
								3'b001:registers[rd] <=	registers[rs1] << imm[4:0];
								//SRLI,SRAI
								3'b101:
								case(imm[11:7])
										 //SRLI
										 7'b0000000:registers[rd] <= registers[rs1] >> imm[4:0];
										 //SRAI
										 7'b0001000:registers[rd] <= registers[rs1] >>> imm[4:0];
								endcase
						 endcase
						 
						 pc<=pc+4;		
				end
				
				//LUI
				7'b0110111:begin
						
					 registers[rd] <= immlui<<12;
					 
					 pc<=pc+4;		 
				end
				
				//AUIPC
				7'b0010111:begin
					 
					registers[rd] <= pc + (immlui<<12);
					
					pc<=pc+4;	
				end
				
				//Integer Register-Register Operations
				7'b0110011:begin
				 
					case(func3)
						
						//ADD,SUB
						3'b000:
							  case(func7)	
									7'b0000000:registers[rd] <= registers[rs1] + registers[rs2];
									7'b0100000:registers[rd] <= registers[rs1] - registers[rs2];	
							  endcase
						
						//SLL
						3'b001:registers[rd] <= registers[rs1] << registers[rs2];

						//SLT
						3'b010:registers[rd] <= $signed(registers[rs1]) < $signed(registers[rs2]);			// Compare as signed numbers

						//SLTU
						3'b011:registers[rd]<=registers[rs1] < registers[rs2];
						
						//XOR
						3'b100:registers[rd]<=registers[rs1] ^ registers[rs2];
						
						//SRL,SRA 
						3'b101:
							 case(func7)
						
								//SRL
								7'b0000000:registers[rd] <= registers[rs1] >> registers[rs2];
								//SRA
								7'b0100000:registers[rd] <= registers[rs1] >>> registers[rs2];
								//default:i<=0;
							 endcase	
							 
						//OR
						3'b110:registers[rd]<=registers[rs1] | registers[rs2]  ;

						//AND
						3'b111:registers[rd]<=registers[rs1] & registers[rs2]  ;
						//default: i<=0;
						
					endcase
					
					pc<=pc+4;
				end
					
				//JAL
				7'b1101111:begin
						if(rd)
						  registers[rd]<=pc+4;
						  
						pc <= pc + ({{11{imm20[19]}},imm20,1'b0});	  
						
				end
				
				//JALR
				7'b1100111:begin
					
					 if(rd)
						  registers[rd]<=pc+4;
						  
					 pc <= ($signed(registers[rs1])+$signed({{20{imm[11]}},imm})) & 'hfffffffe;	
					
				end
									
			  //Conditional Branches   
				7'b1100011:begin 
				
					 case(func3)
									
						  //BGE
						 3'b101: 
									if($signed(registers[rs1])>=$signed(registers[rs2]))							// Compare as signed numbers
										 pc<=pc+{{19{immc[11]}},immc,1'b0};
									else pc<=pc+4;
									
						 //BEQ
						 3'b000:
									if(registers[rs1]==registers[rs2])
										pc<=pc+{{19{imm[11]}},imm,1'b0};
									else pc<=pc+4;
							 
						 //BNE
						 3'b001:
									if(registers[rs1]!=registers[rs2])
													pc<=pc+{{19{imm[11]}},imm,1'b0};
										else pc<=pc+4;
											 
						 //BLT
						 3'b100:
									if($signed(registers[rs1])<$signed(registers[rs2]))							// Compare as signed numbers
													 pc<=pc+{{19{imm[11]}},imm,1'b0};
									else pc<=pc+4;
						 
						 //BLTU
						 3'b110:
									if(registers[rs1]<registers[rs2])
													pc<=pc+{{19{imm[11]}},imm,1'b0};
											else pc<=pc+4;
						 
						 //BGEU
						 3'b111:
									if(registers[rs1]>=registers[rs2])
													pc<=pc+{{19{imm[11]}},imm,1'b0};
									else pc<=pc+4;
						 
					endcase
				end 
					 
			endcase /* case of PART-3*/

		end /* if of PART-3 */
	
	end /* if not reset */
			
end /* always clk */
 
endmodule


