module FPGA_SPI_SLAVE(CLK,SCLK,MOSI,MISO,SS,DATA_IN,DATA_OUT,END_BIT);

	input wire CLK;
	input SCLK,MOSI,SS;
	output reg MISO;

	input[0:7] DATA_OUT;
	output reg[0:7] DATA_IN;

	output wire END_BIT;

	reg[2:0] Count;

	initial begin
		Count = 0;
		DATA_IN = 8'h0;
		MISO = 1;
	end

	assign END_BIT = Count != 0;	//notify End to FPGA
	

	always @(posedge SCLK or posedge SS) if(SS) begin	//Data receive from Master
		DATA_IN <= 0;
	end else begin
		DATA_IN[Count] <= MOSI;
	end
	
	always @(negedge SCLK or posedge SS) if(SS) begin	//Count increse
		Count = 0;
	end else begin
		Count = Count + 1;
	end
	
	always @(negedge SCLK or negedge SS) if(!SS) begin	//Data Send to Master
		MISO <= DATA_OUT[Count];
	end
		
		
endmodule