/*
Sonar on Chip top level module based on user project example
Files:
defines.v - macroodefinitions (come vith Caravel)
Mic_Clk.v - clock divider for MEMS microphones
*/
`include "defines.v"
`define BUS_WIDTH 32

module SonarOnChip(
  
  `ifdef USE_POWER_PINS
    inout vdda1,	// User area 1 3.3V supply
    inout vdda2,	// User area 2 3.3V supply
    inout vssa1,	// User area 1 analog ground
    inout vssa2,	// User area 2 analog ground
    inout vccd1,	// User area 1 1.8V supply
    inout vccd2,	// User area 2 1.8v supply
    inout vssd1,	// User area 1 digital ground
    inout vssd2,	// User area 2 digital ground
  `endif

    // Wishbone Slave ports (WB MI A)
    input wire wb_clk_i,
    input wire wb_rst_i,
    input wire wbs_stb_i,
    input wire wbs_cyc_i,
    input wire wbs_we_i,
    input wire [3:0] wbs_sel_i,
    input wire [`BUS_WIDTH:0] wbs_dat_i,
    input wire [`BUS_WIDTH:0] wbs_adr_i,
    output wire wbs_ack_o,
    output wire [`BUS_WIDTH:0] wbs_dat_o,

    // Logic Analyzer Signals
    input wire  [127:0] la_data_in,
    output wire [127:0] la_data_out,
    input wire  [127:0] la_oenb,
 

    // IOs
    input wire  [`MPRJ_IO_PADS-1:0] io_in,
    output wire [`MPRJ_IO_PADS-1:0] io_out,
    output wire [`MPRJ_IO_PADS-1:0] io_oeb,

    // IRQ
  output wire [2:0] irq
	);
  /*----------------------------- module declaration ends ---------------------*/
  
  /* clock and reset signals*/
  
  wire clk;
  wire rst;
  
  // enable outputs (input does not care about that)
  assign io_oeb = 38'h0000000000;
  
  assign clk = wb_clk_i;
  assign rst = wb_rst_i;
  
  /* Clock signal for MEMS microphones */
  wire mclk;
  
  
  /* Compare module wires*/
  wire [`BUS_WIDTH:0] treshold;
  wire [`BUS_WIDTH:0] maf_o;
  wire compare_ch1_out;
 
  /* PCM inputs from GPIO, will come from PDM */	
  wire [15:0] pcm_i;
	assign pcm_i = io_in[15:0];

  /* PCM register output signal*/
  wire [15:0] pcm_o;
  /* 32 - bit sign extended pcm value */
  wire [`BUS_WIDTH:0] pcm32, pcm32abs;
  
  /* clock enable wiring*/
  wire ce;
  //assign ce = la_data_in[0]; 
  
  /* Multiplier  output */
  wire [`BUS_WIDTH:0] mul_o;
  
  /* Amplifier register signals */
  wire [`BUS_WIDTH:0] amp_i;
  wire [`BUS_WIDTH:0] amp;
  
  //assign amp_i = 32'h00000001;
  
 /** Wishbone Slave Interface **/
	wire [31:0] rdata; 
	wire [31:0] wdata;
	
	wire wb_valid;
	wire [3:0] wstrb;
	wire [31:0] la_write;
    // WB MI A
	assign wb_valid = wbs_cyc_i && wbs_stb_i; 
  assign ce = wb_valid; 
	assign wstrb = wbs_sel_i & {4{wbs_we_i}};
	assign wbs_dat_o = rdata;
	assign wdata = wbs_dat_i;
	assign amp_i = wdata;  

	//always @(posedge clk) begin
	//	if (valid && !ready) begin
	//	    ready <= 1'b1;
	//	    rdata <= count;
	//	    if (wstrb[0]) amp_i[7:0]   <= wdata[7:0];
	//	    if (wstrb[1]) amp_i[15:8]  <= wdata[15:8];
	//	    if (wstrb[2]) amp_i[23:16] <= wdata[23:16];
	//	    if (wstrb[3]) amp_i[31:24] <= wdata[31:24];
	//	end
	//end

  /*-------------------------Structural modelling ----------------------------*/
  
  /*------------------------  PDM starts   -----------------------------------*/
  /*------------------------   PDM ends    -----------------------------------*/
  
  /*------------------------  PCM starts   -----------------------------------*/
  
  REG pcm_reg(clk, rst, ce, pcm_i, pcm_o);
  
  /*------------------------   PCM ends    -----------------------------------*/
  
  /*------------------------   SE starts    -----------------------------------*/
  signext se(pcm_o, pcm32);
  /*------------------------   SE ends    -----------------------------------*/
  
  /*------------------------  MUL starts   -----------------------------------*/
  MULTI mul(pcm32, amp, mul_o);
  /*------------------------   MUL ends    -----------------------------------*/
  
  /*------------------------ AMP starts   -----------------------------------*/
  REG #(.n(`BUS_WIDTH)) amp_reg(clk, rst, ce & wb_valid, amp_i, amp);
  /*------------------------ AMP endss   -----------------------------------*/
  
  
  /*------------------------  ABS starts   -----------------------------------*/
  Abs  abs(mul_o, pcm32abs);
  /*------------------------   ABS ends    -----------------------------------*/
  
  /*------------------------  IIR starts   -----------------------------------*/
  /*------------------------   IIR ends    -----------------------------------*/
  
  /*------------------------  MAMOV starts   ---------------------------------*/
  MAF_FILTER maf(clk, rst, ce, pcm32abs, maf_o);
  /*------------------------   MAMOV ends    ---------------------------------*/
  
  /*------------------------  COMP starts   ----------------------------------*/
  
  comparator comp(maf_o, treshold, compare_ch1_out);
  
  /*------------------------   COMP ends    ----------------------------------*/
  
  /*------------------------  CLKDIV starts   --------------------------------*/
 
  Mic_Clk micclk(clk, rst, mclk);
  
  /*------------------------  CLOCKDIV ends   --------------------------------*/


endmodule



