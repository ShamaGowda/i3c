class test extends uvm_test;

  `uvm_component_utils(test)

  i3c_env env;
  i3c_read_write_read_seq seq;

  function new(string name = "test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    env = i3c_env::type_id::create("env", this);
    seq = i3c_read_write_read_seq::type_id::create("seq");

    `uvm_info("TEST", "Build phase executed", UVM_LOW)
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    seq.start(env.apb_master_agent_h.apb_master_seqr_h);

    phase.drop_objection(this);
  endtask

endclass
