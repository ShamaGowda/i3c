class i3c_read_8b_test extends i3c_base_test;
  `uvm_component_utils(i3c_read_8b_test)


  i3c_sdr_read_virtual_seq sdrReadSeq;

  function new(string name="i3c_read_8b_test.s", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(),
              "Starting ONLY SDR READ sequence",
              UVM_LOW)

    sdrReadSeq = i3c_sdr_read_virtual_seq::type_id::create("sdrReadSeq");
    
    sdrReadSeq.i3c_env_cfg_h = i3c_env_cfg_h;

    sdrReadSeq.start(i3c_env_h.top_virtual_seqr_h);

    #50us;
    phase.drop_objection(this);

  endtask

endclass

