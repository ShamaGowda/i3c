`ifndef I3C_SDR_MULTI_WRITE_READ_VIRTUAL_SEQ_INCLUDED_
`define I3C_SDR_MULTI_WRITE_READ_VIRTUAL_SEQ_INCLUDED_

class i3c_sdr_multi_write_read_virtual_seq extends top_virtual_base_seq;
  `uvm_object_utils(i3c_sdr_multi_write_read_virtual_seq)

  uvm_status_e   status;
  uvm_reg_data_t rdata;

 
  rand bit [7:0]    wdata_q[];
  rand int unsigned transfer_len;


  constraint len_c {
    transfer_len inside {[1:16]};
  }

  constraint size_c {
    wdata_q.size() == transfer_len;
  }

  constraint data_c {
    foreach(wdata_q[i]) {
      wdata_q[i] != 8'h00;
      wdata_q[i] != 8'hFF;
    }
  }

  function new(string name = "i3c_sdr_multi_write_read_virtual_seq");
    super.new(name);
  endfunction

  task body();
    i3c_target_writeOperationWith8bitsData_seq target_write_seq;
    i3c_target_readOperationWith8bitsData_seq  target_read_seq;

    super.body();

    if(!this.randomize())
      `uvm_fatal(get_type_name(), "Randomization failed")

    `uvm_info(get_type_name(),
      $sformatf("Len=%0d Data=%p", transfer_len, wdata_q), UVM_LOW)


    foreach(wdata_q[i]) begin
      i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(
        status, wdata_q[i], .parent(this));
    end

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(TARGET0_ADDRESS);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(transfer_len);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b0);  
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status, .parent(this));

    
    fork
      begin
        target_write_seq =
          i3c_target_writeOperationWith8bitsData_seq::type_id::create(
            "target_write_seq");
        target_write_seq.start(p_sequencer.i3c_target_seqr_h[0]);
      end
    join_none

    #5000;

     i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(TARGET0_ADDRESS);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(transfer_len);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b1);  
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status, .parent(this));

  
    fork
      begin
        target_read_seq =
          i3c_target_readOperationWith8bitsData_seq::type_id::create(
            "target_read_seq");
        target_read_seq.start(p_sequencer.i3c_target_seqr_h[0]);
      end
    join_none

  
    #5000;

    
    for(int i = 0; i < transfer_len; i++) begin
      i3c_env_cfg_h.regBlockHandle.rdatab_inst.read(
        status, rdata, .parent(this));

      `uvm_info("READ_BACK",
        $sformatf("[%0d] RDATAB = 0x%0h", i, rdata), UVM_LOW)

      if(rdata !== wdata_q[i])
        `uvm_error("DATA_MISMATCH",
          $sformatf("Index %0d: expected=0x%0h got=0x%0h",
                    i, wdata_q[i], rdata))
      else
        `uvm_info("DATA_MATCH",
          $sformatf("Index %0d: data=0x%0h ✓", i, rdata), UVM_LOW)
    end

  endtask

endclass

`endif

