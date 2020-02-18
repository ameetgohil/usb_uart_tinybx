// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
    output LED,   // User/boot LED next to power LED
    inout USBP,
    inout USBN,
    output USBPU  // USB pull-up resistor
);

wire clk_48mhz;
wire locked;

wire [7:0] uart_in_data;
wire uart_in_valid;
wire uart_in_ready;

wire [7:0] uart_out_data;
wire uart_out_valid;
wire uart_out_ready;

SB_PLL40_CORE #(
  .FEEDBACK_PATH("SIMPLE"),
  .DIVR(4'b0000),		// DIVR =  0
  .DIVF(7'b0101111),	// DIVF = 47
  .DIVQ(3'b100),		// DIVQ =  4
  .FILTER_RANGE(3'b001)	// FILTER_RANGE = 1
) uut (
  .LOCK(locked),
  .RESETB(1'b1),
  .BYPASS(1'b0),
  .REFERENCECLK(CLK),
  .PLLOUTCORE(clk_48mhz)
  );


  //  Generate reset signal
  reg [5:0] reset_cnt = 0;
  wire reset = ~reset_cnt[5];
  always @(posedge clk_48mhz)
      if ( locked )
          reset_cnt <= reset_cnt + reset;

  wire usb_p_tx;
  wire usb_n_tx;
  wire usb_p_rx;
  wire usb_n_rx;
  wire usb_tx_en;
  wire usb_p_in;
  wire usb_n_in;


  usb_uart_core uart (
    .clk_48mhz  (clk_48mhz),
    .reset      (reset),

    // pins - these must be connected properly to the outside world.  See below.
    .usb_p_tx(usb_p_tx),
    .usb_n_tx(usb_n_tx),
    .usb_p_rx(usb_p_rx),
    .usb_n_rx(usb_n_rx),
    .usb_tx_en(usb_tx_en),

    // uart pipeline in
    .uart_in_data( uart_out_data ),
    .uart_in_valid( uart_out_valid ),
    .uart_in_ready( uart_out_ready ),

    // uart pipeline out
    .uart_out_data( uart_out_data ),
    .uart_out_valid( uart_out_valid ),
    .uart_out_ready( uart_out_ready ),

    .debug( debug )
  );

  assign USBPU = 1'b1;

  assign usb_p_rx = usb_tx_en ? 1'b1 : usb_p_in;
  assign usb_n_rx = usb_tx_en ? 1'b0 : usb_n_in;

  SB_IO #(
    .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    .PULLUP(1'b 0)
  )
  iobuf_usbp
  (
    .PACKAGE_PIN(USBP),
    .OUTPUT_ENABLE(usb_tx_en),
    .D_OUT_0(usb_p_tx),
    .D_IN_0(usb_p_in)
  );

  SB_IO #(
    .PIN_TYPE(6'b 1010_01), // PIN_OUTPUT_TRISTATE - PIN_INPUT
    .PULLUP(1'b 0)
  )
  iobuf_usbn
  (
    .PACKAGE_PIN(USBN),
    .OUTPUT_ENABLE(usb_tx_en),
    .D_OUT_0(usb_n_tx),
    .D_IN_0(usb_n_in)
  );

endmodule
