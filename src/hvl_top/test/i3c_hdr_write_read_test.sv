`ifndef I3C_HDR_WRITE_READ_TEST_INCLUDED_
`define I3C_HDR_WRITE_READ_TEST_INCLUDED_

// i3c_hdr_write_read_test
// Runs HDR WRITE followed immediately by HDR READ to the same target.
// Scoreboard verifies both transactions.
// Expected scoreboard summary:
//   HDR transactions           : 2
//   HDR write byte pass / fail : N / 0
//   HDR read  byte pass / fail : N / 0

class i3c_hdr_write_read_test extends i3c_base_test;
  `uvm_component_utils(i3c_hdr_write_read_test)

  extern function new(string name = "i3c_hdr_write_read_test",
                      uvm_component parent = null);
  extern virtual task run_phase(uvm_phase phase);
extern virtual function void build_phase(uvm_phase phase);
endclass : i3c_hdr_write_read_test


function i3c_hdr_write_read_test::new(
  string name = "i3c_hdr_write_read_test",
  uvm_component parent = null);
  super.new(name, parent);
endfunction : new



function void i3c_hdr_write_read_test::build_phase(uvm_phase phase);
      super.build_phase(phase);
        i3c_env_cfg_h.i3c_target_agent_cfg_h[0].has_daa = 1;
    endfunction : build_phase


task i3c_hdr_write_read_test::run_phase(uvm_phase phase);
  i3c_hdr_write_read_virtual_seq hdr_wr_rd_vseq;
 i3c_daa_virtual_seq            daaSeq;  

  phase.raise_objection(this);

  `uvm_info(get_type_name(),
    "Starting HDR Write+Read test", UVM_LOW)
 daaSeq = i3c_daa_virtual_seq::type_id::create("daaSeq");
    daaSeq.i3c_env_cfg_h = i3c_env_cfg_h;
    daaSeq.start(i3c_env_h.top_virtual_seqr_h);

i3c_env_cfg_h.i3c_target_agent_cfg_h[0].has_daa = 0;



 `uvm_info(get_type_name(),
      "DAA done - updating target address to dynamic 0x08",
      UVM_LOW)

  hdr_wr_rd_vseq =
    i3c_hdr_write_read_virtual_seq::type_id::create("hdr_wr_rd_vseq");
  hdr_wr_rd_vseq.start(i3c_env_h.top_virtual_seqr_h);







  phase.drop_objection(this);
endtask : run_phase

`endif


