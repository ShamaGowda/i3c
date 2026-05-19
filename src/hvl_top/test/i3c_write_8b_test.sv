class i3c_write_8b_test extends i3c_base_test;
  `uvm_component_utils(i3c_write_8b_test)

  i3c_sdr_write_virtual_seq        sdrWriteSeq;

  // i3c_sdr_read_virtual_seq      sdrReadSeq;
  // i3c_rdatab_ro_seq             sdrRdatabSeq;
//   i3c_sdr_write_read_virtual_seq  sdrWriteReadSeq;
  // i3c_sdr_write_read_write_read_virtual_seq  sdrWriteReadWriteReadSeq;
  // i3c_verify_pos_ack_seq        posAckSeq;
  // i3c_verify_neg_ack_seq        negAckSeq;
  // i3c_verify_repeated_start_seq repeatedStartSeq;
  // i3c_start_stop_combination_seq startStopSeq;
  // i3c_randomDataTransferWidth_vseq randomWidthSeq;


  function new(string name="i3c_write_8b_test.s", uvm_component parent=null);
    super.new(name, parent);
  endfunction


  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    `uvm_info(get_type_name(),
              "Starting ONLY SDR WRITE sequence",
              UVM_LOW)


    sdrWriteSeq = i3c_sdr_write_virtual_seq::type_id::create("sdrWriteSeq");


    // sdrReadSeq        = i3c_sdr_read_virtual_seq::type_id::create("sdrReadSeq");
    // sdrRdatabSeq      = i3c_rdatab_ro_seq::type_id::create("sdrRdatabSeq");
  //   sdrWriteReadSeq   = i3c_sdr_write_read_virtual_seq::type_id::create("sdrWriteReadSeq");
    // sdrWriteReadWriteReadSeq =
    // i3c_sdr_write_read_write_read_virtual_seq::type_id::create("sdrWriteReadWriteReadSeq");

    // posAckSeq         = i3c_verify_pos_ack_seq::type_id::create("posAckSeq");
    // negAckSeq         = i3c_verify_neg_ack_seq::type_id::create("negAckSeq");
    // repeatedStartSeq  = i3c_verify_repeated_start_seq::type_id::create("repeatedStartSeq");
    // startStopSeq      = i3c_start_stop_combination_seq::type_id::create("startStopSeq");
    // randomWidthSeq    = i3c_randomDataTransferWidth_vseq::type_id::create("randomWidthSeq");



    sdrWriteSeq.i3c_env_cfg_h = i3c_env_cfg_h;


    // sdrReadSeq.i3c_env_cfg_h        = i3c_env_cfg_h;
    // sdrRdatabSeq.i3c_env_cfg_h      = i3c_env_cfg_h;
    // sdrWriteReadSeq.i3c_env_cfg_h   = i3c_env_cfg_h;
    // sdrWriteReadWriteReadSeq.i3c_env_cfg_h = i3c_env_cfg_h;
    // posAckSeq.i3c_env_cfg_h         = i3c_env_cfg_h;
    // negAckSeq.i3c_env_cfg_h         = i3c_env_cfg_h;
    // repeatedStartSeq.i3c_env_cfg_h  = i3c_env_cfg_h;
    // startStopSeq.i3c_env_cfg_h      = i3c_env_cfg_h;
    // randomWidthSeq.i3c_env_cfg_h    = i3c_env_cfg_h;



    sdrWriteSeq.start(i3c_env_h.top_virtual_seqr_h);


    // sdrReadSeq.start(i3c_env_h.top_virtual_seqr_h);
    // sdrRdatabSeq.start(i3c_env_h.top_virtual_seqr_h);
    // sdrWriteReadSeq.start(i3c_env_h.top_virtual_seqr_h);
    // sdrWriteReadWriteReadSeq.start(i3c_env_h.top_virtual_seqr_h);
    // posAckSeq.start(i3c_env_h.top_virtual_seqr_h);
    // negAckSeq.start(i3c_env_h.top_virtual_seqr_h);
    // repeatedStartSeq.start(i3c_env_h.top_virtual_seqr_h);
    // startStopSeq.start(i3c_env_h.top_virtual_seqr_h);
    // randomWidthSeq.start(i3c_env_h.top_virtual_seqr_h);

#50us;
    phase.drop_objection(this);

  endtask

endclass

