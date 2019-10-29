//This package contains the tasks required to carry out the algorithm

package methods;
	parameter Nb = 4;//number of columns in the state array
 	parameter Nk = 4;//number of the 8-byte words comprising the cipher key
 	parameter Nr = 10;//number of rounds
	import ROM::*;
	//subWord(); supposed to receive a 4-byte input word and applies s-box to each. It is used by key expansion routine
	// and subBytes
	task automatic subWord(input bit [31:0]key, output bit [31:0]sub);
		//$display("key %b",key);
		InvSubBox(key,sub);
		//$display("%0h",sub);
	endtask : subWord
	//subBytes();it takes an array of 16 bytes of the input cipher and substitutes them using an s-box
	//(actually it is InvSybBytes)
	//It uses subWord by sending it 
	task automatic subBytes(input bit[Nb-1:0][0:31]state,output bit[Nb-1:0][0:31]st_pr);//4 columns, each of 32 bit vertical width
		bit [0:(Nb*8)-1]temp;
		for(int i = 0; i<Nb; i++)begin
			temp = state[i];//take the i-th column as a word
			//$display("the temp value is : %h %h %h %h for column %h",temp[0:7],temp[8:15],temp[16:23],temp[24:31],i);
			subWord(temp,st_pr[i]);//substitute it using subWord
			
		end
		$display("in subButes st_pr:\n%h %h %h %h\n %h %h %h %h\n %h %h %h %h\n %h %h %h %h",
		st_pr[0][0:7],st_pr[0][8:15],st_pr[0][16:23],st_pr[0][24:31],
		st_pr[1][0:7],st_pr[1][8:15],st_pr[1][16:23],st_pr[1][24:31],
		st_pr[2][0:7],st_pr[2][8:15],st_pr[2][16:23],st_pr[2][24:31],
		st_pr[3][0:7],st_pr[3][8:15],st_pr[3][16:23],st_pr[3][24:31]);
		//test
		/*
		$display("\n\ntask receive");
		$display("state [0] : %h",state[0]);
		$display("state [1] : %h",state[1]);
		$display("state [2] : %h",state[2]);
		$display("state [3] : %h",state[3]);
		$display("\n\n\n\n");

		$display("task output");
		$display("state_pr [0] : %h",st_pr[0]);
		$display("state_pr [1] : %h",st_pr[1]);
		$display("state_pr [2] : %h",st_pr[2]);
		$display("state_pr [3] : %h",st_pr[3]);
		$display("\n\n\n\n");
		*/
	endtask : subBytes
	//rotWord : Receives a word of 4 bytes and performs cyclic permutation, used by key expansion routine
	//[a0,a1,a2,a3] >>> [a1,a2,a3,a0]
	task automatic rotWord(input bit[31:0] word, output bit[31:0] word_perm);
		//$display("word      : %h %h %h %h",word[7:0],word[15:8],word[23:16],word[31:24]);
		word_perm[23:0] = word[31:8];
		word_perm[31:24] = word[7:0]; 
	endtask : rotWord

	//RCon is a word in wich its 3 right most bytes are zeros
	//This task takes the number of round and returns the corresponding word
	task automatic rnd_const(input int i,output bit[31:0]RCon);
		bit [16:1][31:0] rnd_cnst;

		rnd_cnst[1]  = 32'h01000000;
		rnd_cnst[2]  = 32'h02000000;
		rnd_cnst[3]  = 32'h04000000;
		rnd_cnst[4]  = 32'h08000000;
		rnd_cnst[5]  = 32'h10000000;
		rnd_cnst[6]  = 32'h20000000;
		rnd_cnst[7]  = 32'h40000000;
		rnd_cnst[8]  = 32'h80000000;
		rnd_cnst[9]  = 32'h1b000000;
		rnd_cnst[10] = 32'h36000000;
		//uncomment the following for AES-192
		//rnd_cnst[11] = 32'h6c000000;
		//rnd_cnst[12] = 32'hd8000000;
		//uncomment the following for AES-256
		//rnd_cnst[13] = 32'hab000000;
		//rnd_cnst[14] = 32'h4d000000;
		RCon = rnd_cnst[i];
	endtask : rnd_const

	//this task is responsible for generating the key expansion
	//the input is : 4*Nk (for AES-128; Nk=4) key(a key of 4 words; 128 bits)
	//The output is a key schedule;a linear array of 4-byte words of size Nb*(Nr+1)(for AES-128, Nr=10, so here its size is
	// supposed to be 44)
	task automatic keyExpansion(input bit[8*(4*Nk)-1:0]key, output bit [(Nb*(Nr+1)*4*8)-1:0]w);//[1407:0]w
		bit[31:0] temp;
		bit[31:0] RCon;
		//first Nk words of the expanded key are the cipher key
		//the cipher key is 16 bytes in this system; so the w bits from 127 to 0 are filled with the cipher key
		//wrong//w[(Nb*(Nr+1)*4*8)-1 : ( (Nb*(Nr+1)*4*8)-1 )-8*(4*Nk)] = key[8*(4*Nk)-1:0];
		w[8*(4*Nk)-1 : 0] = key[8*(4*Nk)-1:0];
		//every following word is equal the the one former to it XOR the word Nk positions earlier
		//considering positions with indices which are multiples of Nk, transformation is done prior to XOR
		for(int j = 8*(4*Nk); j<=(Nb*(Nr+1)*4*8)-32-1; j+=32)begin
			temp = w[j-1 -: 32];//the previous word
			rnd_const((j/4)/32,RCon);
			if(j%4 == 0)begin
				rotWord(temp,temp);
				subWord(temp,temp);
				temp = temp ^ RCon;
			end
			else if(Nk > 6 && j%4 == 4)begin
				subWord(temp,temp);
			end 
			//$display("%d",j);
			w[j+31 -: 32] = w[(j-(Nk*32))+31 -: 32] ^ temp;//bytes : w[j] = w[j-Nk] ^ temp;

			
		end
		$display("keyExpansion w: %h ",w[1407:0]);

	endtask : keyExpansion
	//addRoundKey
	//each round key consists of Nb words from the key scedule 
	//Those Nb words are added to the columns of the state
	task automatic addRoundKey(input bit[Nb-1:0][0:31]key, input bit[Nb-1:0][0:31]state, output bit[Nb-1:0][0:31]st_pr);
		for(int i = 0; i<Nb; i++)begin
			st_pr[i] = state[i] ^ key[i];
			
		end
		$display("in addRoundKey st_pr:\n%h %h %h %h\n %h %h %h %h\n %h %h %h %h\n %h %h %h %h",
				st_pr[0][0:7],st_pr[0][8:15],st_pr[0][16:23],st_pr[0][24:31],
				st_pr[1][0:7],st_pr[1][8:15],st_pr[1][16:23],st_pr[1][24:31],
				st_pr[2][0:7],st_pr[2][8:15],st_pr[2][16:23],st_pr[2][24:31],
				st_pr[3][0:7],st_pr[3][8:15],st_pr[3][16:23],st_pr[3][24:31]);	
	endtask : addRoundKey
	//shiftRows
	task automatic shiftRows(input bit[Nb-1:0][0:31]state, output bit[Nb-1:0][0:31]st_pr);
		bit[31:0]temp;
		//zeroth row
		for(int i  = 0; i<Nb; i++)begin
			st_pr[i][0:7] = state[i][0:7];
		end
		//first row
		st_pr[0][8:15] = state[Nb-1][8:15];
		for(int i  = 1; i<Nb; i++)begin
			st_pr[i][8:15] = state[i-1][8:15];
		end
		//second row
		st_pr[0][16:23] = state[Nb-2][16:23];
		st_pr[1][16:23] = state[Nb-1][16:23];
		for(int i  = 2; i<Nb; i++)begin
			st_pr[i][16:23] = state[i-2][16:23];
		end
		//third row
		st_pr[0][24:31] = state[Nb-3][24:31];
		st_pr[1][24:31] = state[Nb-2][24:31];
		st_pr[2][24:31] = state[Nb-1][24:31];
		for(int i  = 3; i<Nb; i++)begin
			st_pr[i][24:31] = state[i-3][24:31];
		end
		$display("in shiftRows st_pr:\n%h %h %h %h\n %h %h %h %h\n %h %h %h %h\n %h %h %h %h",
				st_pr[0][0:7],st_pr[0][8:15],st_pr[0][16:23],st_pr[0][24:31],
				st_pr[1][0:7],st_pr[1][8:15],st_pr[1][16:23],st_pr[1][24:31],
				st_pr[2][0:7],st_pr[2][8:15],st_pr[2][16:23],st_pr[2][24:31],
				st_pr[3][0:7],st_pr[3][8:15],st_pr[3][16:23],st_pr[3][24:31]);
	endtask : shiftRows
	//mod : used by multiplication
	//checks whether the input excceds 2 bytes and reduces it using {01}{1B}
	task automatic mod(input bit[15:0]exceed, output bit[15:0]reduced);
		bit[15:0]m;
		m = 16'h011b;
		if(exceed & 16'h8000) reduced = exceed ^ (m << 7);
		else if(exceed & 16'h4000) reduced = exceed ^ (m << 6);
		else if(exceed & 16'h2000) reduced = exceed ^ (m << 5);
		else if(exceed & 16'h1000) reduced = exceed ^ (m << 4);
		else if(exceed & 16'h0800) reduced = exceed ^ (m << 3);
		else if(exceed & 16'h0400) reduced = exceed ^ (m << 2);
		else if(exceed & 16'h0200) reduced = exceed ^ (m << 1);
		else if(exceed & 16'h0100) reduced = exceed ^ m;
		else reduced = exceed;
	endtask : mod
	//Field multiplication : used to multiply two bytes in GF(2^8)
	task automatic mult(input bit[7:0]a,input bit[7:0]b, output bit[7:0]product);
		bit[7:0][15:0] temp;
		bit[15:0] t;
		if(b[0] == 1) temp[0] = a;
		if(b[1] == 1) temp[1] = a << 1;
		if(b[2] == 1) temp[2] = a << 2;
		if(b[3] == 1) temp[3] = a << 3;
		if(b[4] == 1) temp[4] = a << 4;
		if(b[5] == 1) temp[5] = a << 5;
		if(b[6] == 1) temp[6] = a << 6;
		if(b[7] == 1) temp[7] = a << 7;
		t = temp[0]^temp[1]^temp[2]^temp[3]^temp[4]^temp[5]^temp[6]^temp[7];
		//$display("t : %b",t);
		mod(t,t);
		mod(t,t);
		mod(t,t);
		mod(t,t);
		mod(t,t);
		mod(t,t);
		mod(t,t);
		mod(t,t);
		//$display("t : %h",t);
		product = t[7:0];
		//$display("product : %h",product);
	endtask : mult

	//InvMixColumns
	//this routine is valid only for AES-128 inverse cipher
	//this is not reusable ,unlike the rest of the code, unless for changing the coefficients for the encryption
	//but it isn't valid with AES-192 and AES 256 //actually the columns needed
	task automatic mixColumns(input bit[Nb-1:0][0:31]state, output bit[Nb-1:0][0:31]st_pr);
		//values used for calculations
		bit[7:0]temp_0;
		bit[7:0]temp_1;
		bit[7:0]temp_2;
		bit[7:0]temp_3;
		bit[7:0]temp_4;
		bit[7:0]temp_5;
		bit[7:0]temp_6;
		bit[7:0]temp_7;
		bit[7:0]temp_8;
		bit[7:0]temp_9;
		bit[7:0]temp_10;
		bit[7:0]temp_11;
		bit[7:0]temp_12;
		bit[7:0]temp_13;
		bit[7:0]temp_14;
		bit[7:0]temp_15;
		
		//0 column
		mult(8'h0e,state[0][0:7],temp_0);
		mult(8'h0b,state[0][8:15],temp_1);
		mult(8'h0d,state[0][16:23],temp_2);
		mult(8'h09,state[0][24:31],temp_3);

		mult(8'h09,state[0][0:7],temp_4);
		mult(8'h0e,state[0][8:15],temp_5);
		mult(8'h0b,state[0][16:23],temp_6);
		mult(8'h0d,state[0][24:31],temp_7);

		mult(8'h0d,state[0][0:7],temp_8);
		mult(8'h09,state[0][8:15],temp_9);
		mult(8'h0e,state[0][16:23],temp_10);
		mult(8'h0b,state[0][24:31],temp_11);

		mult(8'h0b,state[0][0:7],temp_12);
		mult(8'h0d,state[0][8:15],temp_13);
		mult(8'h09,state[0][16:23],temp_14);
		mult(8'h0e,state[0][24:31],temp_15);

		st_pr[0][0:7]	= temp_0 ^ temp_1 ^ temp_2 ^ temp_3;
		st_pr[0][8:15]	= temp_4 ^ temp_5 ^ temp_6 ^ temp_7;
		st_pr[0][16:23]	= temp_8 ^ temp_9 ^ temp_10 ^ temp_11;
		st_pr[0][24:31]	= temp_12 ^ temp_13 ^ temp_14 ^ temp_15;

		//column 1
		mult(8'h0e,state[1][0:7],temp_0);
		mult(8'h0b,state[1][8:15],temp_1);
		mult(8'h0d,state[1][16:23],temp_2);
		mult(8'h09,state[1][24:31],temp_3);

		mult(8'h09,state[1][0:7],temp_4);
		mult(8'h0e,state[1][8:15],temp_5);
		mult(8'h0b,state[1][16:23],temp_6);
		mult(8'h0d,state[1][24:31],temp_7);

		mult(8'h0d,state[1][0:7],temp_8);
		mult(8'h09,state[1][8:15],temp_9);
		mult(8'h0e,state[1][16:23],temp_10);
		mult(8'h0b,state[1][24:31],temp_11);

		mult(8'h0b,state[1][0:7],temp_12);
		mult(8'h0d,state[1][8:15],temp_13);
		mult(8'h09,state[1][16:23],temp_14);
		mult(8'h0e,state[1][24:31],temp_15);

		st_pr[1][0:7]	= temp_0 ^ temp_1 ^ temp_2 ^ temp_3;
		st_pr[1][8:15]	= temp_4 ^ temp_5 ^ temp_6 ^ temp_7;
		st_pr[1][16:23]	= temp_8 ^ temp_9 ^ temp_10 ^ temp_11;
		st_pr[1][24:31]	= temp_12 ^ temp_13 ^ temp_14 ^ temp_15;

		//column 2
		mult(8'h0e,state[2][0:7],temp_0);
		mult(8'h0b,state[2][8:15],temp_1);
		mult(8'h0d,state[2][16:23],temp_2);
		mult(8'h09,state[2][24:31],temp_3);

		mult(8'h09,state[2][0:7],temp_4);
		mult(8'h0e,state[2][8:15],temp_5);
		mult(8'h0b,state[2][16:23],temp_6);
		mult(8'h0d,state[2][24:31],temp_7);

		mult(8'h0d,state[2][0:7],temp_8);
		mult(8'h09,state[2][8:15],temp_9);
		mult(8'h0e,state[2][16:23],temp_10);
		mult(8'h0b,state[2][24:31],temp_11);

		mult(8'h0b,state[2][0:7],temp_12);
		mult(8'h0d,state[2][8:15],temp_13);
		mult(8'h09,state[2][16:23],temp_14);
		mult(8'h0e,state[2][24:31],temp_15);

		st_pr[2][0:7]	= temp_0 ^ temp_1 ^ temp_2 ^ temp_3;
		st_pr[2][8:15]	= temp_4 ^ temp_5 ^ temp_6 ^ temp_7;
		st_pr[2][16:23]	= temp_8 ^ temp_9 ^ temp_10 ^ temp_11;
		st_pr[2][24:31]	= temp_12 ^ temp_13 ^ temp_14 ^ temp_15;

		//column 3
		mult(8'h0e,state[3][0:7],temp_0);
		mult(8'h0b,state[3][8:15],temp_1);
		mult(8'h0d,state[3][16:23],temp_2);
		mult(8'h09,state[3][24:31],temp_3);

		mult(8'h09,state[3][0:7],temp_4);
		mult(8'h0e,state[3][8:15],temp_5);
		mult(8'h0b,state[3][16:23],temp_6);
		mult(8'h0d,state[3][24:31],temp_7);

		mult(8'h0d,state[3][0:7],temp_8);
		mult(8'h09,state[3][8:15],temp_9);
		mult(8'h0e,state[3][16:23],temp_10);
		mult(8'h0b,state[3][24:31],temp_11);

		mult(8'h0b,state[3][0:7],temp_12);
		mult(8'h0d,state[3][8:15],temp_13);
		mult(8'h09,state[3][16:23],temp_14);
		mult(8'h0e,state[3][24:31],temp_15);

		st_pr[3][0:7]	= temp_0 ^ temp_1 ^ temp_2 ^ temp_3;
		st_pr[3][8:15]	= temp_4 ^ temp_5 ^ temp_6 ^ temp_7;
		st_pr[3][16:23]	= temp_8 ^ temp_9 ^ temp_10 ^ temp_11;
		st_pr[3][24:31]	= temp_12 ^ temp_13 ^ temp_14 ^ temp_15;

		$display("in mixColumns st_pr:\n%h %h %h %h\n %h %h %h %h\n %h %h %h %h\n %h %h %h %h",
				st_pr[0][0:7],st_pr[0][8:15],st_pr[0][16:23],st_pr[0][24:31],
				st_pr[1][0:7],st_pr[1][8:15],st_pr[1][16:23],st_pr[1][24:31],
				st_pr[2][0:7],st_pr[2][8:15],st_pr[2][16:23],st_pr[2][24:31],
				st_pr[3][0:7],st_pr[3][8:15],st_pr[3][16:23],st_pr[3][24:31]);
	endtask : mixColumns
endpackage




