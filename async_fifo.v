module async_fifo(
			wr_clk,
			rd_clk,
			rst,
			wr_en,
			rd_en,
			wr_data,
			rd_data,
			empty,
			full,
			error
		);


parameter WIDTH=8;
parameter DEPTH=16;
parameter PTR_WIDTH=4; 
input wr_clk,rd_clk,rst,wr_en,rd_en;
output reg empty,full,error;
input [WIDTH-1:0] wr_data;
output reg [WIDTH-1:0]rd_data;
reg [WIDTH-1:0] mem [DEPTH-1:0];
 
reg [PTR_WIDTH-1:0] rd_ptr,wr_ptr;
reg [PTR_WIDTH-1:0]wr_ptr_gray,rd_ptr_gray;
reg [PTR_WIDTH-1:0] rd_ptr_gray_in_wr_clk,wr_ptr_gray_in_rd_clk; // to compare the values of rd_ptr in wr_clk and vice versa
reg wr_toogle_f,rd_toogle_f;
reg wr_toogle_f_rd_clk, rd_toogle_f_wr_clk;
integer i;
// WRITE LOGIC
always@(posedge wr_clk)begin
  if(rst == 1)begin
  	empty       = 1; // rightnow empty is high
        full        = 0;
	error       = 0;
 	wr_toogle_f = 0;
	rd_toogle_f = 0;
	rd_ptr      = 0;
	wr_ptr      = 0;
	wr_ptr_gray = 0;
	rd_ptr_gray = 0;
	rd_ptr_gray_in_wr_clk = 0;
  	wr_ptr_gray_in_rd_clk = 0;

	
	for(i = 0; i< DEPTH; i=i+1) begin
		mem[i] = 0;
	end	
  end
  else begin
  	if(wr_en == 1) begin
		if(full == 1) begin
			$display("FIFO is full");
			error=1;
		end
		else begin 
			// Writing the Memory 
			mem[wr_ptr] = wr_data;
			//this is to represent the rollover if wr_ptr is 15,
			//next will go to 16(~0)
			if(wr_ptr == DEPTH-1) begin
				wr_toogle_f = ~wr_toogle_f;
			end
			wr_ptr = wr_ptr+1; // wr_ptr can't hold 16 values
			wr_ptr_gray = bin2gray(wr_ptr); // coverting binnary to gray coding
		end
	end
  
  end

end

// READ LOGIC
always @(posedge rd_clk) begin
 if(rst != 1) begin 
	 error=0;
  	if(rd_en == 1) begin
		if(empty == 1) begin
			$display("FIFO is empty");
			error=1;
		end
		else begin 
			// Reading the Memory 
			rd_data = mem[rd_ptr];
			//this is to represent the rollover if rd_ptr is 15,
			//next will go to 16(~0)
			if(rd_ptr == DEPTH-1) begin
				rd_toogle_f = ~rd_toogle_f;
			end
			rd_ptr = rd_ptr + 1;
			rd_ptr_gray = bin2gray(rd_ptr);
		end
	end
  
  end

 end
//full geneartion logic
always@(*) begin // all the below memtioned signals are the sensitivity
full=0;
if(wr_ptr_gray == rd_ptr_gray_in_wr_clk && wr_toogle_f != rd_toogle_f_wr_clk)//wr_toogle flag is 16 but read toogle flag will be in 15
begin
	full=1;
end
end




//empty geneartion logic
always@(*)begin
empty=0;
if(wr_ptr_gray_in_rd_clk == rd_ptr_gray && wr_toogle_f_rd_clk == rd_toogle_f)
begin
	empty=1;
end
end

always@(posedge rd_clk) begin
	wr_ptr_gray_in_rd_clk <= wr_ptr_gray; // to avoid glitches
	wr_toogle_f_rd_clk <= wr_toogle_f;
end 
always@(posedge wr_clk) begin
	rd_ptr_gray_in_wr_clk <= rd_ptr_gray; // to avoid glitches
	rd_toogle_f_wr_clk <= rd_toogle_f;
end 
function reg [3:0] bin2gray (input reg [3:0]bin);
	reg [3:0] gray;
	begin
		gray[3] = bin[3];
		gray[2] = bin[3] ^ bin[2];
		gray[1] = bin[2] ^ bin[1];
         	gray[0] = bin[1] ^ bin[0];
		bin2gray = gray;	
	end
endfunction
endmodule
