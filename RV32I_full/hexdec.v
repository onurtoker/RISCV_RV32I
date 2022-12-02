module hexdec(input [3:0] swt, output reg[6:0] hex_out);
 
	localparam HEX_0 = 7'b1000000;		// zero
	localparam HEX_1 = 7'b1111001;		// one
	localparam HEX_2 = 7'b0100100;		// two
	localparam HEX_3 = 7'b0110000;		// three
	localparam HEX_4 = 7'b0011001;		// four
	localparam HEX_5 = 7'b0010010;		// five
	localparam HEX_6 = 7'b0000010;		// six
	localparam HEX_7 = 7'b1111000;		// seven
	localparam HEX_8 = 7'b0000000;		// eight
	localparam HEX_9 = 7'b0011000;		// nine
	localparam HEX_10 = 7'b0001000;		// ten
	localparam HEX_11 = 7'b0000011;		// eleven
	localparam HEX_12 = 7'b1000110;		// twelve
	localparam HEX_13 = 7'b0100001;		// thirteen
	localparam HEX_14 = 7'b0000110;		// fourteen
	localparam HEX_15 = 7'b0001110;		// fifteen
	localparam zero   = 7'b1111111;		// all off

	always@*
	begin
		hex_out = zero;
		case (swt[3:0])
			4'b0000: hex_out = HEX_0;
			4'b0001: hex_out = HEX_1;
			4'b0010: hex_out = HEX_2;
			4'b0011: hex_out = HEX_3; 
			4'b0100: hex_out = HEX_4;
			4'b0101: hex_out = HEX_5;
			4'b0110: hex_out = HEX_6;
			4'b0111: hex_out = HEX_7;
			4'b1000: hex_out = HEX_8;
			4'b1001: hex_out = HEX_9;
			4'b1010: hex_out = HEX_10;
			4'b1011: hex_out = HEX_11;
			4'b1100: hex_out = HEX_12;
			4'b1101: hex_out = HEX_13;
			4'b1110: hex_out = HEX_14;
			4'b1111: hex_out = HEX_15;
		endcase
	end
	
endmodule