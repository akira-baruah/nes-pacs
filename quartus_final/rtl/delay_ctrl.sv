parameter
   RESET_CPU = 8'd0,
	START_CPU = 8'd1,
	PAUSE_CPU = 8'd2,
	WRITE_MEM = 8'd3
;

module delay_ctrl (
    input logic clk,
    input logic faster,
    output logic slower,
	 //output logic [3:0] blink_delay,
	 
	 input logic reset,
	 
	 input logic read,
    output logic [15:0] readdata,
	 
	 input logic write,
	 input logic [15:0] writedata,
	 input logic [15:0] address
);


logic cpu_ready;
logic sync;
logic cpu_write, mem_write, cpu_reset;
logic [15:0] cpu_addr, mem_addr;
logic [7:0] d_out, mem_in, mem_out;
logic [7:0] nes_op;                       // our own NES opcodes

logic [15:0] tmp_data;

assign nes_op = writedata[15:8];

initial begin
	tmp_data = 6;
end

//logic [3:0] delay_intern = 4'b1000;
//assign blink_delay = delay_intern;



always_ff @(posedge clk) begin
	if (write) begin
		tmp_data <= tmp_data + 1;
	end

	if (read) begin
		slower <= 1;
 		readdata <= tmp_data;
	end else begin
		slower <= 0;
 		readdata <= 7;
	end

	readdata <= tmp_data;
end

cpu c (
   .clk (clk),
   .reset (cpu_reset),
   .ready (cpu_ready),
   .irq (0),
   .nmi (0),
   .d_in (mem_out),
   .write (cpu_write),
   .sync (sync),
   .d_out (d_out),
   .addr (cpu_addr)
);

memory mem (
   .clk (clk),
   .addr (mem_addr),
   .write (mem_write),
   .in (mem_in),
   .out (mem_out)
);


always_ff @ (posedge clk) begin
   case (nes_op)
      RESET_CPU: begin
         cpu_ready <= 0;
         cpu_reset <= 1;
         end
      WRITE_MEM: begin
         cpu_ready <= 0;
         mem_write <= 1;
         mem_addr <= address;
         mem_in <= writedata[7:0];
         end
      PAUSE_CPU: begin
         cpu_ready <= 0;
         cpu_reset <= 0;
		end
      START_CPU: begin
         cpu_ready <= 1;
         cpu_reset <= 0;
         mem_in <= d_out;
         mem_write <= cpu_write;
         mem_addr <= cpu_addr;
         end
      default: begin             // keep running CPU
         cpu_ready <= 1;
         cpu_reset <= 0;
         mem_in <= d_out;
         mem_write <= cpu_write;
         mem_addr <= cpu_addr;
         end
   endcase

   //TODO: readdata[7:0] <= mem_out;

end
endmodule



/*
logic [3:0] delay_intern = 4'b1000;

assign delay = delay_intern;

always_ff @(posedge clk) begin
    if (reset)
        delay_intern <= 4'b1000;
    else if (faster && delay_intern != 4'b0001)
        delay_intern <= delay_intern - 1'b1; 
    else if (slower && delay_intern != 4'b1111)
        delay_intern <= delay_intern + 1'b1;
end
*/

