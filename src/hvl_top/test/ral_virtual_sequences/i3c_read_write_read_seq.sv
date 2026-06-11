class i3c_read_write_read_seq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_read_write_read_seq)

  uvm_status_e status;
  uvm_reg_data_t rdata;
  uvm_reg_data_t mirror_val;

  bit [7:0] write_data = 8'h55;
  bit [7:0] read_before;
  bit [7:0] read_after;

  function new(string name="i3c_read_write_read_seq");
    super.new(name);
  endfunction


  task body();

    i3c_target_writeOperationWith8bitsData_seq rwr_target_wr_seq;
    i3c_target_readOperationWith8bitsData_seq  rwr_target_rd_seq;

    super.body();

    `uvm_info(get_type_name(),
      "Starting READ WRITE READ test",
      UVM_LOW)


    fork
      forever begin
        rwr_target_wr_seq =
          i3c_target_writeOperationWith8bitsData_seq::type_id::create(
            "rwr_target_wr_seq");

        rwr_target_wr_seq.start(p_sequencer.i3c_target_seqr_h[0]);
      end

      forever begin
        rwr_target_rd_seq =
          i3c_target_readOperationWith8bitsData_seq::type_id::create(
            "rwr_target_rd_seq");

        rwr_target_rd_seq.start(p_sequencer.i3c_target_seqr_h[0]);
      end
    join_none;


    // FIRST READ

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(7'h68);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(8'd1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'd0);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(status, UVM_CHECK);


    #5000;


    i3c_env_cfg_h.regBlockHandle.rdatab_inst.read(status, rdata);

    read_before = rdata;

    i3c_env_cfg_h.regBlockHandle.rdatab_inst.mirror(status, UVM_NO_CHECK);


    // WRITE

    i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(status, write_data);

    mirror_val =
      i3c_env_cfg_h.regBlockHandle.wdatab_inst.get_mirrored_value();

    `uvm_info("WDATAB_DEBUG",
      $sformatf("Mirror after write = %0h", mirror_val),
      UVM_LOW)


    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(7'h68);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b0);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(status, UVM_CHECK);


    #5000;


    // SECOND READ

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(7'h68);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(status, UVM_CHECK);


    #5000;


    i3c_env_cfg_h.regBlockHandle.rdatab_inst.read(status, rdata);

    read_after = rdata;

    i3c_env_cfg_h.regBlockHandle.rdatab_inst.mirror(status, UVM_NO_CHECK);


    // CHECK RESULT

    if(read_after == write_data)
      `uvm_info("RWR_CHECK",
        $sformatf("PASS: Written value %0h matches read value %0h",
          write_data, read_after),
        UVM_MEDIUM)
    else
      `uvm_error("RWR_CHECK",
        $sformatf("FAIL: Written value %0h does not match read value %0h",
          write_data, read_after))


    `uvm_info("RWR_RESULT",
      $sformatf("First Read = %0h Second Read = %0h",
        read_before, read_after),
      UVM_MEDIUM)

  endtask

endclass
