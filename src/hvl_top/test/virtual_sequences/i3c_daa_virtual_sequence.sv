`ifndef I3C_VIRTUAL_DAA_SEQ_INCLUDED_
`define I3C_VIRTUAL_DAA_SEQ_INCLUDED_

class i3c_virtual_daa_seq extends i3c_virtual_base_seq;
  `uvm_object_utils(i3c_virtual_daa_seq)

  i3c_target_daa_seq i3c_target_daa_seq_h;


  extern function new(string name = "i3c_virtual_daa_seq");
  extern task body();

endclass : i3c_virtual_daa_seq


function i3c_virtual_daa_seq::new(string name = "i3c_virtual_daa_seq");
  super.new(name);
endfunction : new


task i3c_virtual_daa_seq::body();
  super.body();

  `uvm_info(get_type_name(), "Starting DAA virtual sequence", UVM_LOW)

  i3c_target_daa_seq_h = i3c_target_daa_seq::type_id::create("i3c_target_daa_seq_h");

  fork
    begin 
      i3c_target_daa_seq_h.start(p_sequencer.i3c_target_seqr_h);
    end
  join_none


  `uvm_info(get_type_name(),"DAA virtual sequence completed", UVM_LOW)

endtask : body

`endif
