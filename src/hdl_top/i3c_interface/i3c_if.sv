// ============================================================================
// FILE: i3c_if.sv  (MULTI-SLAVE VERSION)
// 
// Each target drives its own sda_o[i]/sda_oen[i]/scl_o[i]/scl_oen[i].
// The bus lines are wired-AND (open-drain pull-up modelled by pullup in
// hdl_top).  Any device that asserts its OEN=1 drives a 0; the SDA/SCL
// wire goes low.  A device that releases (OEN=0) is high-impedance.
// ============================================================================

interface i3c_if #(parameter int NO_OF_TARGETS = 1)
    (input pclk, input areset, inout SCL, inout SDA);

  import i3c_globals_pkg::*;

  // -----------------------------------------------------------------------
  // Shared sampled-bus view (read by all agents)
  // -----------------------------------------------------------------------
  logic scl_i;
  logic sda_i;

  // -----------------------------------------------------------------------
  // Per-target drive signals  (index 0 = target 0, etc.)
  // -----------------------------------------------------------------------
  logic [NO_OF_TARGETS-1:0] scl_o;
  logic [NO_OF_TARGETS-1:0] scl_oen;  // 1 = drive, 0 = tristate
  logic [NO_OF_TARGETS-1:0] sda_o;
  logic [NO_OF_TARGETS-1:0] sda_oen;  // 1 = drive, 0 = tristate

  // -----------------------------------------------------------------------
  // Wired-AND open-drain model
  //   SCL/SDA go low if ANY driver asserts a 0 (oen=1, o=0).
  //   SCL/SDA float high if all drivers are released (all oen=0 or o=1).
  // -----------------------------------------------------------------------
  genvar gi;
  generate
    for (gi = 0; gi < NO_OF_TARGETS; gi++) begin : tgt_drive
      assign SCL = (scl_oen[gi] && !scl_o[gi]) ? 1'b0 : 1'bz;
      assign SDA = (sda_oen[gi] && !sda_o[gi]) ? 1'b0 : 1'bz;
    end
  endgenerate

  // -----------------------------------------------------------------------
  // Sampling: bus value seen by every agent
  // -----------------------------------------------------------------------
  assign scl_i = SCL;
  assign sda_i = SDA;

endinterface : i3c_if

