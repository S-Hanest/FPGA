`timescale 1ns/1ns

module tb_I2C;

	reg clk;
	wire scl;
	wire sda;
	
	reg rw;
	wire sda_in;
	reg sda_out;
	
	reg[0:7] data_in;
	reg[0:7] data_out;
	
	assign sda = (rw ? 8'bz : sda_out);
	assign sda_in = (rw ? sda : 8'bz);
	
	reg[3:0] pos;
	reg[1:0] status;
	reg transaction;
	
	reg sda_in1;
	reg sda_in2;
	
	reg scl1;
	reg scl2;
	
	reg ack;
	wire nack;
	
	reg start_con;
	reg stop_con;
	
	reg rst;
	
	assign nack = ~ack;
	
	parameter ADDRESS = 7'h26;
	parameter READ_ADDRESS = 0;
	parameter READ_DATA = 1;
	parameter WRITE_DATA = 2;
	
	
	wire MSTR;
	wire MSSB;
	wire[2:0] MSST;
	wire[3:0] MSPS;
	wire MSAK;
	wire[7:0] MSDO,MSDI;
	wire[31:0] round;
	FPGA_I2C i2c(.CLK(clk),.RST(rst),.SCL(scl),.SDA(sda)
					,.transaction(MSTR),.START_BIT(MSSB),.status(MSST),.pos(MSPS),.ACK(MSAK),.DATA_OUT(MSDO),.DATA_IN(MSDI),.round(round));
	
	initial begin
		data_out = 8'h4C;
		data_in = 0;
		sda_out = 1;
		clk = 0;
		rw = 1;
		pos = 0;
		status = 0;
		transaction = 0;
		
		sda_in2 = 1;
		sda_in1 = 1;
		
		scl2 = 0;
		scl1 = 0;
		
		ack = 0;
		
		start_con = 0;
		stop_con = 0;
		
		rst = 0;
		#10 rst = 1;
	end

	always @(posedge clk) begin
		if(rw) begin
			sda_in2 <= sda_in1;
			sda_in1 <= sda_in;
		end else begin
			sda_in2 <= 1;
			sda_in1 <= 1;
		end
		
		scl2 <= scl1;
		scl1 <= scl;
	end
	
	always @(posedge clk) begin
		if(scl && rw) begin
			if(!sda_in1 & sda_in2) start_con <= 1;
			else if(sda_in1 & !sda_in2) stop_con <= 1;
		end
		
		if(start_con && (scl1 ^ scl2)) begin 
			start_con <= 0;
			transaction <= 1;
		end
		
		if(stop_con) begin
			stop_con <= 0;
			transaction <= 0;
		end
	end
	
	
	always @(posedge clk) begin
		if(!transaction) status <= 0;
		else if(transaction) begin
			case(status)
				READ_ADDRESS : begin
					if(scl && pos < 8) data_in[pos] <= sda_in;
					else if(!scl && pos == 8) begin
						rw = 0;
						sda_out <= 0;
					end else if(!scl && pos > 8) begin
						pos <= 0;
						if(data_in[0:6] == ADDRESS) begin
							if(!data_in[7]) status <= READ_DATA;
							else status <= WRITE_DATA;
						end else status <= 3;
						rw = 1;
					end
				end
				
				READ_DATA : begin
					if(scl && pos < 8) data_in[pos] <= sda_in;
					else if(!scl && pos == 8)begin
						rw = 0;
						sda_out <= 0;
					end else if(!scl && pos > 8) begin
						pos <= 0;
						status <= 3;
						rw = 1;
					end
				end
				
				WRITE_DATA : begin
					if(!scl) begin
						rw = 0;
						if(pos < 8) sda_out <= data_out[pos];
						else if(pos == 8) sda_out <= 0;
						else begin
							pos <= 0;
							status <= 3;
						end
					end else if(scl && pos == 8)begin
						rw = 1;
						if(sda_in) ack <= 0;
						else ack <= 1;
					end
				end
				
				default : begin
					rw = 1;
					pos <= 0;
				end
				
			endcase
			
			if(scl1^scl2) begin
				if(!scl) pos <= pos + 1;
			end
		end
	end

	always #10 clk = ~clk;
	
endmodule