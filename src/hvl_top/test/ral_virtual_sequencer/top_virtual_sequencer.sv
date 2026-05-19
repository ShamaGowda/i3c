`ifndef TOP_VIRTUAL_SEQUENCER_INCLUDED_
`define TOP_VIRTUAL_SEQUENCER_INCLUDED_

class top_virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);

  `uvm_component_utils(top_virtual_sequencer)

  function new(string name = "top_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction

endclass

`endif
