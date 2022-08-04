module round_key_gen #(
		parameter bus_width = 128, //MUST divide mode, min:8
		parameter mode = 128,	   //128 or 192 or 256
		parameter rounds_required = 10 //used for rcon_address, the memory model as well
	)
(
	input  clk,
	input  rst_n,
	input  dv,
	input  round_key_needed, 
	//round_key_needed:  A note from the cipher/decipher circuits that they have read the round key and this module is allowed to make another
	input  [bus_width-1 : 0] cipher_key,
	input [$ceil($clog2(rounds_required))-1:0] next_rcon,

	output  [$ceil($clog2(rounds_required))-1:0] rcon_address, //used to read round ant for the next round
	output  [mode-1 : 0] rKey, //round key
	output  key_ready //a flag to the cipher/decpher circuit to receive the key
);

//states
//typedef enum logic[2:0] {U = 'x, idle = '0, receive, outp, rcon, regen} state;
//state pr_state, nx_state;
//localparam U 		= 3'bxxx;
localparam idle 	= 3'h0;
localparam receive 	= 3'h1;
localparam outp 	= 3'h2;
localparam rcon 	= 3'h3;
localparam regen 	= 3'h4;

reg [2:0] pr_state, nx_state;

//counter related
/*************************************************************************************************************************/
//counter values and  regs
reg[3:0] inp_cntr_limit = mode/bus_width; 	 //limit of input counter
reg [3:0] inp_cntr;

reg[$ceil($clog2(rounds_required))-1:0] key_cntr_limit = 10+(mode-128)/32;//depends on mode: 10 for 128, 12 for 192 and 14 for 256
reg [$ceil($clog2(rounds_required))-1:0] key_cntr;

reg[3:0] word_count_limit = (mode/32)-1;
reg [3:0] word_cntr;


//counter controls/enables
reg inp_ctrl; //input counter enable
reg key_ctrl; //key counter enable
reg word_ctrl;//word counter enable
//counters

//input counter, only used if mode > bus width
always@(posedge clk) begin
	if(rst_n == 0) inp_cntr <= 4'b0;
	else begin
		if(inp_ctrl == 1) begin
			if(inp_cntr == inp_cntr_limit) inp_cntr <= 4'b0;
			else inp_cntr <= inp_cntr + 1;
		end
	end
end

//key_counter, counts the keys supposed to be generated,  actually decides when the machine stops
always@(posedge clk) begin
	if(rst_n == 0) key_cntr <= 0;
	else begin
		if(key_ctrl == 1) begin
			if(key_cntr == key_cntr_limit) key_cntr <= 0;
			else key_cntr <= key_cntr + 1;
		end
	end
end

//word counter, each key is 4,6 or 8 words, the first has a spexial state to create it
always@(posedge clk) begin
	if(rst_n == 0) word_cntr <= 0;
	else begin
		if(word_ctrl == 1) begin
			if(word_cntr == word_count_limit) word_cntr <= 0;
			else word_cntr <= word_cntr + 1;
		end
	end
end
/*************************************************************************************************************************/



//Auxiliary register related, used: two registers for the round key
/*************************************************************************************************************************/
//Auxiliary regisetrs, ctrl == combinationally driven
reg [mode - 1:0] pr_rKey;
reg [mode - 1:0] nx_rKey, nx_rKey_ctrl;
reg [4:0] rcon_addr_reg, rcon_addr_ctrl;

//pr_rKey
always@(posedge clk) begin
	if(rst_n == 0) pr_rKey <= 0;
	else if((word_cntr == word_count_limit) || (inp_cntr == inp_cntr_limit)) pr_rKey <= nx_rKey;
end

//nx_rKey
always@(posedge clk)begin
	if(rst_n == 0) nx_rKey <= 0;
	else nx_rKey <= nx_rKey_ctrl;
end

/*
//next rcon address
always_ff @(posedge clk)begin
	if(rst_n == 0) rcon_addr_reg <= '0;
	else rcon_addr_reg <= rcon_addr_ctrl;
end

assign rcon_address = rcon_addr_reg;
*/


//state
always@(posedge clk)begin
	if(rst_n == 0) pr_state <= idle;
	else pr_state <= nx_state;
end

/*************************************************************************************************************************/
//output register
reg key_ready_flag, key_ready_ctrl;
always@(posedge clk)begin
	if(rst_n == 0) key_ready_flag <= 0;
	else key_ready_flag <= key_ready_ctrl; 
end
/*************************************************************************************************************************/
assign rKey = pr_rKey;
assign rcon_address = key_cntr;
assign key_ready = key_ready_flag;
/*************************************************************************************************************************/
integer i;
integer j;
always@(*) begin
	case(pr_state)
		idle: begin
			
			if(dv == 1) nx_state = receive;
			else nx_state = idle;
			
			//nx_state = receive;
			inp_ctrl  = 0;
			key_ctrl  = 0;
			word_ctrl = 0;

			nx_rKey_ctrl = nx_rKey;
			key_ready_ctrl = 0;

		end

		receive:begin
			
			if(inp_cntr >= inp_cntr_limit) nx_state = outp;
			else nx_state = receive;
			
			//nx_state = outp;
			inp_ctrl  = 1;
			key_ctrl  = 0;
			word_ctrl = 0;

			if(inp_cntr < inp_cntr_limit)begin
				nx_rKey_ctrl = (nx_rKey << bus_width) ^ cipher_key;
			end
			else begin
				nx_rKey_ctrl = 0;
			end

			key_ready_ctrl = 0;
		end

		outp:begin
			
			if(round_key_needed == 1)nx_state = rcon;
			else nx_state = outp;
			
			//nx_state = rcon;
			inp_ctrl  = 0;
			key_ctrl  = 0;
			word_ctrl = 0;

			nx_rKey_ctrl = nx_rKey;
			key_ready_ctrl = 1;
		end

		rcon:begin
			nx_state = regen;

			inp_ctrl  = 0;
			key_ctrl  = 0;
			word_ctrl = 0;

			//creating word_0
			//if(key_cntr > 4'h7)nx_rKey_ctrl[31:0] = pr_rKey[31:0] ^ {pr_rKey[mode-32:mode-25],pr_rKey[mode-24, mode-1]} ^ (1<<key_cntr);
			//else nx_rKey_ctrl[31:0] = pr_rKey[31:0] ^ {pr_rKey[mode-32:mode-25],pr_rKey[mode-24, mode-1]} ^ next_rcon;
			nx_rKey_ctrl[31:0] = pr_rKey[31:0] ^ {pr_rKey[mode-25:mode-32], pr_rKey[mode-1: mode-24]} ^ next_rcon;
			//nx_rKey_ctrl[31:0] = pr_rKey[31:0] ^ next_rcon;

			nx_rKey_ctrl[bus_width-1:32] = nx_rKey[bus_width-1:32];

			key_ready_ctrl = 0;
		end

		regen:begin
			//state definition based on two counters
			/*
			if(word_cntr < word_count_limit && key_cntr < key_cntr_limit) nx_state = regen;
			else if(word_cntr < word_count_limit && key_cntr >= key_cntr_limit) nx_state = regen;
			//so if(word_cntr < word_count_limit) the value of key_cntr is irrelevant
			else if(word_cntr >= word_count_limit && key_cntr < key_cntr_limit) nx_state = outp;
			else if(word_cntr >= word_count_limit && key_cntr >= key_cntr_limit) nx_state = idle;
			//this will infer a latch of course, but the comment makes things clear
			*/
			
			if(word_cntr < word_count_limit) nx_state = regen;
			else if(word_cntr >= word_count_limit && key_cntr < key_cntr_limit) nx_state = outp;
			else nx_state = idle;
			
			inp_ctrl  = 0;
			key_ctrl  = 1;
			word_ctrl = 1;

			nx_rKey_ctrl[31:0] = nx_rKey[31:0];
			for(i = 32; i<mode; i=i+32) begin
				for(j = 0; j<32; j=j+1) begin
					nx_rKey_ctrl[j+i] = pr_rKey[j+i] ^ nx_rKey[j];
				end
			end

			if(word_cntr == word_count_limit) key_ready_ctrl = 1'b1;
			else key_ready_ctrl = 1'b0;

		end
		//sim
		/*
		default:begin
			nx_state  = U;

			inp_ctrl = 1'bx;
			key_ctrl = 1'bx;
			word_ctrl = 1'bx;

			nx_rKey_ctrl = 1'bx;
			key_ready_ctrl = 1'bx;
		end
		*/
		//synth
		/*
		default:begin
			nx_state  = idle;

			inp_ctrl = 1'b0;
			key_ctrl = 1'b0;
			word_ctrl = 1'b0;

			nx_rKey_ctrl = 1'b0;
			key_ready_ctrl = 1'b0;
		end
		*/
	endcase
end



endmodule

