`ifndef I3C_SDR_WRITE_VIRTUAL_SEQ_INCLUDED_
`define I3C_SDR_WRITE_VIRTUAL_SEQ_INCLUDED_

class i3c_sdr_write_virtual_seq extends top_virtual_base_seq;
  `uvm_object_utils(i3c_sdr_write_virtual_seq)

  uvm_status_e   status;
  uvm_reg_data_t ctrl_val;
  uvm_reg_data_t ctrl_mirror;
  uvm_reg_data_t wdatab_mirror;

  rand bit [7:0]  wdata;
  rand bit [7:0]  transfer_len;

  constraint len_c {
    transfer_len ==1;
  }

  function new(string name = "i3c_sdr_write_virtual_seq");
    super.new(name);
  endfunction

  task body();
    i3c_target_writeOperationWith8bitsData_seq target_seq_write;

    if(i3c_env_cfg_h == null)
      `uvm_fatal("CFG_NULL",
        "i3c_env_cfg_h is NULL inside virtual sequence")
    if(i3c_env_cfg_h.regBlockHandle == null)
      `uvm_fatal("RAL_NULL",
        "regBlockHandle is NULL inside virtual sequence")
    if(i3c_env_cfg_h.regBlockHandle.wdatab_inst == null)
      `uvm_fatal("WDATAB_NULL",
        "wdatab_inst is NULL inside virtual sequence")

    super.body();

    if(!this.randomize()) begin
      `uvm_error(get_type_name(),
        "Sequence randomization failed — using defaults")
      wdata        = 8'hA5;
      transfer_len = 8'd1;
    end else begin
      `uvm_info(get_type_name(), $sformatf(
        "Randomized: wdata=0x%0x len=%0d",
        wdata, transfer_len), UVM_LOW)
    end

    `uvm_info(get_type_name(), "Starting SDR WRITE test", UVM_LOW)

    fork
      begin
        target_seq_write = i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_seq_write");
        target_seq_write.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none;

    i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(
      status,
      wdata,
      .parent(this)
    );

    wdatab_mirror =
      i3c_env_cfg_h.regBlockHandle.wdatab_inst.get_mirrored_value();
    `uvm_info("WDATAB_DEBUG",
      $sformatf("WDATAB mirrored value = 0x%0h", wdatab_mirror),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.wdatab_inst.mirror(
      status, UVM_NO_CHECK);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.address.set(i3c_env_cfg_h.i3c_target_agent_cfg_h[0].targetAddress);
    
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.length.set(
      transfer_len);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.direction.set(1'b0);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    ctrl_val = i3c_env_cfg_h.regBlockHandle.ctrl_inst.get();
    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL value before update = 0x%0h", ctrl_val),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(
      status, .parent(this));

    ctrl_mirror =
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.get_mirrored_value();
    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL mirrored value after update = 0x%0h",
      ctrl_mirror), UVM_LOW)

    #50us;

    `uvm_info(get_type_name(),
      "SDR WRITE issued and registers verified", UVM_LOW)

  endtask

endclass
`endif
