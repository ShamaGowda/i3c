
`ifndef I3C_TARGET_DAA_SEQ_INCLUDED_
`define I3C_TARGET_DAA_SEQ_INCLUDED_

class i3c_target_daa_seq extends i3c_target_base_seq;
  `uvm_object_utils(i3c_target_daa_seq)

  // -----------------------------------------------------------------------
  // Fixed identity fields – set by the virtual sequence BEFORE calling
  // start() so every round uses the same PID/BCR/DCR from agent config.
  // -----------------------------------------------------------------------
  bit [47:0] cfg_pid = 48'h0;
  bit [7:0]  cfg_bcr = 8'h0;
  bit [7:0]  cfg_dcr = 8'h0;

  extern function new(string name = "i3c_target_daa_seq");
  extern task body();

endclass : i3c_target_daa_seq


function i3c_target_daa_seq::new(string name = "i3c_target_daa_seq");
  super.new(name);
endfunction : new


task i3c_target_daa_seq::body();

  bit address_assigned;
  int round;

  address_assigned = 0;
  round            = 0;

  `uvm_info(get_type_name(),
    "Multi-slave DAA sequence start",
    UVM_LOW)

  while (!address_assigned) begin

    round++;
    req = i3c_target_tx::type_id::create($sformatf("req_daa_r%0d", round));
    start_item(req);

    // ------------------------------------------------------------------
    // Constrain to the FIXED PID/BCR/DCR from the agent configuration.
    // Never randomize PID/BCR/DCR – they are the device's hardware
    // identity and must be stable across all arbitration rounds so that
    // open-drain bit-by-bit comparison is deterministic.
    // ------------------------------------------------------------------
    if (!req.randomize() with {
      txn_type == i3c_target_tx::DAA;
      pid      == cfg_pid;
      bcr      == cfg_bcr;
      dcr      == cfg_dcr;
    }) begin
      `uvm_error(get_type_name(),
        $sformatf("Randomization failed on DAA round %0d", round))
    end else begin
      `uvm_info(get_type_name(),
        $sformatf("[round %0d] PID=0x%0x BCR=0x%0x DCR=0x%0x",
                  round, req.pid, req.bcr, req.dcr), UVM_LOW)
    end

    finish_item(req);

    // After finish_item() the driver proxy has called drive_daa_data()
    // and updated req.daa_ack / req.dynamic_address.
    if (req.daa_ack == ACK) begin
      address_assigned = 1;
      `uvm_info(get_type_name(),
        $sformatf("Address assigned after round %0d: dynamic_addr=0x%0h",
                  round, req.dynamic_address), UVM_LOW)
    end else begin
      `uvm_info(get_type_name(),
        $sformatf("[round %0d] Did not win arbitration ", round), UVM_LOW)
    end

  end // while

  `uvm_info(get_type_name(),
    $sformatf("DAA sequence complete after %0d round(s). Dynamic addr = 0x%0h",
              round, req.dynamic_address), UVM_LOW)

endtask : body

`endif

