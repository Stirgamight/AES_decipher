//the input array is copied to the state array for which all transformations are applied
//after all transformations are done the state array is copied to the output array 
// 			the outputs are plain text, load and ready

//`include "methods.sv"
module invCipher(ct,start,clk,rst,key,pt,ready);
 
 import methods::*;
 parameter Nb = 4;//number of columns in the state array
 parameter Nk = 4;//number of the 8-byte words comprising the cipher key
 parameter Nr = 10;//number of rounds for AES-128

 //inputs
 input bit [32*Nb-1:0]ct;//cipher text
 input bit [32*Nk-1:0]key;//AES-128 key
 input bit start;
 input bit clk;
 input bit rst;

 //outputs
 output logic [32*Nb-1:0]pt;//plain text
 output reg ready;

 

 //byte [Nb*(Nr+1)]w;//the key schedule
 logic [(Nb*(Nr+1)*4*8)-1:0]w;
 logic [Nb-1:0][0:31]state;//the state array(2D) on which all inverse transformations are applied
 logic [Nb-1:0][0:31]st_pr;
 logic done ;



 always @(posedge clk)begin
 	
 	if(!rst)begin
 		ready = 0;
 		pt = '{default:'0};
 		state = '{default:'0};
 		w = '{default:'0};
 		done = 0;
 	end
 	else if(rst && start)begin
 		ready = 0;
 		keyExpansion(key,w);
 		
 		for(int i = 0; i<Nb; i++)begin
 			state[i]=ct[i*32 +: 32];
 		end
 		
 		addRoundKey(state,w[8*4*(Nr+1)*Nb-1 -: 4*4*8],state);
 		//first rounds
 		for(int i = Nr-1; i>=1; i--)begin
 			shiftRows(state,st_pr);
 			subBytes(st_pr,state);
 			addRoundKey(state,w[8*4*(i+1)*Nb-1 -: 4*4*8],st_pr);
 			mixColumns(st_pr,state);
 			$display("loop counted %d ",i);
 		end
 		//last round
 		shiftRows(state,st_pr);
 		subBytes(st_pr,state);
 		addRoundKey(state,w[127 : 0],st_pr);
 		done = 1;

 	end
 end
always@(posedge clk)begin
 	
 	if(done)begin
 		for(int i = 0; i<Nb; i++)begin
 			pt[i*32 +: 32]=st_pr[i];
 		end
 		done = 0;
 		ready = 1;
 		$display("aes_out :%h %h %h %h %h %h %h %h %h %h %h %h %h %h %h %h",
 		pt[127:120],pt[119:112],pt[111:104],pt[103:96],pt[95:88],pt[87:80],pt[79:72],pt[71:64],pt[63:56]
					,pt[55:48],pt[47:40],pt[39:32],pt[31:24],pt[23:16],pt[15:8],pt[7:0]);
 	end
 end

 //test on subWord
 /*
 initial begin
  bit[31:0] sub;
  subWord(32'hf11f0230,sub);
 end
 //$display("%h",sub);
 */
 //test on subBytes
 /*
 initial begin
 	integer variable = 0;
 	logic [Nb-1:0][0:31]st;
 	logic [Nb-1:0][0:31]st_pr;
 	for(int i = 0; i<Nb; i++)begin
 		for(int j = 0; j<32;j++)begin
 			st[i][j] = variable;
 			variable = !variable;
 		end
 	end
 	subBytes(st,st_pr);
 	//this is the state before substitution
 	
 	$display("\n\n\n\ntop",);
 	$display("state[0][0:7]   : %h",st[0][0:7]);
 	$display("state[0][8:15]  : %h",st[0][8:15]);
 	$display("state[0][16:23] : %h",st[0][16:23]);
 	$display("state[0][24:31] : %h",st[0][24:31]);

 	$display("state[1][0:7]   : %h",st[1][0:7]);
 	$display("state[1][8:15]  : %h",st[1][8:15]);
 	$display("state[1][16:23] : %h",st[1][16:23]);
 	$display("state[1][24:31] : %h",st[1][24:31]);

 	$display("state[2][0:7]   : %h",st[2][0:7]);
 	$display("state[2][8:15]  : %h",st[2][8:15]);
 	$display("state[2][16:23] : %h",st[2][16:23]);
 	$display("state[2][24:31] : %h",st[2][24:31]);

 	$display("state[3][0:7]   : %h",st[3][0:7]);
 	$display("state[3][8:15]  : %h",st[3][8:15]);
 	$display("state[3][16:23] : %h",st[3][16:23]);
 	$display("state[3][24:31] : %h",st[3][24:31]);

 	//this is the state after substitution
 	$display("\n\n\n\nafter sub");
 	$display("st_pr[0][0:7]   : %h",st_pr[0][0:7]);
 	$display("st_pr[0][8:15]  : %h",st_pr[0][8:15]);
 	$display("st_pr[0][16:23] : %h",st_pr[0][16:23]);
 	$display("st_pr[0][24:31] : %h",st_pr[0][24:31]);

 	$display("st_pr[1][0:7]   : %h",st_pr[1][0:7]);
 	$display("st_pr[1][8:15]  : %h",st_pr[1][8:15]);
 	$display("st_pr[1][16:23] : %h",st_pr[1][16:23]);
 	$display("st_pr[1][24:31] : %h",st_pr[1][24:31]);

 	$display("st_pr[2][0:7]   : %h",st_pr[2][0:7]);
 	$display("st_pr[2][8:15]  : %h",st_pr[2][8:15]);
 	$display("st_pr[2][16:23] : %h",st_pr[2][16:23]);
 	$display("st_pr[2][24:31] : %h",st_pr[2][24:31]);

 	$display("st_pr[3][0:7]   : %h",st_pr[3][0:7]);
 	$display("st_pr[3][8:15]  : %h",st_pr[3][8:15]);
 	$display("st_pr[3][16:23] : %h",st_pr[3][16:23]);
 	$display("st_pr[3][24:31] : %h",st_pr[3][24:31]);
 	
 end
 */
 //testing rotWord
 /*
 initial begin
 	bit [31:0]word_perm;
 	rotWord(32'h1f2d3015,word_perm);

 	$display("word_perm : %h %h %h %h",word_perm[7:0],word_perm[15:8],word_perm[23:16],word_perm[31:24]);
 end
 */
 //testing key extension
 /*
 initial begin
 	bit[31:0]Rcon;
 	rnd_const(10,Rcon);
 	$display("RCON : %h %h %h %h",Rcon[31:24],Rcon[23:16],Rcon[15:8],Rcon[7:0]);
 end
 */
 //testing field multiplication
 /*
 initial begin
 	bit[7:0] result;
 	mult(8'hab,8'h02,result);
 end
 */
 //testing keyExp
 /*
 initial begin
 	bit[(Nb*(Nr+1)*4*8)-1:0]w;
 	keyExpansion(128'hff012031654b8a991030205566478952,w);
 end
 */
endmodule

