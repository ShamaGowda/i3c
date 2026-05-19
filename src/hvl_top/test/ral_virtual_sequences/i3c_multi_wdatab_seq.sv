class i3c_multi_wdatab_seq extends top_virtual_base_seq;
  `uvm_object_utils(i3c_multi_wdatab_seq )

  uvm_status_e   status;
  uvm_reg_data_t ctrl_val;
  uvm_reg_data_t ctrl_mirror;

 
  rand bit [7:0]  wdata_q[];      
  rand int unsigned transfer_len; 


  constraint len_c {
  transfer_len dist {
    [1:16]   := 70,
    [17:128]  := 30
  };

wdata_q.size() == transfer_len;
  }


  function new(string name = "i3c_multi_wdatab_seq ");
    super.new(name);
  endfunction

  task body();
    i3c_target_writeOperationWith8bitsData_seq target_seq_write;


    if(i3c_env_cfg_h == null)
      `uvm_fatal("CFG_NULL","i3c_env_cfg_h is NULL")
    if(i3c_env_cfg_h.regBlockHandle == null)
      `uvm_fatal("RAL_NULL","regBlockHandle is NULL")
    if(i3c_env_cfg_h.regBlockHandle.wdatab_inst == null)
      `uvm_fatal("WDATAB_NULL","wdatab_inst is NULL")

    super.body();


    if(!this.randomize()) begin
      `uvm_fatal(get_type_name(),"Randomization failed")
    end
  `uvm_info(get_type_name(),
      $sformatf("Len=%0d Data=%p", transfer_len, wdata_q),
      UVM_LOW)

    `uvm_info(get_type_name(),
      "Starting SDR MULTI-BYTE WRITE test",
      UVM_LOW)


    fork
      begin
        target_seq_write =
          i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_seq_write");
        target_seq_write.start(p_sequencer.i3c_target_seqr_h);
      end
    join_none;


    foreach (wdata_q[i]) begin
      i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(
        status,
        wdata_q[i],
        .parent(this)
      );

      `uvm_info("WDATAB_WRITE",
        $sformatf("Wrote byte[%0d] = 0x%0h", i, wdata_q[i]),
        UVM_LOW)
    end

 
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.address.set(
      i3c_env_cfg_h.i3c_target_agent_cfg_h[0].targetAddress);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.length.set(transfer_len);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.direction.set(1'b0);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    ctrl_val =
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.get();

    `uvm_info("CTRL_DEBUG",
 $sformatf("CTRL value before update = 0x%0h", ctrl_val),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(
      status, .parent(this));

    ctrl_mirror =
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.get_mirrored_value();

    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL mirrored value after update = 0x%0h",
      ctrl_mirror),
      UVM_LOW)

    #50us;

    `uvm_info(get_type_name(),
      "SDR MULTI-BYTE WRITE completed",
      UVM_LOW)

  endtask

endclass
