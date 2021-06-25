`include"async_fifo.v"
module tb();
parameter WIDTH = 8;
parameter DEPTH = 16;
parameter PTR_WIDTH=6; 
parameter RD_CLK_TP=16;
parameter WR_CLK_TP=8;
parameter MAX_TRANS = 500;
parameter WR_DELAY_MAX=10;
parameter RD_DELAY_MAX=10;

reg wr_clk,rd_clk,rst,wr_en,rd_en;
wire empty,full,error;
reg [WIDTH-1:0] wr_data;
wire [WIDTH-1:0]rd_data;
//reg [PTR_WIDTH-1:0] rd_ptr,wr_ptr;
//reg [PTR_WIDTH-1:0] rd_ptr_in_wr_clk,wr_ptr_in_rd_clk; 
//reg wr_toogle_f,rd_toogle_f;
reg wr_delay,rd_delay; // delay b/w 2 writes & reads
reg [8*30:1] testcase;
integer seed,i;

async_fifo dut(
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

//clock geneartion
initial begin
wr_clk=0;
forever #(WR_CLK_TP/2) wr_clk = ~wr_clk;
end

initial begin
rd_clk=0;
forever #(RD_CLK_TP/2) rd_clk = ~rd_clk;
end

//reseting
initial begin
 $value$plusargs("seed=%d",seed);
 $value$plusargs("testcase=%s",testcase);
 rst=1;
 wr_en=0;
 rd_en=0;
 wr_data=0;
 repeat(5)@(posedge wr_clk);
 rst=0;
 //Apply stimulus
 
 case(testcase)
	 "test_full": begin // only read
		 for(i=0; i<DEPTH; i=i+1)begin
		 	 @(posedge wr_clk);
			 wr_en   = 1;
			 wr_data = $random;
		 end
		 @(posedge wr_clk);
		 wr_en = 0;
		 wr_data = 0;
	 end	 
	 "test_full_error": begin // overlap of read
		 for(i=0; i<DEPTH+1; i=i+1)begin
		 	 @(posedge wr_clk);
			 wr_en   = 1;
			 wr_data = $random;
		 end
		 @(posedge wr_clk);
		 wr_en = 0;
		 wr_data = 0;

	 
	 end	 
	 "test_empty": begin
		 //Writing to FIFO
		 for(i=0; i<DEPTH; i=i+1)begin
		 	 @(posedge rd_clk);
			 wr_en   = 1;
			 wr_data = $random;
		 end
		 @(posedge rd_clk);
		 wr_en = 0;
		 wr_data = 0;
	 
	// Reading from FIFO
	
		 for(i=0; i<DEPTH; i=i+1)begin
		 	 @(posedge rd_clk);
			 rd_en   = 1;
		 end
		 @(posedge wr_clk);
		 rd_en = 0;
	end
	"test_empty_error": begin
		//write to FIFO 
		 for(i=0; i<DEPTH; i=i+1)begin
		 	 @(posedge wr_clk);
			 wr_en   = 1;
			 wr_data = $random(seed);
		 end
		 @(posedge wr_clk);
		 wr_en = 0;
		 wr_data = 0;
	 
	// Reading from FIFO
	
		 for(i=0; i<DEPTH+1; i=i+1)begin
		 	 @(posedge rd_clk);
			 rd_en   = 1;
		 end
		 @(posedge wr_clk);
		 rd_en = 0;
	 end
	"test_concurrent_write_read":begin
		//use fork join to run parallel
		fork
			begin
			for(i=0; i<MAX_TRANS; i=i+1)begin
				@(posedge wr_clk);
				wr_en = 1;
				wr_data = $random(seed);
				wr_delay = $urandom_range(1,WR_DELAY_MAX);
				@(posedge wr_clk);
				wr_en = 0;
				wr_data = 0;
				repeat(wr_delay - 1)@(posedge wr_clk);
			end
			@(posedge wr_clk);
			wr_en = 0;
			wr_data = 0;	
			end
			begin
			
			for (i = 0; i < MAX_TRANS; i=i+1) begin
			 @(posedge rd_clk);
			 rd_en = 1;
			 rd_delay = $urandom_range(1, RD_DELAY_MAX); 
			 @(posedge rd_clk);
			 rd_en = 0;
			 repeat(rd_delay-1)@(posedge rd_clk);
		        end
		       @(posedge rd_clk);
		       rd_en = 0;
	
			end
		join
	end		
 endcase
#50;
$finish;

end



endmodule
