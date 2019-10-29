module scr_brd_xor(
	input  bit[127:0]aes_out,
	input  bit[127:0]cipher,//message
	output bit[127:0]plain_text
	);
assign plain_text = aes_out ^ cipher;

endmodule : scr_brd_xor
