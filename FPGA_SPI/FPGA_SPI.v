module FPGA_SPI(CLK,SCLK,MOSI,MISO,SS);

input CLK;

inout wire SCLK,MOSI,SS,MISO;

wire[7:0] DATA_IN;
reg[7:0] DATA_OUT;

reg START_BIT;
wire END_BIT;

integer counter;

initial begin
	DATA_OUT = 8'h0;
	START_BIT = 0;
	counter = 0;
end

FPGA_SPI_MASTER MS(CLK,SCLK,MOSI,MISO,SS,
						 DATA_IN,DATA_OUT,START_BIT,END_BIT);

/*FPGA_SPI_SLAVE SL(CLK,SCLK,MOSI,MISO,SS,
						DATA_IN,DATA_OUT,END_BIT);*/

/*
* Master Function
*/

	
always @(posedge CLK) begin		//Delay 1 Sec
	counter = counter + 1;
	if(counter == 50_000_000) begin
		counter = 0;
	end
end

always @(posedge CLK) begin		//SPI Master Start in 0, Stop in 1
	if(counter == 0) begin
		START_BIT = 0;
	end
	
	if(END_BIT == 1) begin
		START_BIT = 1;
	end
end

always @(posedge SS) begin			//Send Data
	DATA_OUT = DATA_OUT + 1;
end



/*
*SLAVE Function
*/

/*always @(negedge END_BIT) begin	//Send Data
	DATA_OUT <= DATA_IN;					//Echo
end*/


endmodule