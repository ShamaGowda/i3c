`ifndef I3C_INVALID_ADDR_WRITE_VIRTUAL_SEQ_INCLUDED_
`define I3C_INVALID_ADDR_WRITE_VIRTUAL_SEQ_INCLUDED_

class i3c_invalid_addr_write_virtual_seq extends top_virtual_base_seq;

`uvm_object_utils(i3c_invalid_addr_write_virtual_seq)

uvm_status_e status;
uvm_reg_data_t ctrl_val;
uvm_reg_data_t ctrl_mirror;

// invalid address
localparam bit [6:0] INVALID_ADDR = 7'h7F;

function new(string name = "i3c_invalid_addr_write_virtual_seq");
super.new(name);
endfunction

task body();

super.body();

`uvm_info(get_type_name(),
  "Starting INVALID ADDRESS WRITE test",
  UVM_LOW)


i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(
  status,
  8'hA5,
  .parent(this)
);

i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_addr.set(
  INVALID_ADDR
);

i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_len.set(
  8'd1
);

i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_dir.set(
  1'b0 
);

i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(
  2'b00
);

i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(
  1'b1
);

ctrl_val =
  i3c_env_cfg_h.regBlockHandle.ctrl_inst.get();

`uvm_info("CTRL_DEBUG",
  $sformatf("CTRL value (invalid addr write) = %0h",
  ctrl_val),
  UVM_LOW)

i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(
  status,
  .parent(this)
);

if(status != UVM_IS_OK)
  `uvm_error("RAL","CTRL write failed")

// Wait for transaction to complete
#5000;


i3c_env_cfg_h.regBlockHandle.ctrl_inst.mirror(
  status,
  UVM_NO_CHECK
);

ctrl_mirror =
  i3c_env_cfg_h.regBlockHandle.ctrl_inst.get_mirrored_value();

`uvm_info("INVALID_ADDR_CHECK",
  $sformatf("CTRL after invalid write = %0h", ctrl_mirror),
  UVM_LOW)


`uvm_info(get_type_name(),
  "INVALID ADDRESS WRITE test completed",
  UVM_LOW)

endtask

endclass

`endif

