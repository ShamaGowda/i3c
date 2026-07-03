// ============================================================================
// FILE: hdl_top.sv  (MULTI-SLAVE VERSION)
//
// Key changes vs single-slave:
//   1. i3c_if is instantiated with the NO_OF_TARGETS parameter so the
//      per-target sda_o/sda_oen/scl_o/scl_oen arrays are the right width.
//   2. The generate loop for i3c_target_agent_bfm passes target_ID=i so
//      each BFM registers in config_db with a unique key.
//   3. All per-target sda_o[i]/sda_oen[i] wire up to the interface slices;
//      open-drain wired-AND is inside i3c_if.
// ============================================================================
`ifndef HDL_TOP_INCLUDED_
`define HDL_TOP_INCLUDED_

import i3c_globals_pkg::*;
import apb_global_pkg::*;

module hdl_top;

  bit clk;
  bit rst;

  wire I3C_SCL;
  wire I3C_SDA;

  // APB clock / reset
  wire pclk;
  wire preset_n;

  assign pclk    = clk;
  assign preset_n = rst;

  // DUT register-interface signals
  logic        wr_en;
  logic        rd_en;
  logic [6:0]  addrs;
  logic [31:0] w_reg_data;
  logic [7:0]  w_data;
  logic [31:0] rd_data;
  logic [7:0]  r_data;
logic dut_cmd_dc_type;
assign dut_cmd_dc_type = 1'b0; 
  logic scl_o;
  wire  sda_o;
  logic sda_oe;

  initial begin
    $display("HDL TOP – multi-slave (%0d targets)", NO_OF_TARGETS);
  end

  // ---------------------------------------------------------------------------
  // Clock generation
  // ---------------------------------------------------------------------------
  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  // ---------------------------------------------------------------------------
  // Reset generation
  // ---------------------------------------------------------------------------
  initial begin
    rst = 1'b1;
    repeat (2) @(posedge clk);
    rst = 1'b0;
    repeat (2) @(posedge clk);
    rst = 1'b1;
  end

  // ---------------------------------------------------------------------------
  // APB interface
  // ---------------------------------------------------------------------------
  apb_if apb_intf(.pclk(pclk), .preset_n(preset_n));

  // ---------------------------------------------------------------------------
  // I3C bus – shared open-drain wires (pulled high by pullups below)
  // ---------------------------------------------------------------------------
  pullup p_scl (I3C_SCL);
  pullup p_sda (I3C_SDA);

  // ---------------------------------------------------------------------------
  // I3C interface – parameterised with NO_OF_TARGETS so the per-slave
  // drive arrays are sized correctly
  // ---------------------------------------------------------------------------
  i3c_if #(.NO_OF_TARGETS(NO_OF_TARGETS)) intf_i3c (
    .pclk   (clk),
    .areset (rst),
    .SCL    (I3C_SCL),
    .SDA    (I3C_SDA)
  );

  // ---------------------------------------------------------------------------
  // APB → DUT register wrapper
  // ---------------------------------------------------------------------------
  apb_i3c_wrapper wrapper (
    .apb        (apb_intf),
    .wr_en      (wr_en),
    .rd_en      (rd_en),
    .addrs      (addrs),
    .w_reg_data (w_reg_data),
    .w_data     (w_data),
    .rd_data    (rd_data),
    .r_data     (r_data)
  );

  // ---------------------------------------------------------------------------
  // DUT (I3C MASTER)
  // ---------------------------------------------------------------------------
  I3C_TOP dut (
    .clk        (clk),
    .rst_n      (rst),
    .wr_en      (wr_en),
    .rd_en      (rd_en),
    .addrs      (addrs),
    .w_reg_data (w_reg_data),
    .w_data     (w_data),
    .rd_data    (rd_data),
    .r_data     (r_data),
    .scl_i      (I3C_SCL),
      .cmd_dc_type (dut_cmd_dc_type),
    .sda_i      (I3C_SDA),
    .sda_o      (sda_o),
    .sda_oe     (sda_oe)
  );
//.scl_o      (scl_o),
  // ---------------------------------------------------------------------------
  // APB master BFM – programs DUT registers (the only master-side BFM needed)
  // NOTE: No i3c_controller_agent_bfm – the DUT IS the controller.
  //       The I3C bus is observed only through the per-slave target BFMs.
  // ---------------------------------------------------------------------------
  apb_master_agent_bfm apb_master_agent_bfm_h (apb_intf);

  // ---------------------------------------------------------------------------
  // Target agent BFMs – one per slave, each gets its own ID
  // The generate loop passes target_ID so config_db keys are unique.
  // ---------------------------------------------------------------------------
  genvar i;
  generate
    for (i = 0; i < NO_OF_TARGETS; i++) begin : gen_target_bfm
      i3c_target_agent_bfm #(
        .target_ID(i)
      ) i3c_target_agent_bfm_inst (
        .intf (intf_i3c)
      );
    end
  endgenerate

  // ---------------------------------------------------------------------------
  // Wave dump
  // ---------------------------------------------------------------------------
  initial begin
    $dumpfile("i3c_avip.vcd");
    $dumpvars();
  end

endmodule : hdl_top

`endif

