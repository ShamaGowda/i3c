class i3c_invalid_addr_write_test extends i3c_base_test;
  `uvm_component_utils(i3c_invalid_addr_write_test)

  i3c_invalid_addr_write_virtual_seq invalidaddrwrite;
 
  function new(string name="i3c_invalid_addr_write_test", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(),
              "Starting ONLY i3c_invalid_addr_write_test",
              UVM_LOW)

    invalidaddrwrite = i3c_invalid_addr_write_virtual_seq::type_id::create("invalidaddrwrite");
    
    invalidaddrwrite.i3c_env_cfg_h = i3c_env_cfg_h;

    invalidaddrwrite.start(i3c_env_h.top_virtual_seqr_h);

    #50us;
    phase.drop_objection(this);

  endtask

endclass

