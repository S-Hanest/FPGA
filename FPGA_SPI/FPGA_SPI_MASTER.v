module FPGA_SPI_MASTER(CLK,SCLK,MOSI,MISO,SS,DATA_IN,DATA_OUT,START_BIT,END_BIT);

integer i;

input wire CLK;
output reg SCLK,MOSI,SS;
input MISO;

input [0:7] DATA_OUT;
output reg[0:7] DATA_IN;

input wire START_BIT;
output reg END_BIT;

integer DIV_CLK;
parameter DIV_CLK_Limit = 24;	//1MHz

initial begin
	i = 0;
	SCLK = 0;
	MOSI = 1;
	SS = 1;
	DATA_IN = 0;
	
	END_BIT = 0;
	DIV_CLK = 0;
end

always @(posedge CLK) begin
	if(START_BIT == 0) begin
		SS = 0;
		DIV_CLK = DIV_CLK + 1;
		
		if(SCLK == 0) begin
			MOSI = DATA_OUT[i];	//DATA_Send in !SCLK
		end
		
		if(DIV_CLK == DIV_CLK_Limit) begin		//Clock Divide for Arduino
			DIV_CLK = 0;
			SCLK = ~SCLK;
			
			if(SCLK == 1) begin	//DATA_Receive in rising edge SCLK
				DATA_IN[i] = MISO;
				i = i + 1;
			end else begin			//I increse in falling edge SCLK
				if(i == 8) begin
					i = 0;
					END_BIT = 1;	//notify End to FPGA
				end
			end
			
		end
	end else begin
		SCLK = 0;
		DIV_CLK = 0;
		MOSI = 1;
		i = 0;
	end
	
	if(END_BIT == 1 && START_BIT == 1) begin
		SS = 1;
		END_BIT = 0;
	end
end

endmodule