module UART(CLK,TX,RX);
				//,TX_Status,RX_Status,TX_Start,TX_Transaction,RX_Transaction,TXD,RXD,TX_Count,RX_Count,BUFF);

input CLK;

input RX;
output reg TX;

reg[7:0] RXD,TXD; //DATA_BIT 8

parameter DATA_BIT = 8;
parameter PARITY_BIT = 0;
parameter STOP_BIT = 1;
/*
	BAUDRATE = (FPGA_CLOCK / UART_BAUDRATE) + (0 ~ 2)
	115200 = 435
	57600 = 870
	38400 = 1302
	19200 = 2604
	9600 = 5208
*/
parameter BAUDRATE = 2604;	

reg[3:0] TX_Status,RX_Status;
integer TX_Count,RX_Count;

reg TX_Start;

reg TX_Transaction, RX_Transaction;	//Same of busy bit

reg BUFF;

integer timer;

initial begin
	BUFF = 0;
	timer = 0;
	
	TX_Count = 0;
	RX_Count = 0;

	TX_Start = 1;
	
	TX_Transaction = 1;	//Not Busy
	RX_Transaction = 1;	//Not Busy
	
	TX = 1;
	
	TX_Status = 0;
	RX_Status = 0;
	
	TXD = 8'h00;
	RXD = 8'h00;	
end


always @(posedge CLK) begin					//Echo Function
	if(RX_Transaction) TXD <= RXD;
	else begin
		BUFF = 1;
	end
	
	if(RX_Transaction && BUFF) begin	
		TX_Start = 0;								//TX_Send Start
		BUFF = 0;
	end else if(!BUFF) begin
		TX_Start = 1;								//TX_Send Stop
	end
end

/*always @(posedge CLK) begin	//Loop Send Function
	TX_Start = 1;
	timer = timer + 1;
	if(timer == 50_000_000) begin
		timer = 0;
		TX_Start = 0;
		TXD <= 8'hD3;
	end
end*/

always @(posedge CLK) begin																	//TX_Function
	if(TX_Transaction && !TX_Start) begin													//TX Start Condition
		TX_Transaction = 0;
		TX = 0;																						//Start Bit
		TX_Status = 1;
		TX_Count = 0;
	end else if(!TX_Transaction) begin
		if(TX_Count == BAUDRATE) begin	
			if(TX_Status > 0 && TX_Status < 1 + DATA_BIT) begin						//DATA_BIT Operation
				TX = TXD[TX_Status -1];
			end else if(TX_Status < 1 + DATA_BIT + PARITY_BIT) begin					//PARITY_BIT Operation
			end else if(TX_Status < 1 + DATA_BIT + PARITY_BIT + STOP_BIT) begin	// STOP_BIT Operation
				TX = 1;
			end else begin
				TX = 1;
				TX_Transaction = 1;
			end
			TX_Count = 0;
			TX_Status = TX_Status + 1;
		end
		TX_Count = TX_Count + 1;
	end
end

always @(posedge CLK) begin 																	//RX_Function
	if(RX_Transaction && !RX) begin															//RX Start Condition (negedge RX)
		RX_Transaction = 0;
		RX_Status = 1;
		RX_Count = 0;
	end else if(!RX_Transaction) begin								
		if(RX_Count == BAUDRATE) begin
			if(RX_Status > 0 && RX_Status < 1 + DATA_BIT) begin						//DATA_BIT Operation
				RXD[RX_Status - 1] = RX;
				RX_Status = RX_Status + 1;
			end else if(RX_Status < 1 + DATA_BIT + PARITY_BIT) begin					//PARITY_BIT Operation
			end else if(RX_Status < 1 + DATA_BIT + PARITY_BIT + STOP_BIT) begin	//STOP_BIT Operation
				if(RX) begin																		//if Stop bit == 1
					RX_Status = RX_Status + 1;													//go next Status
				end else begin																		//else reset
					RX_Transaction = 1;															
					RX_Count = 0;
				end
			end else begin
				RX_Transaction = 1;
				RX_Count = 0;
			end
			RX_Count = 0;
		end
		RX_Count = RX_Count + 1;
	end
end

endmodule