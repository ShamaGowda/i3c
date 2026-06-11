// ============================================================================
// FILE: i3c_virtual_sequencer.sv  (MULTI-SLAVE VERSION)
//
// The virtual sequencer now holds an ARRAY of target sequencer handles
// (one per slave).  The DAA virtual sequence iterates this array and
// starts a DAA sequence on each element in parallel.
// ============================================================================
`ifndef TOP_VIRTUAL_SEQUENCER_INCLUDED_
`define TOP_VIRTUAL_SEQUENCER_INCLUDED_

class top_virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);
  `uvm_component_utils(top_virtual_sequencer)

  // Environment config – set by i3c_env during connect_phase
  i3c_env_config           i3c_env_cfg_h;

  // APB master sequencer (unchanged)
  apb_master_sequencer     apb_master_seqr_h;

  // ARRAY of target sequencers – index matches target agent index
  // Populated by i3c_env::connect_phase()
  i3c_target_sequencer     i3c_target_seqr_h[];

  // NOTE: no controller sequencer – the DUT IS the controller.
  // The testbench drives the DUT exclusively through the APB master AVIP.

  function new(string name = "top_virtual_sequencer",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass : top_virtual_sequencer

`endif

