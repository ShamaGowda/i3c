`ifndef I3C_CCC_COVERAGE_TEST_INCLUDED_
`define I3C_CCC_COVERAGE_TEST_INCLUDED_

class i3c_ccc_coverage_test extends i3c_base_test;
  `uvm_component_utils(i3c_ccc_coverage_test)

  i3c_ccc_coverage_virtual_seq cccCovSeq;

  function new(string name = "i3c_ccc_coverage_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(),
      "Starting CCC coverage test", UVM_LOW)

    cccCovSeq =
      i3c_ccc_coverage_virtual_seq::type_id::create("cccCovSeq");
    cccCovSeq.i3c_env_cfg_h = i3c_env_cfg_h;
    cccCovSeq.start(i3c_env_h.top_virtual_seqr_h);

    #50us;
    phase.drop_objection(this);
  endtask

endclass
`endif
