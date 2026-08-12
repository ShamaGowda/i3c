`ifndef I3C_HDR_WRITE_VIRTUAL_SEQ_LEN_17_INCLUDED_
`define I3C_HDR_WRITE_VIRTUAL_SEQ_LEN_17_INCLUDED_

class i3c_hdr_write_virtual_seq_len_17 extends top_virtual_base_seq;
  `uvm_object_utils(i3c_hdr_write_virtual_seq_len_17)

  uvm_status_e   status;
  uvm_reg_data_t ctrl_val;
  uvm_reg_data_t ctrl_mirror;

  int unsigned target_idx = 0;

  rand bit [7:0] wdata_bytes[0:16];

  rand int unsigned transfer_len;
  constraint len_c {
    transfer_len == 17;
  }

  constraint wdata_val_c {
    foreach (wdata_bytes[i]) {
      wdata_bytes[i] inside {[8'h01:8'hFF]};
    }
  }

  function new(string name = "i3c_hdr_write_virtual_seq_len_17");
    super.new(name);
  endfunction

  task body();
    i3c_target_hdr_write_seq target_seq_write;

    if (i3c_env_cfg_h == null)
      `uvm_fatal("CFG_NULL",
        "i3c_env_cfg_h is NULL inside i3c_hdr_write_virtual_seq")
    if (i3c_env_cfg_h.regBlockHandle == null)
      `uvm_fatal("RAL_NULL",
        "regBlockHandle is NULL inside i3c_hdr_write_virtual_seq")

    super.body();

    if (!this.randomize()) begin
      `uvm_error(get_type_name(), "Randomization failed - using defaults")
      transfer_len    = 2;
      wdata_bytes[0]  = 8'h44;
      wdata_bytes[1]  = 8'hBE;
    end

    $display("========================================================");
    $display("  RANDOMIZED VALUES for %s", get_type_name());
    $display("  transfer_len = %0d", transfer_len);
    for (int i = 0; i < transfer_len; i++)
      $display("  wdata_bytes[%0d] = 8'h%02x (%0d)", i, wdata_bytes[i], wdata_bytes[i]);
    $display("========================================================");

    `uvm_info(get_type_name(),
      $sformatf("HDR WRITE to target[%0d] addr=0x%0h len=%0d bytes",
                target_idx,
                i3c_env_cfg_h.i3c_target_agent_cfg_h[target_idx].targetAddress,
                transfer_len),
      UVM_LOW)

    for (int i = 0; i < transfer_len; i++)
      `uvm_info(get_type_name(),
        $sformatf("  planned payload[%0d] = 0x%02h", i, wdata_bytes[i]),
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

    for (int i = 0; i < transfer_len; i++) begin
      `uvm_info(get_type_name(),
        $sformatf("Pushing WDATAB[%0d] = 0x%02h to RTL FIFO", i, wdata_bytes[i]),
        UVM_LOW)

      i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(
        status, uvm_reg_data_t'(wdata_bytes[i]),
        UVM_FRONTDOOR, .parent(this));

      if (status != UVM_IS_OK)
        `uvm_error(get_type_name(),
          $sformatf("WDATAB write[%0d]=0x%02h failed status=%s",
                    i, wdata_bytes[i], status.name()))
      else
        `uvm_info(get_type_name(),
          $sformatf("WDATAB[%0d] write OK", i), UVM_LOW)
    end

    `uvm_info(get_type_name(),
      $sformatf("All %0d bytes loaded into WDATAB FIFO", transfer_len),
      UVM_LOW)

    // ------------------------------------------------------------------
    // Step 3: program CTRL to kick off the HDR WRITE transaction
    // ------------------------------------------------------------------
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(
      i3c_env_cfg_h.i3c_target_agent_cfg_h[target_idx].targetAddress);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(transfer_len);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b0);   // WRITE
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'd0);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_ccc.set(8'd0);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_mode.set(1'b1);  // HDR
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    ctrl_val = i3c_env_cfg_h.regBlockHandle.ctrl_inst.get();
    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL before HDR write = 0x%0h  addr=0x%0h len=%0d",
                ctrl_val,
                i3c_env_cfg_h.i3c_target_agent_cfg_h[target_idx].targetAddress,
                transfer_len),
      UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status, .parent(this));

    ctrl_mirror =
      i3c_env_cfg_h.regBlockHandle.ctrl_inst.get_mirrored_value();
    `uvm_info("CTRL_DEBUG",
      $sformatf("CTRL mirrored after write = 0x%0h", ctrl_mirror), UVM_LOW)

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(status, UVM_NO_CHECK);

    // ------------------------------------------------------------------
    // Step 4: wait for transaction to complete
    // ------------------------------------------------------------------
    #(5000 * (transfer_len + 2));

    i3c_env_cfg_h.i3c_target_agent_cfg_h[target_idx].hdr_mode = 0;

    `uvm_info(get_type_name(),
      $sformatf("HDR WRITE to target[%0d] complete (%0d bytes)",
                target_idx, transfer_len),
      UVM_LOW)

  endtask : body

endclass : i3c_hdr_write_virtual_seq_len_17

`endif
