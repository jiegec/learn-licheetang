module led
	( 
		input wire CLK_IN,
		input wire RST_N,
		output wire [2:0] RGB_LED,
		
		input wire UART_RXD,
		output wire UART_TXD
	);
	
	parameter time1 = 24'd24_000_000;
	parameter CLK_HZ = 24_000_000;
	parameter BIT_RATE = 115200;
	parameter PAYLOAD_BITS = 8;
	
	wire uart_tx_busy;
	wire uart_tx_en;
	wire [PAYLOAD_BITS-1:0] uart_tx_data;
	wire uart_rx_break;
	wire uart_rx_valid;
	wire [PAYLOAD_BITS-1:0] uart_rx_data;
	
	
	assign uart_tx_en = !uart_tx_busy && uart_rx_valid;
	assign uart_tx_data = uart_rx_data;

	uart_rx #(
	.BIT_RATE(BIT_RATE),
	.PAYLOAD_BITS(PAYLOAD_BITS),
	.CLK_HZ  (CLK_HZ  )
	) i_uart_rx(
	.clk          (CLK_IN          ), // Top level system clock input.
	.resetn       (RST_N         ), // Asynchronous active low reset.
	.uart_rxd     (UART_RXD     ), // UART Recieve pin.
	.uart_rx_en   (1'b1         ), // Recieve enable
	.uart_rx_break(uart_rx_break), // Did we get a BREAK message?
	.uart_rx_valid(uart_rx_valid), // Valid data recieved and available.
	.uart_rx_data (uart_rx_data )  // The recieved data.
	);
	
	uart_tx #(
	.BIT_RATE(BIT_RATE),
	.PAYLOAD_BITS(PAYLOAD_BITS),
	.CLK_HZ  (CLK_HZ  )
	) i_uart_tx(
	.clk          (CLK_IN       ),
	.resetn       (RST_N         ),
	.uart_txd     (UART_TXD     ),
	.uart_tx_en   (uart_tx_en   ),
	.uart_tx_busy (uart_tx_busy ),
	.uart_tx_data (uart_tx_data ) 
	);
	
	reg [2:0] rledout;
	reg [23:0] count;
	reg [1:0] shift_cnt;
	
	initial begin
		count = 24'b0;
		rledout = 3'b1;
		shift_cnt = 2'b0;
	end
	
	always @ (posedge CLK_IN) begin
		if (RST_N == 0) begin
			count <= 24'b0;
			rledout <= 3'b1;
			shift_cnt <= 2'b0;
		end

		if (count == time1) begin
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
	
	assign RGB_LED = rledout;


endmodule
