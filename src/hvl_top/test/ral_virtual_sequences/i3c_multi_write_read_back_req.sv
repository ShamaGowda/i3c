`ifndef I3C_MULTI_WRITE_READ_BACK_SEQ_INCLUDED_
`define I3C_MULTI_WRITE_READ_BACK_SEQ_INCLUDED_

class i3c_multi_write_read_back_seq extends top_virtual_base_seq;
  `uvm_object_utils(i3c_multi_write_read_back_seq)

  uvm_status_e   status;
  uvm_reg_data_t rdata;
  uvm_reg_data_t mirror_val;

  bit [7:0] tx_data[3] = '{8'h11, 8'h22, 8'h33};
  bit [7:0] rx_data[3];

  function new(string name = "i3c_multi_write_read_back_seq");
    super.new(name);
  endfunction

  task body();
    i3c_target_writeOperationWith8bitsData_seq multi_wr_target_seq;
    i3c_target_readOperationWith8bitsData_seq  multi_rd_target_seq;

    super.body();

    if(i3c_env_cfg_h == null)
      `uvm_fatal("CFG_NULL", "i3c_env_cfg_h is NULL")

    `uvm_info(get_type_name(),
      "Starting 24-bit WRITE READ BACK test", UVM_LOW)

    fork
      begin
        multi_wr_target_seq =
          i3c_target_writeOperationWith8bitsData_seq::type_id::create(
            "multi_wr_target_seq");
        multi_wr_target_seq.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none

    foreach(tx_data[i]) begin
      i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(
        status, tx_data[i], .parent(this));

      mirror_val =
        i3c_env_cfg_h.regBlockHandle.wdatab_inst.get_mirrored_value();
      `uvm_info("WDATAB_DEBUG",
        $sformatf("Mirror after write[%0d] = 0x%0h", i, mirror_val),
        UVM_LOW)
    end

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.address.set(
      i3c_env_cfg_h.i3c_target_agent_cfg_h[0].targetAddress);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.length.set(8'd3);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.direction.set(1'b0);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status, .parent(this));

    `uvm_info(get_type_name(), "3-byte write triggered", UVM_LOW)

    #10us;

    multi_rd_target_seq = i3c_target_readOperationWith8bitsData_seq::
                          type_id::create("multi_rd_target_seq");
    multi_rd_target_seq.num_bytes = 3;

    fork
      begin
        multi_rd_target_seq.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.address.set(
      i3c_env_cfg_h.i3c_target_agent_cfg_h[0].targetAddress);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.length.set(8'd3);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.direction.set(1'b1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status, .parent(this));

    `uvm_info(get_type_name(), "3-byte read triggered", UVM_LOW)

    #10us;

    foreach(rx_data[i]) begin
      i3c_env_cfg_h.regBlockHandle.rdatab_inst.read(
        status, rdata, .parent(this));
      rx_data[i] = rdata[7:0];
      `uvm_info("READ_BACK",
        $sformatf("RDATAB[%0d] = 0x%0h", i, rx_data[i]), UVM_LOW)
    end

    foreach(tx_data[i]) begin
      if(rx_data[i] == tx_data[i])
        `uvm_info("MULTI_RW_MATCH",
          $sformatf("Match  [%0d]: expected=0x%0h got=0x%0h",
                    i, tx_data[i], rx_data[i]), UVM_LOW)
      else
        `uvm_error("MULTI_RW_MISMATCH",
          $sformatf("Mismatch[%0d]: expected=0x%0h got=0x%0h",
                    i, tx_data[i], rx_data[i]))
    end

    `uvm_info(get_type_name(),
      "24-bit WRITE READ BACK complete", UVM_LOW)

  endtask : body

endclass : i3c_multi_write_read_back_seq

`endif
