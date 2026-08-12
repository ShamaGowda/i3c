`ifndef I3C_HDR_WRITE_EMPTY_FIFO_MINIMAL_SEQ_INCLUDED_
`define I3C_HDR_WRITE_EMPTY_FIFO_MINIMAL_SEQ_INCLUDED_

class i3c_hdr_write_empty_fifo_seq extends top_virtual_base_seq;
  `uvm_object_utils(i3c_hdr_write_empty_fifo_seq)

  uvm_status_e   status;
  int unsigned   target_idx = 0;
  bit [7:0]      transfer_len = 4;

  function new(string name = "i3c_hdr_write_empty_fifo_seq");
    super.new(name);
  endfunction

  task body();
    i3c_target_hdr_write_seq target_seq_write;

    super.body();

    `uvm_info(get_type_name(),
      $sformatf("Initiating HDR WRITE with EMPTY TX FIFO, target[%0d] addr=0x%0h len=%0d, no WDATAB writes",
                target_idx,
                i3c_env_cfg_h.i3c_target_agent_cfg_h[target_idx].targetAddress,
                transfer_len),
      UVM_LOW)

    i3c_env_cfg_h.i3c_target_agent_cfg_h[target_idx].hdr_mode = 1;

    fork
      begin
        target_seq_write =
          i3c_target_hdr_write_seq::type_id::create("target_seq_write");
        target_seq_write.start(
          p_sequencer.i3c_target_seqr_h[target_idx]);
      end
    join_none

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(
      i3c_env_cfg_h.i3c_target_agent_cfg_h[target_idx].targetAddress);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(transfer_len);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b0);   // WRITE
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'd0);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_mode.set(1'b1);  // HDR
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status, .parent(this));

    #(5000 * (transfer_len + 2));

    i3c_env_cfg_h.i3c_target_agent_cfg_h[target_idx].hdr_mode = 0;

    `uvm_info(get_type_name(),
      "HDR WRITE (empty FIFO) transaction attempt complete", UVM_LOW)

  endtask : body

endclass : i3c_hdr_write_empty_fifo_seq

`endif
