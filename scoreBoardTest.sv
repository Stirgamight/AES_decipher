module scrBrdTest();
	parameter Nb = 4;//number of columns in the state array
 	parameter Nk = 4;//number of the 8-byte words comprising the cipher key
 	parameter Nr = 10;//number of rounds
	reg [32*Nb-1:0]ct;//cipher text
	reg [32*Nk-1:0]key;//AES-128 key
	reg [63:0]Iv;
	reg start;
	reg clk;
	reg rst;

	wire [32*Nb-1:0]pt;//plain text
	wire ready;

	topScrBrd scrBrd(.Iv(Iv),.cipher(ct),.start(start),.rst(rst),.clk(clk),.plain_text(pt),.ready(ready),.key(key));

	always begin
		clk = 0;
		#5;
		clk = 1;
		#5;
	end

	initial begin
		rst = 0;
		#10;
		rst = 1;
		start = 1;
		Iv = 64'h2232859645102203;
		ct = 128'h50ff65cf9d6834b1d2003de297a2e26f;
		key= 128'h000102030405060708090a0b0c0d0e0f;
		#10;
		start = 0;
		$display("Iv :  %h %h %h %h %h %h %h %h",
			Iv[63:56],Iv[55:48],Iv[47:40],Iv[39:32],Iv[31:24],Iv[23:16],Iv[15:8],Iv[7:0]);
		$monitor(" at time: %d, pt = %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h, ready = %d",
			$time,pt[127:120],pt[119:112],pt[111:104],pt[103:96],pt[95:88],pt[87:80],pt[79:72],pt[71:64],pt[63:56]
					,pt[55:48],pt[47:40],pt[39:32],pt[31:24],pt[23:16],pt[15:8],pt[7:0],ready);

		#30;
		$finish;
	end

endmodule : scrBrdTest
