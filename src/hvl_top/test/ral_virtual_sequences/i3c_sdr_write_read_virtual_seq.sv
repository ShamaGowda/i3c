 `ifndef I3C_SDR_WRITE_READ_VIRTUAL_SEQ_INCLUDED_
`define I3C_SDR_WRITE_READ_VIRTUAL_SEQ_INCLUDED_

class i3c_sdr_write_read_virtual_seq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_sdr_write_read_virtual_seq)

  uvm_status_e   status;
  uvm_reg_data_t ctrl_val;
  uvm_reg_data_t ctrl_mirror;
  uvm_reg_data_t wdatab_mirror;
  uvm_reg_data_t rdata;


  rand bit [7:0] wdata;
  rand bit [7:0] transfer_len;


  constraint len_c {
    transfer_len == 1;
  }

  function new(string name = "i3c_sdr_write_read_virtual_seq");
    super.new(name);
  endfunction

  task body();

    i3c_target_writeOperationWith8bitsData_seq target_write_seq;
    i3c_target_readOperationWith8bitsData_seq  target_read_seq;

    super.body();

 
    if(!this.randomize()) begin
      `uvm_error(get_type_name(), "Randomization failed, using defaults")
      wdata        = 8'hA5;
      transfer_len = 8'd1;
    end

    `uvm_info(get_type_name(),
      $sformatf("Randomized: wdata=0x%0h len=%0d",
      wdata, transfer_len),
      UVM_LOW)

    `uvm_info(get_type_name(),
      "Starting SDR WRITE followed by READ test",
      UVM_LOW)

 
    fork
      begin
        target_write_seq =
          i3c_target_writeOperationWith8bitsData_seq::type_id::create(
            "target_write_seq");

        target_write_seq.start(p_sequencer.i3c_target_seqr_h[0]);
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
      $sformatf("WDATAB mirrored value = %0h", wdatab_mirror),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.wdatab_inst.mirror(
      status, UVM_NO_CHECK);

  
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(i3c_env_cfg_h.i3c_target_agent_cfg_h[0].targetAddress);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(transfer_len);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b0);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    ctrl_val =
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.get();

    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL value before update = %0h", ctrl_val),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(
      status, .parent(this));

    ctrl_mirror =
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.get_mirrored_value();

    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL mirrored value after update = %0h",
      ctrl_mirror),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(status, UVM_NO_CHECK);

    #5000;

   
    fork
      begin
        target_read_seq =
          i3c_target_readOperationWith8bitsData_seq::type_id::create(
            "target_read_seq");

        target_read_seq.start(p_sequencer.i3c_target_seqr_h[0]);
      end
    join_none;

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(i3c_env_cfg_h.i3c_target_agent_cfg_h[0].targetAddress);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(transfer_len);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(
      status, .parent(this));

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(status, UVM_NO_CHECK);

    #5000;


    i3c_env_cfg_h.regBlockHandle.rdatab_inst.read(
      status,
      rdata
    );

    `uvm_info("READ_BACK",
      $sformatf("Data from RDATAB = %0h", rdata),
      UVM_MEDIUM)

    `uvm_info(get_type_name(),
      "SDR WRITE followed by READ completed",
      UVM_LOW)

  endtask

endclass

`endif

