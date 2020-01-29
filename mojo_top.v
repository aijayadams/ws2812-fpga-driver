module mojo_top(
    // 50MHz clock input
    input clk,
    // Input from reset button (active low)
    input rst_n,
    // cclk input from AVR, high when AVR is ready
    input cclk,
    // Outputs to the 8 onboard LEDs
    output[7:0]led,
    // AVR SPI connections
    output spi_miso,
    input spi_ss,
    input spi_mosi,
    input spi_sck,
    // AVR ADC channel select
    output [3:0] spi_channel,
    // Serial connections
    input avr_tx, // AVR Tx => FPGA Rx
    output avr_rx, // AVR Rx => FPGA Tx
    input avr_rx_busy, // AVR Rx buffer full
	 // WS2812
	 output reg d_out
    );

wire rst = ~rst_n; // make reset active high

// these signals should be high-z when not used
assign spi_miso = 1'bz;
assign avr_rx = 1'bz;
assign spi_channel = 4'bzzzz;

wire nclock;

wire [31:0] colour;
reg [31:0] mdin = 0;
reg [31:0] addra = 0;
reg [3:0] wea = 0;

blkmem colours (
  .clka(clk), // input clka
  .wea(wea), // input [3 : 0] wea
  .addra(addra), // input [31 : 0] addra
  .dina(mdin), // input [31 : 0] dina
  .douta(colour) // output [31 : 0] douta
);


// Start LED Control
parameter FSM_RST = 3'b000;
parameter FSM_1_H = 3'b001;
parameter FSM_1_L = 3'b010;
parameter FSM_0_H = 3'b011;
parameter FSM_0_L = 3'b100;
parameter FSM_READ = 3'b101;

parameter TEST_COLOR = 48'h020020000000;
parameter TEST_BLACK = 48'h000000020020;
parameter TEST_LEN = 8'd48;

parameter T1H = 32'd35; //0.70us
parameter T1L = 32'd30; //0.60us
parameter T0H = 32'd17; //0.34us
parameter T0L = 32'd35; //0.80us
parameter T_RES = 32'd50000; //1ms
parameter NUM_LEDS = 8'd2;

wire send_data = led[0];

reg [2:0] FSM = 3'b000;
reg [7:0] r_position = 8'b0;
reg [7:0] current_led = 8'b0;
wire [31:0] counter1;
reg counter1_rst = 1'b0;

reg flip_colour = 1'b0;
reg [31:0] filp_counter = 0;

assign led[7:3] = 0;
assign led[2:0] = FSM[2:0];

initial begin
d_out = 1'b0;

end
counter counter1_cntr(.rst(counter1_rst), .clk(clk), .mycounter(counter1));

always @(posedge clk) 
  case(FSM)
    FSM_RST: begin
      if (filp_counter == 1000) begin
        filp_counter = 0;
        flip_colour = ~flip_colour;
      end
      filp_counter = filp_counter + 1;
      // Reset Read
      counter1_rst = 0;
      current_led = 0;
      r_position = 8'b0;
      d_out = 1'b0;
      if (addra > 100)
        addra = 0;
      if (counter1 > T_RES) begin
          counter1_rst = 1;
          FSM = FSM_READ;
      end
    end
    
    FSM_READ: begin
      if (r_position == TEST_LEN) begin
        addra = addra + 1;
      if ((current_led + 1) == NUM_LEDS) begin
        FSM = FSM_RST;
        counter1_rst = 1;
      end else begin
        r_position = 0;
      current_led = current_led + 1;
      end
        
      end else begin
      if (flip_colour) begin
          if (colour[r_position] == 1) begin
              FSM = FSM_1_H;
          end else begin
              FSM = FSM_0_H;
          end
      end else begin
          if (TEST_BLACK[r_position] == 1) begin
              FSM = FSM_1_H;
          end else begin
              FSM = FSM_0_H;
          end
      end
        r_position = r_position + 1;
        end
    end

    FSM_1_H: begin
      counter1_rst = 0;
      d_out= 1'b1;
      if(counter1 > T1H) begin
        counter1_rst = 1'b1;
        FSM = FSM_1_L;
      end
  end
  
  FSM_1_L: begin
      counter1_rst = 0;
      d_out = 1'b0;
      if(counter1 > T1L) begin
        counter1_rst = 1'b1;
        FSM = FSM_READ;
      end
  end
  
  FSM_0_H: begin
      counter1_rst = 0;
      d_out = 1'b1;
      if(counter1 > T0H) begin
        counter1_rst = 1'b1;
        FSM = FSM_0_L;
      end
  end
  
  FSM_0_L: begin
      counter1_rst = 0;
      d_out = 1'b0;
      d_out = 1'b0;
      if(counter1 > T0L) begin
        counter1_rst = 1'b1;
        FSM = FSM_READ;
      end
    end
  
endcase

endmodule