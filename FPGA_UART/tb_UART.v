`timescale 1ns/1ns

module tb_UART;

	reg clk;
	reg RX;
	wire TX;
	
	/*wire[3:0] TXS,RXS;
	wire[7:0] TXD,RXD;
	wire[31:0] TX_Count,RX_Count;
	wire TX_Start;
	wire TX_T,RX_T;
	wire BUFF;*/
	
	UART uart(.CLK(clk),.TX(TX),.RX(RX));
				//,.TX_Status(TXS),.RX_Status(RXS),.TX_Start(TX_Start),.TX_Transaction(TX_T),.RX_Transaction(RX_T),.TXD(TXD),.RXD(RXD),.TX_Count(TX_Count),.RX_Count(RX_Count),.BUFF(BUFF));
	
	initial begin
		clk = 0;
		RX = 1;
		#100
		#52080 RX = 0;
		
		#52080 RX = 1;
		#52080 RX = 0;
		#52080 RX = 0;
		#52080 RX = 1;
		
		#52080 RX = 0;
		#52080 RX = 1;
		#52080 RX = 1;
		#52080 RX = 0;
		
		#52080 RX = 1;
		
		#52080 RX = 0;
		
		#52080 RX = 0;
		#52080 RX = 1;
		#52080 RX = 1;
		#52080 RX = 0;
		
		#52080 RX = 1;
		#52080 RX = 0;
		#52080 RX = 0;
		#52080 RX = 1;
		
		#52080 RX = 1;
	end
	
	always
		#10 clk = ~clk;
endmodule
