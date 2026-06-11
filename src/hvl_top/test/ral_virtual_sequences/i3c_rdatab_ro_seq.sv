`ifndef I3C_RDATAB_RO_SEQ_INCLUDED_
`define I3C_RDATAB_RO_SEQ_INCLUDED_

class i3c_rdatab_ro_seq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_rdatab_ro_seq)

  uvm_status_e status;
  uvm_reg_data_t rdata_before, rdata_after;

  function new(string name="i3c_rdatab_ro_seq");
    super.new(name);
  endfunction


  task body();

    i3c_target_writeOperationWith8bitsData_seq target_seq_write;

    super.body();
    
`uvm_info(get_type_name(), "Starting RDATAB RO test", UVM_LOW)


    // Start target
    fork
      forever begin
        target_seq_write =
          i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_seq_write");
        target_seq_write.start(p_sequencer.i3c_target_seqr_h[0]);
      end
    join_none;


    // Read before write attempt
    i3c_env_cfg_h.regBlockHandle.rdatab_inst.read(status, rdata_before);


    // Try writing to RO register
    i3c_env_cfg_h.regBlockHandle.rdatab_inst.write(
      status,
      8'hFF,
      .parent(this)
    );


    // Read after write
    i3c_env_cfg_h.regBlockHandle.rdatab_inst.read(status, rdata_after);


    // Check RO behavior
    if(rdata_before == rdata_after)
      `uvm_info(get_type_name(),"Register is read-only as expected",UVM_LOW)
    else
      `uvm_error(get_type_name(),"RDATAB changed after write")


    // Mirror check
    i3c_env_cfg_h.regBlockHandle.rdatab_inst.mirror(status, UVM_CHECK);

  endtask

endclass

`endif

