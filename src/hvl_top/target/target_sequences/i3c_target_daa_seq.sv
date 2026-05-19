`ifndef I3C_TARGET_DAA_SEQ_INCLUDED_
`define I3C_TARGET_DAA_SEQ_INCLUDED_

class i3c_target_daa_seq extends i3c_target_base_seq;
  `uvm_object_utils(i3c_target_daa_seq)

  extern function new(string name = "i3c_target_daa_seq");
  extern task body();

endclass : i3c_target_daa_seq


function i3c_target_daa_seq::new(string name = "i3c_target_daa_seq");
  super.new(name);
endfunction : new


task i3c_target_daa_seq::body();
  req = i3c_target_tx::type_id::create("req");
  start_item(req);

  `uvm_info(get_type_name(),
    "Before randomization - DAA req created", UVM_NONE)


  req.txn_type = i3c_target_tx::DAA;

if(!req.randomize() with {
  txn_type == i3c_target_tx::DAA;

  pid inside {[48'h0 : 48'hFFFFFFFFFFFF]};

  bcr inside {[8'h00 : 8'h7F]};
  bcr[7] == 1'b0;

  dcr inside {[8'h00 : 8'hFF]};

}) begin
  `uvm_error(get_type_name(), "Randomization failed")
end

 else begin
    `uvm_info(get_type_name(), $sformatf(
      "Randomization SUCCESS - txn_type=%s PID=0x%0x BCR=0x%0x DCR=0x%0x",
      req.txn_type.name(), req.pid, req.bcr, req.dcr), UVM_NONE)
    req.print();
  end

  finish_item(req);
  `uvm_info(get_type_name(),
    "finish_item returned - DAA item sent to driver", UVM_NONE)
endtask : body

`endif
