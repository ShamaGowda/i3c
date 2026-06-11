class i3c_random_rw_virtual_seq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_random_rw_virtual_seq)

  uvm_status_e status;
  uvm_reg_data_t rdata;

  bit [7:0] data;
  bit dir;

  function new(string name="i3c_random_rw_virtual_seq");
    super.new(name);
  endfunction


  task body();

    i3c_target_writeOperationWith8bitsData_seq target_wr_seq;
    i3c_target_readOperationWith8bitsData_seq  target_rd_seq;

    super.body();

    fork
      forever begin
        target_wr_seq =
          i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_wr_seq");
        target_wr_seq.start(p_sequencer.i3c_target_seqr_h[0]);
      end

      forever begin
        target_rd_seq =
          i3c_target_readOperationWith8bitsData_seq::type_id::create("target_rd_seq");
        target_rd_seq.start(p_sequencer.i3c_target_seqr_h[0]);
      end
    join_none;


    repeat(20) begin

      dir  = $urandom_range(0,1);
      data = $urandom_range(0,255);

      if(dir == 0) begin

        i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(status, data);

        i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(TARGET0_ADDRESS);
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(8'd1);
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b0);
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'd0);
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);

      end

      else begin

        i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(TARGET0_ADDRESS);
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(8'd1);
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b1);
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'd0);
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);
        i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);

      end


      #5000;


      if(dir == 1) begin

        i3c_env_cfg_h.regBlockHandle.rdatab_inst.read(status, rdata);

        `uvm_info(
          "RANDOM_READ",
          $sformatf("Random read data = %0h", rdata),
          UVM_MEDIUM
        )

      end

    end

  endtask

endclass
