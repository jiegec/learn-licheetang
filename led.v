module led
	( 
		input wire clk_in,
		input wire rst_n,
		output wire [2:0] rgb_led,
		
		input wire uart_rxd,
		output wire uart_txd
	);
	
	parameter CLK_HZ = 24_000_000;
	parameter BIT_RATE = 115200;
	parameter PAYLOAD_BITS = 8;

	wire rst;
	assign rst = !rst_n;
	
	wire uart_tx_busy;
	reg uart_tx_en;
	reg [PAYLOAD_BITS-1:0] uart_tx_data;

	wire uart_rx_break;
	wire uart_rx_valid;
	wire uart_rx_en;
	wire [PAYLOAD_BITS-1:0] uart_rx_data;

	wire uart_fifo_we;
	wire [PAYLOAD_BITS-1:0] uart_fifo_di;
	wire uart_fifo_re;
	wire [PAYLOAD_BITS-1:0] uart_fifo_do;
	wire uart_fifo_empty_flag;
	wire uart_fifo_full_flag;
	
	assign uart_rx_en = !uart_fifo_full_flag;
	assign uart_fifo_we = uart_rx_en && uart_rx_valid;
	assign uart_fifo_di = uart_rx_data;

	//assign uart_tx_data = uart_fifo_do;
	assign uart_fifo_re = !uart_tx_busy && !uart_fifo_empty_flag;
	
	always begin
		if (uart_fifo_do >= 8'h61 && uart_fifo_do <= 8'h6d) begin
			uart_tx_data <= uart_fifo_do + 13;
		end else if (uart_fifo_do >= 8'h6e && uart_fifo_do <= 8'h7a) begin
			uart_tx_data <= uart_fifo_do - 13;
		end else begin
			uart_tx_data <= uart_fifo_do;
		end
	end

	always @ (posedge clk_in) begin
		uart_tx_en <= uart_fifo_re;
	end

	uart_rx #(
	.BIT_RATE(BIT_RATE),
	.PAYLOAD_BITS(PAYLOAD_BITS),
	.CLK_HZ  (CLK_HZ  )
	) i_uart_rx(
	.clk          (clk_in          ), // Top level system clock input.
	.resetn       (rst_n         ), // Asynchronous active low reset.
	.uart_rxd     (uart_rxd     ), // UART Recieve pin.
	.uart_rx_en   (uart_rx_en   ), // Recieve enable
	.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
	.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
	.uart_rx_data (uart_rx_data )  // The recieved data.
	);
	
	uart_tx #(
	.BIT_RATE(BIT_RATE),
	.PAYLOAD_BITS(PAYLOAD_BITS),
	.CLK_HZ  (CLK_HZ  )
	) i_uart_tx(
	.clk          (clk_in       ),
	.resetn       (rst_n         ),
	.uart_txd     (uart_txd     ),
	.uart_tx_en   (uart_tx_en   ),
	.uart_tx_busy (uart_tx_busy ),
	.uart_tx_data (uart_tx_data ) 
	);

	uart_fifo i_uart_fifo(
		.clkw(clk_in),
		.clkr(clk_in),
		.rst(rst),
		.we(uart_fifo_we),
		.di(uart_fifo_di),
		.re(uart_fifo_re),
		.do(uart_fifo_do),
		.empty_flag(uart_fifo_empty_flag),
		.full_flag(uart_fifo_full_flag)
	);
	
	reg [2:0] rledout;
	reg [23:0] count;
	reg [1:0] shift_cnt;
	
	initial begin
		count = 24'b0;
		rledout = 3'b1;
		shift_cnt = 2'b0;
	end
	
	always @ (posedge clk_in) begin
		if (rst_n == 0) begin
			count <= 24'b0;
			rledout <= 3'b1;
			shift_cnt <= 2'b0;
		end

		if (count == CLK_HZ) begin
 			count <= 24'd0;
 			
 			if ( shift_cnt == 2'b10 ) begin
				rledout <= 3'b1;
				shift_cnt <=2'b0;
 			end
 			else begin
 				rledout <= {rledout[1:0],1'b0};
				shift_cnt <= shift_cnt + 1'b1;
			end
 		end
 		else
 			count <= count + 1'b1;
	end
	
	assign rgb_led = rledout;


endmodule
