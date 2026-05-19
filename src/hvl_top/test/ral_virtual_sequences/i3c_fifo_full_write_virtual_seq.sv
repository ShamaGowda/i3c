`ifndef I3C_FIFO_FULL_WRITE_VIRTUAL_SEQ_INCLUDED_
`define I3C_FIFO_FULL_WRITE_VIRTUAL_SEQ_INCLUDED_

class i3c_fifo_full_write_virtual_seq extends top_virtual_base_seq;

`uvm_object_utils(i3c_fifo_full_write_virtual_seq)

uvm_status_e status;
uvm_reg_data_t ctrl_val;

localparam int FIFO_DEPTH = 16;

function new(string name = "i3c_fifo_full_write_virtual_seq");
super.new(name);
endfunction

task body();

super.body();

`uvm_info(get_type_name(),
  "Starting FIFO FULL WRITE test",
  UVM_LOW)

for (int i = 0; i < FIFO_DEPTH; i++) begin
  i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(
    status,
    i,
    .parent(this)
  );
end

`uvm_info("FIFO_DEBUG",
  "FIFO filled to depth 16",
  UVM_LOW)

// OVERFLOW WRITE 17th
i3c_env_cfg_h.regBlockHandle.wdatab_inst.write(
  status,
  8'hFF,
  .parent(this)
);

`uvm_info("FIFO_DEBUG",
  "Attempted write beyond FIFO depth",
  UVM_LOW)

fork
  begin
    i3c_target_writeOperationWith8bitsData_seq target_seq;
    target_seq =
      i3c_target_writeOperationWith8bitsData_seq::type_id::create("target_seq");

    target_seq.start(p_sequencer.i3c_target_seqr_h);
  end
join_none;

i3c_env_cfg_h.regBlockHandle.ctrl_inst.address.set(TARGET0_ADDRESS);
i3c_env_cfg_h.regBlockHandle.ctrl_inst.length.set(8'd16);
i3c_env_cfg_h.regBlockHandle.ctrl_inst.direction.set(1'b0); // WRITE
i3c_env_cfg_h.regBlockHandle.ctrl_inst.cmd_type.set(2'b00);
i3c_env_cfg_h.regBlockHandle.ctrl_inst.start.set(1'b1);

ctrl_val = i3c_env_cfg_h.regBlockHandle.ctrl_inst.get();

`uvm_info("CTRL_DEBUG",
  $sformatf("CTRL value = %0h", ctrl_val),
  UVM_LOW)

i3c_env_cfg_h.regBlockHandle.ctrl_inst.update(
  status,
  .parent(this)
);

#10000;

`uvm_info(get_type_name(),
  "FIFO FULL WRITE test completed",
  UVM_LOW)

endtask

endclass

`endif

