class i3c_write_read_write_read_8b_test extends i3c_base_test;
  `uvm_component_utils(i3c_write_read_write_read_8b_test)

  i3c_sdr_write_read_write_read_virtual_seq  sdrWriteReadWriteReadSeq;
 
  function new(string name="i3c_write_read_write_read_8b_test.s", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(),
              "Starting ONLY SDR WRITE Read write read sequence",
              UVM_LOW)

    sdrWriteReadWriteReadSeq   = i3c_sdr_write_read_write_read_virtual_seq::type_id::create("sdrWriteReadWriteReadSeq");
    
    sdrWriteReadWriteReadSeq.i3c_env_cfg_h   = i3c_env_cfg_h;

    sdrWriteReadWriteReadSeq.start(i3c_env_h.top_virtual_seqr_h);

    #50us;
    phase.drop_objection(this);

  endtask

endclass
