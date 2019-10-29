module topScrBrd(Iv,key,start,rst,clk,ready,cipher,plain_text);
parameter Nb = 4;//number of columns in the state array
parameter Nk = 4;//number of the 8-byte words comprising the cipher key
parameter Nr = 10;//number of rounds

input bit [(32*Nb)/2-1:0] Iv;
input bit [(32*Nb)-1:0] key;
input bit start;
input bit clk;
input bit rst;
input bit [32*Nb-1 : 0]cipher;

output bit ready;
output bit[32*Nb-1 : 0]plain_text;

wire [32*Nb-1:0]con;
wire [32*Nb-1:0]aes_o;

ctr ctr(.Iv(Iv),.Concatenated(con));
invCipher invC(.ct(con),.start(start),.clk(clk),.rst(rst),.key(key),.pt(aes_o),.ready(ready));
scr_brd_xor xr(.aes_out(aes_o),.cipher(cipher),.plain_text(plain_text));

endmodule : topScrBrd
