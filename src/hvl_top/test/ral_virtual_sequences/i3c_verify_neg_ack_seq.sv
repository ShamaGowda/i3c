`ifndef I3C_VERIFY_NEG_ACK_SEQ_INCLUDED_
`define I3C_VERIFY_NEG_ACK_SEQ_INCLUDED_

class i3c_verify_neg_ack_seq extends top_virtual_base_seq;

  `uvm_object_utils(i3c_verify_neg_ack_seq)

  uvm_status_e status;
  uvm_reg_data_t wdatab_mirror;

  function new(string name = "i3c_verify_neg_ack_seq");
    super.new(name);
  endfunction


  task body();

    i3c_target_writeOperationWith8bitsData_seq target_seq;

    super.body();

    `uvm_info(get_type_name(),
      "Starting Negative ACK verification",
      UVM_LOW)


    fork
      forever begin
        target_seq =
          i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_seq");

        target_seq.start(p_sequencer.i3c_target_seqr_h[0]);
      end
    join_none;


    i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(status, 8'hA5);

    wdatab_mirror =
      i3c_env_cfg_h.regBlockHandle.wdatab_inst.get_mirrored_value();

    `uvm_info("WDATAB_DEBUG",
      $sformatf("WDATAB mirrored value = %0h", wdatab_mirror),
      UVM_LOW)


    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(7'h7F); // invalid target
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(8'd1);
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(1'b0); // WRITE
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00); // SDR
    i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

    i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(status);


    #5000;


    `uvm_info(get_type_name(),
      "Negative ACK stimulus issued (invalid address transaction attempted)",
      UVM_MEDIUM)

  endtask

endclass

`endif

