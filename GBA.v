`timescale 1ns / 1ps

module top(
  input wire clk16,

  // onboard USB interface
  output pin_pu,
  output pin_usbp,
  output pin_usbn,

	input GBACART_WR,
  input GBACART_CS,
  input GBACART_RD,
	input GBACART_CS2,
  inout wire [15:0] GBACART_AD
);

assign pin_pu = 1'b1;
assign pin_usbp = 1'b0;
assign pin_usbn = 1'b0;

reg  [15:0] gba_data_out;
wire [15:0] gba_addr_lo_in;
reg  [15:0] gba_addr_lo;
//wire [23:0] gba_addr;
//assign gba_addr = {GBACART_AH, gba_addr_lo};

reg [15:0] rom [0:441];
initial $readmemh("fire.hex", rom);

reg risingRD, fallingRD, fallingCS;
reg [1:3] resyncRD;
reg [1:3] resyncCS;

always @(posedge clk) begin
  if (fallingRD && (gba_addr_lo < 16'd442)) gba_data_out = rom[gba_addr_lo[9:0]];
  if (risingRD) gba_addr_lo <= gba_addr_lo + 1'b1;
  else if (fallingCS) gba_addr_lo <= gba_addr_lo_in;

  // detect rising and falling edge(s)
  // (https://www.doulos.com/knowhow/fpga/synchronisation/)
  risingRD  <= resyncRD[2] & !resyncRD[3];
  fallingRD <= resyncRD[3] & !resyncRD[2];
  fallingCS <= resyncCS[3] & !resyncCS[2];

  // update history shifter(s)
  resyncRD <= {GBACART_RD, resyncRD[1:2]};
  resyncCS <= {GBACART_CS, resyncCS[1:2]};
end

// instantiate tristate IO
SB_IO #(
    .PIN_TYPE(6'b101001),
    .PULLUP(1'b0)
) gba_io[15:0] (
    .PACKAGE_PIN(GBACART_AD[15:0]),
    .OUTPUT_ENABLE((!GBACART_RD && !GBACART_CS)),
    .D_OUT_0(gba_data_out[15:0]),
    .D_IN_0(gba_addr_lo_in[15:0])
);

wire clk;
wire clk_locked;

SB_PLL40_CORE #(
    .FEEDBACK_PATH("SIMPLE"),
    .DIVR(4'b0000),		// DIVR =  0
    .DIVF(7'b0101011),	// DIVF = 43
    .DIVQ(3'b010),		// DIVQ =  2
    .FILTER_RANGE(3'b001)	// FILTER_RANGE = 1
) uut (
    .LOCK(clk_locked),
    .RESETB(1'b1),
    .BYPASS(1'b0),
    .REFERENCECLK(clk16),
    .PLLOUTCORE(clk)
);

endmodule
