`ifndef I3C_VERIFY_REPEATED_START_SEQ_INCLUDED_
`define I3C_VERIFY_REPEATED_START_SEQ_INCLUDED_

class i3c_verify_repeated_start_seq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_verify_repeated_start_seq)

  uvm_status_e status;
  uvm_reg_data_t wdatab_mirror;
  uvm_reg_data_t ctrl_mirror;

  function new(string name = "i3c_verify_repeated_start_seq");
    super.new(name);
  endfunction


  task body();

    i3c_target_writeOperationWith8bitsData_seq target_seq;

    super.body();

    `uvm_info(get_type_name(),
      "Starting Repeated Start Verification",
      UVM_LOW)


    fork
      forever begin
        target_seq =
          i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_seq");

        target_seq.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none;


    i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(status, 8'hA5);

    wdatab_mirror =
      i3c_env_cfg_h.regBlockHandle.wdatab_inst.get_mirrored_value();

    `uvm_info("WDATAB_DEBUG",
      $sformatf("WDATAB mirror value = %0h", wdatab_mirror),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.wdatab_inst.mirror(status, UVM_CHECK);


    i3c_env_cfg_h.regBlockHandle.ctrl_inst.address.set(TARGET0_ADDRESS);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.length.set(8'd1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.direction.set(1'b0);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    ctrl_mirror =
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.get();

    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL start bit set to = %0d", ctrl_mirror),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(status, UVM_CHECK);


    #5000;


    i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(status, 8'h3C);

    wdatab_mirror =
      i3c_env_cfg_h.regBlockHandle.wdatab_inst.get_mirrored_value();

    `uvm_info("WDATAB_DEBUG",
      $sformatf("WDATAB mirror value = %0h", wdatab_mirror),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.wdatab_inst.mirror(status, UVM_CHECK);


    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    ctrl_mirror =
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.get();

    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL start bit for repeated start = %0d", ctrl_mirror),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(status, UVM_CHECK);


    #5000;


    `uvm_info(get_type_name(),
      "Repeated Start transfer completed successfully",
      UVM_MEDIUM)

  endtask

endclass

`endif
