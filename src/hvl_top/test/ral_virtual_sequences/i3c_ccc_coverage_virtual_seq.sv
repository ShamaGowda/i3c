`ifndef I3C_CCC_COVERAGE_VIRTUAL_SEQ_INCLUDED_
`define I3C_CCC_COVERAGE_VIRTUAL_SEQ_INCLUDED_

class i3c_ccc_coverage_virtual_seq extends top_virtual_base_seq;
  `uvm_object_utils(i3c_ccc_coverage_virtual_seq)

  uvm_status_e   status;
  uvm_reg_data_t ctrl_val;
  uvm_reg_data_t ctrl_mirror;

  bit [7:0] ccc_values[$] = '{8'h08, 8'h10, 8'h20, 8'h40, 8'h80};

  function new(string name = "i3c_ccc_coverage_virtual_seq");
    super.new(name);
  endfunction

  task body();
    if(i3c_env_cfg_h == null)
      `uvm_fatal("CFG_NULL",
        "i3c_env_cfg_h is NULL inside virtual sequence")
    if(i3c_env_cfg_h.regBlockHandle == null)
      `uvm_fatal("RAL_NULL",
        "regBlockHandle is NULL inside virtual sequence")

    super.body();

    `uvm_info(get_type_name(),
      "Starting CCC coverage sequence", UVM_LOW)

    foreach(ccc_values[i]) begin
      `uvm_info(get_type_name(), $sformatf(
        "=== CCC iteration %0d: ccc=0x%0x ===",
        i, ccc_values[i]), UVM_LOW)

      i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'd1);
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_ccc.set(
        ccc_values[i]);
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(
        i3c_env_cfg_h.i3c_target_agent_cfg_h[0].targetAddress);
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(8'd1);
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b0);
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

      ctrl_val = i3c_env_cfg_h.regBlockHandle.ctrl_inst.get();
      `uvm_info(get_type_name(), $sformatf(
        "CTRL value before update = 0x%0h (ccc=0x%0x)",
        ctrl_val, ccc_values[i]), UVM_LOW)

      i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(
        status, .parent(this));

      ctrl_mirror =
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.get_mirrored_value();
      `uvm_info(get_type_name(), $sformatf(
        "CTRL mirrored after update = 0x%0h", ctrl_mirror), UVM_LOW)

      i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(
        status, UVM_NO_CHECK);

      #5000;

      `uvm_info(get_type_name(), $sformatf(
        "CCC 0x%0x iteration done", ccc_values[i]), UVM_LOW)

    end

    `uvm_info(get_type_name(),
      "CCC coverage sequence complete", UVM_LOW)

  endtask

endclass
`endif
