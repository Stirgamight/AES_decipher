module ctr(
	input  bit[63:0] Iv,
	output bit[127:0]Concatenated
	);
bit [63:0] con;//the first count only
assign con[63:0] = 64'h0000000000000000;

assign Concatenated [63:0] = con[63:0];
assign Concatenated [127:64] = Iv[63:0];
/*initial begin


$monitor("con : %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h"
	,Concatenated[127:120],Concatenated[119:112],Concatenated[111:104],Concatenated[103:96],
	Concatenated[95:88],Concatenated[87:80],Concatenated[79:72],Concatenated[71:64],Concatenated[63:56]
	,Concatenated[55:48],Concatenated[47:40],
	Concatenated[39:32],Concatenated[31:24],Concatenated[23:16],Concatenated[15:8],Concatenated[7:0]);
end*/
endmodule : ctr