`ifndef I3C_SCOREBOARD_INCLUDED_
`define I3C_SCOREBOARD_INCLUDED_
class i3c_scoreboard extends uvm_component;
  `uvm_component_utils(i3c_scoreboard)
  uvm_tlm_analysis_fifo #(apb_master_tx) apb_analysis_fifo;
  uvm_tlm_analysis_fifo #(i3c_target_tx) target_analysis_fifo[];
  i3c_env_config i3c_env_cfg_h;
  int apb_tx_count;
  int target_tx_count;
  int write_pass;
  int write_fail;
  int read_pass;
  int read_fail;
  // HDR counters
  int hdr_write_pass;
  int hdr_write_fail;
  int hdr_read_pass;
  int hdr_read_fail;
  int daa_addr_pass;
  int daa_addr_fail;
  int daa_parity_pass;
  int daa_parity_fail;
  int daa_devices_seen;
  bit [6:0] exp_address;
  bit [7:0] exp_length;
  bit       exp_direction;
  bit [1:0] exp_cmd_type;
  bit [7:0] exp_ccc;
  bit       exp_mode;      // CTRL[26]: 0=SDR, 1=HDR
  // SDR data queues
  bit [7:0] exp_write_data[$];
  bit [7:0] exp_rd_wr_data[$];
  typedef struct {
    bit         assigned;
    bit [6:0]   dynamic_address;
    bit [47:0]  pid;
    bit [7:0]   bcr;
    bit [7:0]   dcr;
    bit         daa_ack;
  } daa_result_t;
  daa_result_t daa_result[];
  bit [6:0] daa_next_exp_addr;
  extern function new(string name = "i3c_scoreboard",
                      uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual task          run_phase(uvm_phase phase);
  extern virtual function void check_phase(uvm_phase phase);
  // SDR
  extern protected task          collect_apb_transaction();
  extern protected task          compare_with_target();
  extern protected function void decode_ctrl(bit [31:0] ctrl_val);
  // HDR
  extern protected task          compare_with_hdr_target();
  // DAA
  extern protected function bit  is_daa_transaction();
  extern protected task          compare_with_daa_target();
  // helpers
  extern protected function int  find_target_by_address(bit [6:0] addr);
endclass : i3c_scoreboard
function i3c_scoreboard::new(string name = "i3c_scoreboard",
                              uvm_component parent = null);
  super.new(name, parent);
endfunction
function void i3c_scoreboard::build_phase(uvm_phase phase);
  super.build_phase(phase);
  if (!uvm_config_db #(i3c_env_config)::get(
        this, "", "i3c_env_config", i3c_env_cfg_h))
    `uvm_fatal("SB_CFG", "Cannot get i3c_env_config from config_db")
  // APB fifo (single master)
  apb_analysis_fifo = new("apb_analysis_fifo", this);
  // Per-slave target fifos
  target_analysis_fifo =
    new[i3c_env_cfg_h.no_of_targets];
  foreach (target_analysis_fifo[i]) begin
    target_analysis_fifo[i] = new(
      $sformatf("target_analysis_fifo_%0d", i), this);
  end
  // Per-slave DAA result table
  daa_result = new[i3c_env_cfg_h.no_of_targets];
  foreach (daa_result[i]) begin
    daa_result[i].assigned       = 0;
    daa_result[i].dynamic_address = 7'h00;
    daa_result[i].pid             = 48'h0;
    daa_result[i].bcr             = 8'h00;
    daa_result[i].dcr             = 8'h00;
    daa_result[i].daa_ack         = NACK;
  end
  daa_next_exp_addr = DAA_FIRST_DYN_ADDR;
  `uvm_info("SB",
    $sformatf("Scoreboard built for %0d target(s)",
              i3c_env_cfg_h.no_of_targets), UVM_LOW)
endfunction : build_phase
task i3c_scoreboard::run_phase(uvm_phase phase);
  super.run_phase(phase);
  forever begin
    collect_apb_transaction();
    if (is_daa_transaction()) begin
      `uvm_info("SB",
        $sformatf("DAA transaction detected: cmd_type=0x%0x ccc=0x%0x",
                  exp_cmd_type, exp_ccc), UVM_MEDIUM)
      compare_with_daa_target();
    end
    else if (exp_mode) begin
      `uvm_info("SB", "HDR transaction detected", UVM_MEDIUM)
      compare_with_hdr_target();
    end
    else begin
      compare_with_target();
    end
  end
endtask : run_phase
task i3c_scoreboard::collect_apb_transaction();
  apb_master_tx apb_pkt;
  exp_write_data.delete();
  forever begin
    apb_analysis_fifo.get(apb_pkt);
    apb_tx_count++;
    // Accumulate WDATAB writes (addr 0x30)
    if (apb_pkt.pwrite == apb_global_pkg::WRITE &&
        apb_pkt.paddr[6:0] == 7'h30) begin
      exp_write_data.push_back(apb_pkt.pwdata[7:0]);
      exp_rd_wr_data.push_back(apb_pkt.pwdata[7:0]);
      `uvm_info("SB",
        $sformatf("WDATAB collected = 0x%0x", apb_pkt.pwdata[7:0]),
        UVM_HIGH)
    end
    // CTRL write with start bit set (addr 0x0C, bit[31]=1)
    if (apb_pkt.pwrite == apb_global_pkg::WRITE &&
        apb_pkt.paddr[6:0] == 7'h0C &&
        apb_pkt.pwdata[31] == 1'b1) begin
      decode_ctrl(apb_pkt.pwdata);
      `uvm_info("SB", $sformatf(
        "CTRL decoded: addr=0x%0x dir=%0b len=%0d cmd_type=0x%0x ccc=0x%0x mode=%0s",
        exp_address, exp_direction, exp_length,
        exp_cmd_type, exp_ccc, exp_mode ? "HDR" : "SDR"), UVM_MEDIUM)
      break;
    end
  end
endtask : collect_apb_transaction
function void i3c_scoreboard::decode_ctrl(bit [31:0] ctrl_val);
  exp_address   = ctrl_val[6:0];
  exp_length    = ctrl_val[14:7];
  exp_direction = ctrl_val[15];
  exp_ccc       = ctrl_val[23:16];
  exp_cmd_type  = ctrl_val[25:24];
  exp_mode      = ctrl_val[26];   // 0=SDR, 1=HDR
endfunction : decode_ctrl
function bit i3c_scoreboard::is_daa_transaction();
  if (exp_cmd_type == CMD_TYPE_DAA)
    return 1;
  if (exp_cmd_type == CMD_TYPE_CCC && exp_ccc == ENTDAA_CCC_CODE)
    return 1;
  return 0;
endfunction : is_daa_transaction
task i3c_scoreboard::compare_with_daa_target();
  i3c_target_tx tgt;
  bit [6:0]     exp_dyn_addr;
  int           num_targets;
  int           targets_processed;
  num_targets        = i3c_env_cfg_h.no_of_targets;
  targets_processed  = 0;
  if (exp_cmd_type == CMD_TYPE_CCC) begin
    if (exp_ccc == ENTDAA_CCC_CODE)
      `uvm_info("SB_DAA_CTRL_CCC",
        "CTRL CCC = 0x07 (ENTDAA) PASS", UVM_MEDIUM)
    else
      `uvm_error("SB_DAA_CTRL_CCC",
        $sformatf("cmd_type=2 but CCC=0x%0h, expected ENTDAA=0x07", exp_ccc))
  end else begin
    `uvm_info("SB_DAA_CTRL_CMD",
      "CTRL cmd_type = 3 (explicit DAA) PASS", UVM_MEDIUM)
  end
  while (targets_processed < num_targets) begin
    for (int i = 0; i < num_targets; i++) begin
      // Skip slots already processed this round
      if (daa_result[i].assigned) continue;
      if (target_analysis_fifo[i].try_get(tgt)) begin
        target_tx_count++;
        daa_devices_seen++;
        targets_processed++;
        `uvm_info("SB_DAA",
          $sformatf("Got DAA result from target[%0d]: PID=0x%0h BCR=0x%0h  DCR=0x%0h dynAddr=0x%0h daa_ack=%0b",
                    i, tgt.pid, tgt.bcr, tgt.dcr,
                    tgt.dynamic_address, tgt.daa_ack), UVM_MEDIUM)
        // -- txn_type check
        if (tgt.txn_type !== i3c_target_tx::DAA) begin
          `uvm_error("SB_DAA_TXN_TYPE",
            $sformatf("[target %0d] Expected DAA txn but got txn_type=%s",
                      i, tgt.txn_type.name()))
        end
        // -- Store result
        daa_result[i].assigned        = 1;
        daa_result[i].dynamic_address = tgt.dynamic_address;
        daa_result[i].pid             = tgt.pid;
        daa_result[i].bcr             = tgt.bcr;
        daa_result[i].dcr             = tgt.dcr;
        daa_result[i].daa_ack         = tgt.daa_ack;
        // -- Parity / ACK check
        if (tgt.daa_ack === ACK) begin
          `uvm_info("SB_DAA_ACK",
            $sformatf("[target %0d] daa_ack=ACK for addr 0x%0h PASS",
                      i, tgt.dynamic_address), UVM_MEDIUM)
          daa_parity_pass++;
          // -- Sequential dynamic address check
          exp_dyn_addr = daa_next_exp_addr;
          daa_next_exp_addr++;   // always advance so later slaves get the right expected address
          if (tgt.dynamic_address !== exp_dyn_addr) begin
            `uvm_error("SB_DAA_DYNADDR",
              $sformatf("[target %0d] Dynamic address: expected 0x%0h got 0x%0h",
                        i, exp_dyn_addr, tgt.dynamic_address))
            daa_addr_fail++;
          end else begin
            `uvm_info("SB_DAA_DYNADDR",
              $sformatf("[target %0d] Dynamic address 0x%0h PASS",
                        i, tgt.dynamic_address), UVM_MEDIUM)
            daa_addr_pass++;
          end
          // -- BCR[7] must be 0 (target device role)
          if (tgt.bcr[7] !== 1'b0)
            `uvm_error("SB_DAA_BCR_ROLE",
              $sformatf("[target %0d] BCR[7] must be 0 but got 1 (PID=0x%0h)",
                        i, tgt.pid))
          else
            `uvm_info("SB_DAA_BCR_ROLE",
              $sformatf("[target %0d] BCR[7]=0 (target role) PASS", i),
              UVM_MEDIUM)
          // -- PID non-zero
          if (tgt.pid === 48'h0)
            `uvm_error("SB_DAA_PID_ZERO",
              $sformatf("[target %0d] PID is zero – invalid", i))
          // -- Cross-check: PID must match what test configured
          if (i3c_env_cfg_h.i3c_target_agent_cfg_h[i].pid !== tgt.pid)
            `uvm_error("SB_DAA_PID_MISMATCH",
              $sformatf("[target %0d] PID: configured=0x%0h received=0x%0h",
                        i,
                        i3c_env_cfg_h.i3c_target_agent_cfg_h[i].pid,
                        tgt.pid))
          else
            `uvm_info("SB_DAA_PID",
              $sformatf("[target %0d] PID 0x%0h matches config PASS", i, tgt.pid),
              UVM_MEDIUM)
          // -- BCR cross-check
          if (i3c_env_cfg_h.i3c_target_agent_cfg_h[i].bcr !== tgt.bcr)
            `uvm_error("SB_DAA_BCR_MISMATCH",
              $sformatf("[target %0d] BCR: configured=0x%0h received=0x%0h",
                        i,
                        i3c_env_cfg_h.i3c_target_agent_cfg_h[i].bcr,
                        tgt.bcr))
          else
            `uvm_info("SB_DAA_BCR",
              $sformatf("[target %0d] BCR 0x%0h PASS", i, tgt.bcr), UVM_MEDIUM)
          // -- DCR cross-check
          if (i3c_env_cfg_h.i3c_target_agent_cfg_h[i].dcr !== tgt.dcr)
            `uvm_error("SB_DAA_DCR_MISMATCH",
              $sformatf("[target %0d] DCR: configured=0x%0h received=0x%0h",
                        i,
                        i3c_env_cfg_h.i3c_target_agent_cfg_h[i].dcr,
                        tgt.dcr))
          else
            `uvm_info("SB_DAA_DCR",
              $sformatf("[target %0d] DCR 0x%0h PASS", i, tgt.dcr), UVM_MEDIUM)
        end else begin
          `uvm_info("SB_DAA_ACK",
            $sformatf("[target %0d] daa_ack=NACK this round (not assigned yet)",
                      i), UVM_MEDIUM)
        end
      end // try_get succeeded
    end // for each target
    // Yield time slice so other processes can push items into fifos
    if (targets_processed < num_targets)
      #1;
  end // while not all processed
  // Reset assigned flags for next ENTDAA command (if test issues multiple)
  foreach (daa_result[i])
    daa_result[i].assigned = 0;
  `uvm_info("SB_DAA",
    $sformatf("DAA round complete: %0d/%0d devices assigned",
              targets_processed, num_targets), UVM_LOW)
endtask : compare_with_daa_target
function int i3c_scoreboard::find_target_by_address(bit [6:0] addr);
  foreach (i3c_env_cfg_h.i3c_target_agent_cfg_h[i]) begin
    if (i3c_env_cfg_h.i3c_target_agent_cfg_h[i].targetAddress == addr)
      return i;
  end
  return -1;
endfunction : find_target_by_address
task i3c_scoreboard::compare_with_target();
  i3c_target_tx tgt;
  int           tgt_idx;
  // Find which slave this SDR transaction was directed to
  tgt_idx = find_target_by_address(exp_address);
  if (tgt_idx < 0) begin
    `uvm_error("SB_SDR_NO_TARGET",
      $sformatf("SDR: Cannot find target for address 0x%0x", exp_address))
    return;
  end
  `uvm_info("SB_SDR",
    $sformatf("SDR: collecting from target_analysis_fifo[%0d] addr=0x%0x",
              tgt_idx, exp_address), UVM_MEDIUM)
  target_analysis_fifo[tgt_idx].get(tgt);
  target_tx_count++;
  `uvm_info("SB", $sformatf("Target[%0d] pkt:\n%s", tgt_idx, tgt.sprint()),
    UVM_HIGH)
  // -- Operation check
  begin
    operationType_e exp_op = (exp_direction == 1'b0) ?
                             i3c_globals_pkg::WRITE :
                             i3c_globals_pkg::READ;
    if (exp_op == tgt.operation)
      `uvm_info("SB_OP_MATCH",
        $sformatf("[target %0d] Operation %s PASS", tgt_idx, exp_op.name()),
        UVM_MEDIUM)
    else
      `uvm_error("SB_OP_MISMATCH",
        $sformatf("[target %0d] Operation: expected %s got %s",
                  tgt_idx, exp_op.name(), tgt.operation.name()))
  end
  // -- WRITE data comparison
  if (exp_direction == 1'b0) begin
    int actual_bytes = tgt.writeData.size();
    `uvm_info("SB",
      $sformatf("[target %0d] Write: APB sent %0d bytes, CTRL length=%0d, target received %0d bytes",
                tgt_idx, exp_write_data.size(), exp_length, actual_bytes),
      UVM_MEDIUM)
    for (int i = 0; i < actual_bytes; i++) begin
      bit [7:0] exp_val;
      exp_val = (i < exp_write_data.size()) ? exp_write_data[i] : 8'hFF;
      if (exp_val == tgt.writeData[i][7:0]) begin
        `uvm_info("SB_WDATA_MATCH",
          $sformatf("[target %0d] writeData[%0d]: expected 0x%0x got 0x%0x PASS",
                    tgt_idx, i, exp_val, tgt.writeData[i][7:0]), UVM_MEDIUM)
        write_pass++;
      end else begin
        `uvm_error("SB_WDATA_MISMATCH",
          $sformatf("[target %0d] writeData[%0d]: expected 0x%0x got 0x%0x FAIL",
                    tgt_idx, i, exp_val, tgt.writeData[i][7:0]))
        write_fail++;
      end
    end
    if (exp_write_data.size() > actual_bytes)
      `uvm_info("SB_FIFO_OVERFLOW",
        $sformatf("[target %0d] APB sent %0d bytes, target got %0d, RTL may have dropped %0d",
                  tgt_idx,
                  exp_write_data.size(), actual_bytes,
                  exp_write_data.size() - actual_bytes), UVM_MEDIUM)
  // -- READ data comparison
  end else begin
    bit [7:0]     apb_read_data[$];
    apb_master_tx rd_pkt;
    int           rd_count = 0;
    while (rd_count < int'(exp_length)) begin
      apb_analysis_fifo.get(rd_pkt);
      apb_tx_count++;
      if (rd_pkt.pwrite == apb_global_pkg::READ &&
          rd_pkt.paddr[6:0] == 7'h40) begin
        apb_read_data.push_back(rd_pkt.prdata[7:0]);
        `uvm_info("SB",
          $sformatf("[target %0d] RDATAB[%0d] = 0x%0x",
                    tgt_idx, rd_count, rd_pkt.prdata[7:0]), UVM_HIGH)
        rd_count++;
      end
    end
    if (apb_read_data.size() != tgt.readData.size()) begin
      `uvm_error("SB_RDATA_SIZE",
        $sformatf("[target %0d] Read size mismatch: apb=%0d target=%0d",
                  tgt_idx, apb_read_data.size(), tgt.readData.size()))
    end else begin
      for (int i = 0; i < tgt.readData.size(); i++) begin
        bit [7:0] exp_val;
        if (i < exp_rd_wr_data.size())
          exp_val = exp_rd_wr_data[i];
        else begin
          exp_val = 8'hFF;
          `uvm_warning("SB_RDATA_EMPTY",
            $sformatf("[target %0d] exp_rd_wr_data queue too small", tgt_idx))
        end
        if (exp_val == tgt.readData[i][7:0]) begin
          `uvm_info("SB_RDATA_MATCH",
            $sformatf("[target %0d] readData[%0d]: expected 0x%0x got 0x%0x PASS",
                      tgt_idx, i, exp_val, tgt.readData[i][7:0]), UVM_MEDIUM)
          read_pass++;
        end else begin
          `uvm_error("SB_RDATA_MISMATCH",
            $sformatf("[target %0d] readData[%0d]: expected 0x%0x got 0x%0x FAIL",
                      tgt_idx, i, exp_val, tgt.readData[i][7:0]))
          read_fail++;
        end
      end
    end
    exp_rd_wr_data.delete();
  end
endtask : compare_with_target
// ============================================================================
// compare_with_hdr_target  (HDR, MULTI-SLAVE)
//
// Mirrors compare_with_target() (SDR) structure, but scores against hdr_*
// counters and uses SB_HDR_* IDs so HDR and SDR results never mix in logs
// or in the summary. Every byte gets an explicit PASS/FAIL log line.
//
// HDR WRITE: compares APB WDATAB bytes (what the DUT was told to send)
// against what the target monitor actually captured on the bus.
//
// HDR READ: compares what the target monitor captured being driven onto
// the bus (tgt.readData -- target's own transmission) against what the
// APB-side sequence read back out of RDATAB (apb_read_data -- what the
// DUT forwarded to software). This is NOT a write-loopback check; HDR
// read data is independent, freshly-randomized data, so it must never be
// compared against exp_rd_wr_data (which belongs only to the SDR
// write-then-readback flow).
// ============================================================================
task i3c_scoreboard::compare_with_hdr_target();
  i3c_target_tx tgt;
  int           tgt_idx;
  // Find which slave this HDR transaction was directed to
  tgt_idx = find_target_by_address(exp_address);
  if (tgt_idx < 0) begin
    `uvm_error("SB_HDR_NO_TARGET",
      $sformatf("HDR: Cannot find target for address 0x%0x", exp_address))
    return;
  end
  `uvm_info("SB_HDR",
    $sformatf("HDR: collecting from target_analysis_fifo[%0d] addr=0x%0x",
              tgt_idx, exp_address), UVM_MEDIUM)
  target_analysis_fifo[tgt_idx].get(tgt);
  target_tx_count++;
  `uvm_info("SB", $sformatf("Target[%0d] pkt:\n%s", tgt_idx, tgt.sprint()),
    UVM_HIGH)
  // -- txn_type check
  if (tgt.txn_type != i3c_target_tx::HDR_WRITE &&
      tgt.txn_type != i3c_target_tx::HDR_READ) begin
    `uvm_error("SB_HDR_TXN_TYPE",
      $sformatf("[target %0d] Expected HDR txn but got txn_type=%s",
                tgt_idx, tgt.txn_type.name()))
  end
  // -- Operation check
  begin
    operationType_e exp_op = (exp_direction == 1'b0) ?
                             i3c_globals_pkg::WRITE :
                             i3c_globals_pkg::READ;
    if (exp_op == tgt.operation)
      `uvm_info("SB_HDR_OP_MATCH",
        $sformatf("[target %0d] HDR Operation %s PASS", tgt_idx, exp_op.name()),
        UVM_MEDIUM)
    else
      `uvm_error("SB_HDR_OP_MISMATCH",
        $sformatf("[target %0d] HDR Operation: expected %s got %s",
                  tgt_idx, exp_op.name(), tgt.operation.name()))
  end

  if (exp_direction == 1'b0) begin
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// HDR WRITE COMPARE /////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    // DUT drives target: compare APB WDATAB bytes (exp_write_data, what
    // software queued for the DUT to send) against what the target
    // monitor actually captured being driven on the bus (tgt.writeData).
    int actual_bytes = tgt.writeData.size();
    `uvm_info("SB",
      $sformatf("[target %0d] HDR Write: APB sent %0d bytes, CTRL length=%0d, target received %0d bytes",
                tgt_idx, exp_write_data.size(), exp_length, actual_bytes),
      UVM_MEDIUM)
    for (int i = 0; i < actual_bytes; i++) begin
      bit [7:0] exp_val;
      exp_val = (i < exp_write_data.size()) ? exp_write_data[i] : 8'hFF;
      if (exp_val == tgt.writeData[i][7:0]) begin
        `uvm_info("SB_HDR_WDATA_MATCH",
          $sformatf("[target %0d] HDR writeData[%0d]: expected 0x%0x got 0x%0x PASS",
                    tgt_idx, i, exp_val, tgt.writeData[i][7:0]), UVM_MEDIUM)
        hdr_write_pass++;
      end else begin
        `uvm_error("SB_HDR_WDATA_MISMATCH",
          $sformatf("[target %0d] HDR writeData[%0d]: expected 0x%0x got 0x%0x FAIL",
                    tgt_idx, i, exp_val, tgt.writeData[i][7:0]))
        hdr_write_fail++;
      end
    end
    if (exp_write_data.size() > actual_bytes)
      `uvm_info("SB_HDR_FIFO_OVERFLOW",
        $sformatf("[target %0d] APB sent %0d bytes, target got %0d, RTL may have dropped %0d",
                  tgt_idx,
                  exp_write_data.size(), actual_bytes,
                  exp_write_data.size() - actual_bytes), UVM_MEDIUM)
    ////////////////////////////////////////////////////////////////////////
    /////////////////////// END HDR WRITE COMPARE ////////////////////////////
    ////////////////////////////////////////////////////////////////////////

  end else begin
    ////////////////////////////////////////////////////////////////////////
    ////////////////////////// HDR READ COMPARE //////////////////////////////
    ////////////////////////////////////////////////////////////////////////
    // Target drives the bus, DUT forwards it to software: compare what the
    // target monitor captured being driven on the bus (tgt.readData) against
    // what the APB-side sequence actually read back out of RDATAB
    // (apb_read_data). Both sides are independent, freshly-captured values
    // for THIS transaction -- do NOT compare against exp_rd_wr_data, which
    // only applies to the SDR write-then-readback loopback flow.
    bit [7:0]     apb_read_data[$];
    apb_master_tx rd_pkt;
    int           rd_count = 0;
    while (rd_count < int'(exp_length)) begin
      apb_analysis_fifo.get(rd_pkt);
      apb_tx_count++;
      if (rd_pkt.pwrite == apb_global_pkg::READ &&
          rd_pkt.paddr[6:0] == 7'h40) begin
        apb_read_data.push_back(rd_pkt.prdata[7:0]);
        `uvm_info("SB",
          $sformatf("[target %0d] HDR RDATAB[%0d] = 0x%0x",
                    tgt_idx, rd_count, rd_pkt.prdata[7:0]), UVM_HIGH)
        rd_count++;
      end
    end

    if (apb_read_data.size() != tgt.readData.size()) begin
      `uvm_error("SB_HDR_RDATA_SIZE",
        $sformatf("[target %0d] HDR Read size mismatch: apb=%0d target_driven=%0d",
                  tgt_idx, apb_read_data.size(), tgt.readData.size()))
    end else begin
      for (int i = 0; i < apb_read_data.size(); i++) begin
        if (apb_read_data[i] == tgt.readData[i][7:0]) begin
          `uvm_info("SB_HDR_RDATA_MATCH",
            $sformatf("[target %0d] HDR readData[%0d]: target drove 0x%0x, APB received 0x%0x PASS",
                      tgt_idx, i, tgt.readData[i][7:0], apb_read_data[i]), UVM_MEDIUM)
          hdr_read_pass++;
        end else begin
          `uvm_error("SB_HDR_RDATA_MISMATCH",
            $sformatf("[target %0d] HDR readData[%0d]: target drove 0x%0x, APB received 0x%0x FAIL",
                      tgt_idx, i, tgt.readData[i][7:0], apb_read_data[i]))
          hdr_read_fail++;
        end
      end
    end
    // NOTE: exp_rd_wr_data is intentionally left untouched here (no
    // .delete()) -- it belongs to the SDR write/readback flow only and
    // must not be consumed/cleared by the HDR read path.
    ////////////////////////////////////////////////////////////////////////
    /////////////////////// END HDR READ COMPARE /////////////////////////////
    ////////////////////////////////////////////////////////////////////////
  end
endtask : compare_with_hdr_target
function void i3c_scoreboard::check_phase(uvm_phase phase);
  super.check_phase(phase);
  `uvm_info("SB_SUMMARY", $sformatf({
    "\n============= SCOREBOARD SUMMARY =============\n",
    "  APB transactions seen      : %0d\n",
    "  I3C target transactions    : %0d\n",
    "  -- SDR --\n",
    "  Write byte pass / fail     : %0d / %0d\n",
    "  Read  byte pass / fail     : %0d / %0d\n",
    "  -- HDR --\n",
    "  Write byte pass / fail     : %0d / %0d\n",
    "  Read  byte pass / fail     : %0d / %0d\n",
    "  -- DAA --\n",
    "  Devices seen               : %0d / %0d expected\n",
    "  Dyn address pass / fail    : %0d / %0d\n",
    "  Parity/ACK  pass / fail    : %0d / %0d\n",
    "=============================================="},
    apb_tx_count,    target_tx_count,
    write_pass,      write_fail,
    read_pass,       read_fail,
    hdr_write_pass,  hdr_write_fail,
    hdr_read_pass,   hdr_read_fail,
    daa_devices_seen, i3c_env_cfg_h.no_of_daa_devices,
    daa_addr_pass,   daa_addr_fail,
    daa_parity_pass, daa_parity_fail),
    UVM_NONE)
  // SDR error flags
  if (write_fail != 0)
    `uvm_error("SB_SUMMARY", $sformatf("%0d write data mismatch(es)", write_fail))
  if (read_fail != 0)
    `uvm_error("SB_SUMMARY", $sformatf("%0d read data mismatch(es)", read_fail))
  // HDR error flags
  if (hdr_write_fail != 0)
    `uvm_error("SB_SUMMARY", $sformatf("%0d HDR write data mismatch(es)", hdr_write_fail))
  if (hdr_read_fail != 0)
    `uvm_error("SB_SUMMARY", $sformatf("%0d HDR read data mismatch(es)", hdr_read_fail))
  // DAA: count check
  if (i3c_env_cfg_h.has_daa &&
      daa_devices_seen != i3c_env_cfg_h.no_of_daa_devices)
    `uvm_error("SB_SUMMARY",
      $sformatf("DAA device count: expected %0d, saw %0d",
                i3c_env_cfg_h.no_of_daa_devices, daa_devices_seen))
  // DAA: address error flags
  if (daa_addr_fail != 0)
    `uvm_error("SB_SUMMARY",
      $sformatf("%0d DAA dynamic address mismatch(es)", daa_addr_fail))
  if (daa_parity_fail != 0)
    `uvm_error("SB_SUMMARY",
      $sformatf("%0d DAA parity/ACK failure(s)", daa_parity_fail))
  // DAA: unique dynamic address check across all slaves
  if (i3c_env_cfg_h.has_daa) begin
    for (int i = 0; i < i3c_env_cfg_h.no_of_targets; i++) begin
      for (int j = i+1; j < i3c_env_cfg_h.no_of_targets; j++) begin
        if (i3c_env_cfg_h.i3c_target_agent_cfg_h[i].targetAddress ==
            i3c_env_cfg_h.i3c_target_agent_cfg_h[j].targetAddress)
          `uvm_error("SB_DAA_DUPLICATE_ADDR",
            $sformatf("Targets %0d and %0d have the same dynamic address 0x%0h",
                      i, j,
                      i3c_env_cfg_h.i3c_target_agent_cfg_h[i].targetAddress))
      end
    end
  end
  // DAA: unique PID check across all slaves
  if (i3c_env_cfg_h.has_daa) begin
    for (int i = 0; i < i3c_env_cfg_h.no_of_targets; i++) begin
      for (int j = i+1; j < i3c_env_cfg_h.no_of_targets; j++) begin
        if (i3c_env_cfg_h.i3c_target_agent_cfg_h[i].pid ==
            i3c_env_cfg_h.i3c_target_agent_cfg_h[j].pid)
          `uvm_error("SB_DAA_DUPLICATE_PID",
            $sformatf("Targets %0d and %0d have the same PID 0x%0h (arb broken)",
                      i, j,
                      i3c_env_cfg_h.i3c_target_agent_cfg_h[i].pid))
      end
    end
  end
  // Per-slave FIFO drain check
  foreach (target_analysis_fifo[i]) begin
    if (target_analysis_fifo[i].size() != 0)
      `uvm_error("SB_SUMMARY",
        $sformatf("target_analysis_fifo[%0d] not empty: %0d leftover packet(s)",
                  i, target_analysis_fifo[i].size()))
  end
  if (apb_analysis_fifo.size() != 0)
    `uvm_error("SB_SUMMARY",
      $sformatf("APB FIFO not empty: %0d leftover packet(s)",
                apb_analysis_fifo.size()))
  `uvm_info("SB_SUMMARY", "check_phase complete", UVM_LOW)
endfunction : check_phase
`endif




