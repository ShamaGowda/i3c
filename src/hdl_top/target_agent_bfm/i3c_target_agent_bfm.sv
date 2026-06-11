
`ifndef I3C_TARGET_AGENT_BFM_INCLUDED_
`define I3C_TARGET_AGENT_BFM_INCLUDED_

module i3c_target_agent_bfm
  #(parameter int target_ID = 0)
  (i3c_if intf);

  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import i3c_globals_pkg::*;

  // -------------------------------------------------------------------------
  // Driver BFM – wired to the per-target slice of the interface arrays
  // -------------------------------------------------------------------------
  i3c_target_driver_bfm i3c_target_drv_bfm_h (
    .pclk    (intf.pclk),
    .areset  (intf.areset),
    .scl_i   (intf.scl_i),
    .scl_o   (intf.scl_o  [target_ID]),
    .scl_oen (intf.scl_oen[target_ID]),
    .sda_i   (intf.sda_i),
    .sda_o   (intf.sda_o  [target_ID]),
    .sda_oen (intf.sda_oen[target_ID])
  );

  // -------------------------------------------------------------------------
  // Monitor BFM – passive; shares the same bus view
  // -------------------------------------------------------------------------
  i3c_target_monitor_bfm i3c_target_mon_bfm_h (
    .pclk    (intf.pclk),
    .areset  (intf.areset),
    .scl_i   (intf.scl_i),
    .scl_o   (intf.scl_o  [target_ID]),
    .scl_oen (intf.scl_oen[target_ID]),
    .sda_i   (intf.sda_i),
    .sda_o   (intf.sda_o  [target_ID]),
    .sda_oen (intf.sda_oen[target_ID])
  );

  // -------------------------------------------------------------------------
  // Register BFM handles in config_db with per-target keys
  //   Key format:  "i3c_target_driver_bfm_<ID>"
  //   The driver proxy looks up the same key (see i3c_target_driver_proxy.sv)
  // -------------------------------------------------------------------------
  initial begin
    static string drv_key = $sformatf("i3c_target_driver_bfm_%0d",  target_ID);
    static string mon_key = $sformatf("i3c_target_monitor_bfm_%0d", target_ID);

    `uvm_info("TGT_AGENT_BFM",
      $sformatf("Registering BFMs: drv_key=%s  mon_key=%s",
                drv_key, mon_key), UVM_LOW)

    uvm_config_db #(virtual i3c_target_driver_bfm)::set(
        null, "*", drv_key, i3c_target_drv_bfm_h);

    uvm_config_db #(virtual i3c_target_monitor_bfm)::set(
        null, "*", mon_key, i3c_target_mon_bfm_h);
  end

  initial begin
    $display("i3c_target_agent_bfm: target_ID=%0d", target_ID);
  end

endmodule : i3c_target_agent_bfm

`endif

