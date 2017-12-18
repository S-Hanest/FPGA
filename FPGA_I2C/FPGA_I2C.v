module FPGA_I2C(CLK,RST,SCL,SDA
					,transaction,START_BIT,status,pos,ACK,DATA_OUT,DATA_IN,round);

input CLK;
input RST;

inout wire SCL;
inout wire SDA;

wire SCL_IN;
reg SCL_OUT;
reg MS;

wire SDA_IN;
reg SDA_OUT;
reg RW;

assign SDA = (RW ? 8'bz : SDA_OUT);	//RW 1 is read 0 is write
assign SDA_IN = (RW ? SDA : 8'bz);

assign SCL = (MS ? SCL_OUT : 8'bz);	//MS 1 is Master 0 is Slave
assign SCL_IN = (MS ? 8'bz : SCL);

output reg [0:7] DATA_OUT;
output reg [0:7] DATA_IN;

output reg [3:0] pos;
output reg [3:0] status;
output reg transaction;
reg transaction1,transaction2;
output reg START_BIT;
output reg ACK;
wire NACK;

assign NACK = ~ACK;

integer DIV_CLK;
parameter DIV_CLK_LIMIT = 62;

parameter START_CONDITION = 0,
			 STOP_CONDITION = 1,
			 READ_CONDITION = 2,
			 WRITE_CONDITION = 3;

parameter ROUND_LIMIT = 4;
reg [6:0] SLAVE_ADDR;

output integer round;
integer count;

initial begin
	MS = 1;
	RW = 0;
	
	SDA_OUT = 1;
	SCL_OUT = 1;
	
	DIV_CLK = 0;
	
	pos = 0;
	transaction = 0;
	START_BIT = 0;
	
	ACK = 0;
	
	DATA_IN = 8'h0;
	DATA_OUT = 8'h0;
	SLAVE_ADDR = 7'h26;
	round = 0;
	count = 0;
end

always @(posedge CLK) begin
	transaction1 <= transaction;
end

always @(posedge CLK or negedge RST) if(!RST) begin
	round = 0;
	
	START_BIT <= 0;
	status <= START_CONDITION;
	count <= 0;
end else begin
	if(START_BIT) START_BIT <= 0;

	if(status == 5) begin
		count <= count + 1;
		if(count == 5_000_000) begin
			round = 0;
			count <= 0;
		end
	end
	
	if(!transaction & transaction1) begin
		if((status == WRITE_CONDITION) && NACK) round = (ROUND_LIMIT - 1);
		else round = round + 1;
	end
	
	if(!transaction && round <= ROUND_LIMIT) begin
		START_BIT <= 1;
		
		case(round)
			0 : begin
				status <= START_CONDITION;
			end
			
			1 : begin
				DATA_OUT = {SLAVE_ADDR[6:0],1'b1};
				status <= WRITE_CONDITION;
			end
			
			2 : begin
				status <= READ_CONDITION;
			end
			
			3 : begin
				status <= STOP_CONDITION;
			end
		
			/*4 : begin
				status <= START_CONDITION;
			end
			
			5 : begin
				DATA_OUT = {SLAVE_ADDR[6:0],1'b0};
				status <= WRITE_CONDITION;
			end
			
			6 : begin
				DATA_OUT = DATA_IN + 1;
				status <= WRITE_CONDITION;
			end
			
			7 : begin
				status <= STOP_CONDITION;
			end*/
			
			default : begin
				status <= 5;
			end
		endcase
		
	end
	
end


always @(posedge CLK or negedge RST) if(!RST) begin
	RW = 0;
	
	SDA_OUT <= 1;
	SCL_OUT = 1;
	
	DIV_CLK <= 0;
	
	pos <= 0;
	transaction <= 0;
	
	DATA_IN <= 8'h0;
	
	ACK <= 0;
	
end else begin
	if(!transaction && START_BIT) begin
		transaction <= 1;
		DIV_CLK <= 0;
		pos <= 0;
	end else if(transaction) begin
		case(status)
			START_CONDITION : begin
				RW = 0;
				if((!SCL_OUT|!SDA_OUT) & (DIV_CLK == 0)) begin
					SCL_OUT <= 1;
					SDA_OUT <= 1;
				end else begin
					DIV_CLK <= DIV_CLK + 1;
					if(DIV_CLK == (DIV_CLK_LIMIT/2)) SDA_OUT <= 0;
					else if (DIV_CLK == DIV_CLK_LIMIT) begin
						SCL_OUT = ~SCL_OUT;
						DIV_CLK <= 0;
						transaction = 0;
					end
				end
			end
			
			STOP_CONDITION : begin
				RW = 0;
				if((SCL_OUT | SDA_OUT) & (DIV_CLK == 0)) begin
					SCL_OUT = 0;
					SDA_OUT <= 0;
				end else begin
					DIV_CLK <= DIV_CLK + 1;
					if(DIV_CLK == (DIV_CLK_LIMIT/2)) SCL_OUT = 1;
					else if (DIV_CLK == DIV_CLK_LIMIT) begin
						SDA_OUT <= 1;
						
						DIV_CLK <= 0;
						transaction <= 0;
					end
				end
			end
			
			READ_CONDITION : begin
				DIV_CLK <= DIV_CLK + 1;
				if(SCL_OUT && pos < 8) begin 
					RW = 1;
					DATA_IN[pos] <= SDA_IN;
				end else if(!SCL_OUT && pos == 8) begin
					RW = 0;
					SDA_OUT <= 0;
				end else if(!SCL_OUT && pos > 8) begin
					pos <= 0;
					transaction <= 0;
					RW = 1;
				end
				
				if(DIV_CLK == DIV_CLK_LIMIT) begin
					DIV_CLK <= 0;
					SCL_OUT = ~SCL_OUT;
					if(!SCL_OUT) pos <= pos + 1;
				end
			end
			
			WRITE_CONDITION : begin
				DIV_CLK <= DIV_CLK + 1;
				if(!SCL_OUT) begin
					RW = 0;
					if(pos < 8) SDA_OUT <= DATA_OUT[pos];
					else if(pos == 8) RW = 1;
					else begin
						pos <= 0;
						transaction <= 0;
						RW = 1;
					end
				end else if(SCL_OUT && pos == 8) begin
					RW = 1;
					if(SDA_IN) ACK <= 0;
					else ACK <= 1;
				end
				
				if(DIV_CLK == DIV_CLK_LIMIT) begin
					DIV_CLK <= 0;
					SCL_OUT = ~SCL_OUT;
					if(!SCL_OUT) pos <= pos + 1;
				end
			end
			
			default : begin
				RW = 0;
	
				SDA_OUT <= 1;
				SCL_OUT = 1;
				
				DIV_CLK <= 0;
				
				pos <= 0;
				transaction <= 0;
				
				ACK <= 0;
			end
			
		endcase
		
	end
end

endmodule