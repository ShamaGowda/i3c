`ifndef I3C_SDR_OR_DAA_VIRTUAL_SEQ_INCLUDED_
`define I3C_SDR_OR_DAA_VIRTUAL_SEQ_INCLUDED_

class i3c_sdr_or_daa_virtual_seq extends top_virtual_base_seq;
  `uvm_object_utils(i3c_sdr_or_daa_virtual_seq)

  uvm_status_e   status;
  uvm_reg_data_t ctrl_val;
  uvm_reg_data_t ctrl_mirror;

  function new(string name = "i3c_sdr_or_daa_virtual_seq");
    super.new(name);
  endfunction

  task body();
    i3c_target_daa_seq target_daa_seq;

    // Null checks
    if(i3c_env_cfg_h == null)
      `uvm_fatal("CFG_NULL",
        "i3c_env_cfg_h is NULL inside virtual sequence")
    if(i3c_env_cfg_h.regBlockHandle == null)
      `uvm_fatal("RAL_NULL",
        "regBlockHandle is NULL inside virtual sequence")

    super.body();

    `uvm_info(get_type_name(), "Starting sdr or DAA sequence", UVM_LOW)

        fork
      begin
        target_daa_seq = i3c_target_daa_seq::type_id::create("target_daa_seq");
        target_daa_seq.start(p_sequencer.i3c_target_seqr_h[0]);
      end
    join_none

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'd2);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_ccc.set(8'h07);   
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);  
  
    ctrl_val = i3c_env_cfg_h.regBlockHandle.ctrl_inst.get();
    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL value before DAA update = 0x%0h", ctrl_val),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status, .parent(this));

    ctrl_mirror = i3c_env_cfg_h.regBlockHandle.ctrl_inst.get_mirrored_value();
    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL mirrored value after DAA update = 0x%0h",
      ctrl_mirror), UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(status, UVM_NO_CHECK);

    #20000;

    `uvm_info(get_type_name(),
      "DAA completed — target assigned dynamic address 0x08",
      UVM_LOW)

  endtask

endclass
`endif
