`ifndef TOP_VIRTUAL_BASE_SEQ_INCLUDED_
`define TOP_VIRTUAL_BASE_SEQ_INCLUDED_

class top_virtual_base_seq extends
  uvm_sequence #(uvm_sequence_item);

  `uvm_object_utils(top_virtual_base_seq)
  `uvm_declare_p_sequencer(top_virtual_sequencer)

  i3c_env_config i3c_env_cfg_h;


  function new(string name =
               "top_virtual_base_seq");

    super.new(name);

  endfunction


  task body();

    if(p_sequencer == null)
      `uvm_fatal("SEQ_NULL",
        "Virtual sequencer handle is NULL")


    i3c_env_cfg_h =
      p_sequencer.i3c_env_cfg_h;


    if(i3c_env_cfg_h == null)
      `uvm_fatal("CFG_NULL",
        "i3c_env_cfg_h is NULL in base virtual sequence")


  endtask

endclass

`endif
