`timescale 1ns/1ns

module tb_FPGA_SPI;
	reg clk;
	
	/*wire sclk;							//Master Test bench Code
	wire mosi,ss;
	reg miso;
	
	reg[7:0] data_out;
	reg[7:0] data_in;
	integer i;
	
	initial begin
		data_out = 8'h9D;
		data_in = 0;
		i = 0;
		clk = 0;
		miso = 0;
	end
	
	always @(posedge clk) begin
		if(ss == 0 && sclk == 0) begin
			miso = data_out[i];
		end
	end
	
	always @(posedge sclk) begin
		if(ss == 0) begin
			data_in[i] = mosi;
			i = i + 1;
			if(i == 8) i = 0;
		end else begin
			miso = 0;
			i = 0;
		end
	end*/
	
	reg sclk;								//Slave Test bench Code
	reg mosi,ss;
	wire miso;
	
	integer div_clk,i;
	
	reg [0:7] data_in;
	reg[0:7] data_out;
	
	initial begin
		clk = 0;
		sclk = 0;
		mosi = 0;
		ss = 1;
		div_clk = 0;
		
		data_in = 8'h0;
		data_out = 8'h0;
		i = 0;
	end
	
	always @(posedge clk) begin
		if(ss==1) begin
			div_clk = 0;
			sclk = 0;
			data_out <= data_in;
			#500 ss = 0;
		end
		div_clk = div_clk + 1;
		if(sclk == 0) begin
			mosi = data_out[i];
		end
		
		if(div_clk == 5) begin
			div_clk = 0;
			sclk = ~sclk;
			if(sclk == 1) begin
				data_in[i] = miso;
				i = i + 1;
			end else begin
				if(i == 8) begin
					i = 0;
					ss = 1;
				end
			end
		end
	end
	
	always begin
		#10 clk = ~clk;
	end
	FPGA_SPI spi(.CLK(clk),.SCLK(sclk),.MOSI(mosi),.MISO(miso),.SS(ss));
	
endmodule