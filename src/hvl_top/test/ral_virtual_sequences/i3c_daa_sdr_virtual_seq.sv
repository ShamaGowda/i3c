class i3c_daa_sdr_virtual_seq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_daa_sdr_virtual_seq)

  uvm_status_e    status;
  uvm_reg_data_t  rdata;

  bit [7:0] write_data = 8'h55;
  bit [7:0] read_data;

  function new(string name="i3c_daa_sdr_virtual_seq");
    super.new(name);
  endfunction


  task body();

    i3c_target_writeOperationWith8bitsData_seq target_wr_seq;
    i3c_target_readOperationWith8bitsData_seq  target_rd_seq;

    super.body();


    fork
      forever begin
        target_wr_seq =
        i3c_target_writeOperationWith8bitsData_seq::
        type_id::create("target_wr_seq");

        target_wr_seq.start(p_sequencer.i3c_target_seqr_h);
      end

      forever begin
        target_rd_seq =
        i3c_target_readOperationWith8bitsData_seq::
        type_id::create("target_rd_seq");

        target_rd_seq.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none;



    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'd2);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.ccc.set(`CCC_ENTDAA);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);


    #5000;

    `uvm_info("DAA_CHECK",
      "ENTDAA command issued successfully",
      UVM_MEDIUM)


    i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(
      status,
      write_data
    );

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.address.set(
      TARGET0_ADDRESS
    );

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.length.set(8'd1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.direction.set(1'b0);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'd0);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);


    #5000;



    i3c_env_cfg_h.regBlockHandle.ctrl_inst.address.set(
      TARGET0_ADDRESS
    );

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.length.set(8'd1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.direction.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'd0);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);


    #5000;



    i3c_env_cfg_h.regBlockHandle.rdatab_inst.read(
      status,
      rdata
    );

    read_data = rdata;

    if(read_data == write_data)

      `uvm_info(
        "SDR_DATA_CHECK",
        $sformatf(
          "PASS: write %0h read %0h",
          write_data,
          read_data
        ),
        UVM_MEDIUM
      )

    else

      `uvm_error(
        "SDR_DATA_CHECK",
        $sformatf(
          "FAIL: write %0h read %0h",
          write_data,
          read_data
        )
      )

  endtask

endclass
