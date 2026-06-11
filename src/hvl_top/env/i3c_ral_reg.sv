/*CTRL REG
[31]      start
[30:26]   reserved
[25:24]   cmd_type
[23:16]   CCC
[15]      direction
[14:7]    length
[6:0]     address
*/

class i3c_ctrl_reg extends uvm_reg;

`uvm_object_utils(i3c_ctrl_reg)

  rand uvm_reg_field start;
       uvm_reg_field reserved;
  rand uvm_reg_field cmd_type;
  rand uvm_reg_field cmd_mode;
  rand uvm_reg_field cmd_ccc;
  rand uvm_reg_field cmd_dir;
  rand uvm_reg_field cmd_len;
  rand uvm_reg_field cmd_addr;

  function new(string name = "i3c_ctrl_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    cmd_addr = uvm_reg_field::type_id::create("cmd_addr");
    cmd_addr.configure(this, 7, 0, "WO", 0, 0, 1, 0, 0);

    cmd_len = uvm_reg_field::type_id::create("cmd_len");
    cmd_len.configure(this, 8, 7, "WO", 0, 0, 1, 0, 0);

    cmd_dir = uvm_reg_field::type_id::create("cmd_dir");
    cmd_dir.configure(this, 1, 15, "WO", 0, 0, 1, 0, 0);

    cmd_ccc = uvm_reg_field::type_id::create("cmd_ccc");
    cmd_ccc.configure(this, 8, 16, "WO", 0, 0, 1, 0, 0);

    cmd_type = uvm_reg_field::type_id::create("cmd_type");
    cmd_type.configure(this, 2, 24, "RW", 0, 0, 1, 0, 0);
   
    cmd_mode = uvm_reg_field::type_id::create("cmd_mode");
    cmd_mode.configure(this, 1, 26, "WO", 0, 0, 1, 0, 0);

    reserved = uvm_reg_field::type_id::create("reserved");
    reserved.configure(this, 4, 27, "WO", 0, 0, 1, 0, 0);

    start = uvm_reg_field::type_id::create("start");
    start.configure(this, 1, 31, "WO", 0, 0, 1, 0, 0);

  endfunction

endclass



class i3c_wdatab_reg extends uvm_reg;

`uvm_object_utils(i3c_wdatab_reg)

  rand uvm_reg_field tx_data;

  function new(string name = "i3c_wdatab_reg");
    super.new(name, 8, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    tx_data = uvm_reg_field::type_id::create("tx_data");
    tx_data.configure(this, 8, 0, "WO", 0, 0, 1, 0, 0);
  endfunction

endclass

//rdatab_reg
class i3c_rdatab_reg extends uvm_reg;
 `uvm_object_utils(i3c_rdatab_reg) 

  uvm_reg_field rx_data;

  function new(string name = "i3c_rdatab_reg");
    super.new(name, 8, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    rx_data = uvm_reg_field::type_id::create("rx_data");
    rx_data.configure(this, 8, 0, "RO", 0, 0, 1, 0, 0);
  endfunction

endclass

class i3c_status_reg extends uvm_reg;

  `uvm_object_utils(i3c_status_reg)

  uvm_reg_field cmd_busy;
  uvm_reg_field sdr_busy;
  uvm_reg_field sdr_done;
  uvm_reg_field daa_done;
  uvm_reg_field daa_busy;

  uvm_reg_field tx_full;
  uvm_reg_field tx_empty;

  uvm_reg_field rx_full;
  uvm_reg_field rx_empty;

  uvm_reg_field sdr_bit_done;
  uvm_reg_field sdr_bit_busy;

  uvm_reg_field bus_idle;

  uvm_reg_field hdr_busy;
  uvm_reg_field hdr_done;

  uvm_reg_field hdr_bit_done;
  uvm_reg_field hdr_bit_busy;

  uvm_reg_field irq;

  uvm_reg_field reserved;

  function new(string name="i3c_status_reg");
    super.new(name,32,UVM_NO_COVERAGE);
  endfunction


  virtual function void build();

    cmd_busy = uvm_reg_field::type_id::create("cmd_busy");
    cmd_busy.configure(this,1,0,"RO",0,0,1,0,0);

    sdr_busy = uvm_reg_field::type_id::create("sdr_busy");
    sdr_busy.configure(this,1,1,"RO",0,0,1,0,0);

    sdr_done = uvm_reg_field::type_id::create("sdr_done");
    sdr_done.configure(this,1,2,"RO",0,0,1,0,0);

    daa_done = uvm_reg_field::type_id::create("daa_done");
    daa_done.configure(this,1,3,"RO",0,0,1,0,0);

    daa_busy = uvm_reg_field::type_id::create("daa_busy");
    daa_busy.configure(this,1,4,"RO",0,0,1,0,0);

    tx_full = uvm_reg_field::type_id::create("tx_full");
    tx_full.configure(this,1,5,"RO",0,0,1,0,0);

    tx_empty = uvm_reg_field::type_id::create("tx_empty");
    tx_empty.configure(this,1,6,"RO",0,0,1,0,0);

    rx_full = uvm_reg_field::type_id::create("rx_full");
    rx_full.configure(this,1,7,"RO",0,0,1,0,0);

    rx_empty = uvm_reg_field::type_id::create("rx_empty");
    rx_empty.configure(this,1,8,"RO",0,0,1,0,0);

    sdr_bit_done = uvm_reg_field::type_id::create("sdr_bit_done");
    sdr_bit_done.configure(this,1,9,"RO",0,0,1,0,0);

    sdr_bit_busy = uvm_reg_field::type_id::create("sdr_bit_busy");
    sdr_bit_busy.configure(this,1,10,"RO",0,0,1,0,0);

    bus_idle = uvm_reg_field::type_id::create("bus_idle");
    bus_idle.configure(this,1,11,"RO",0,0,1,0,0);

    hdr_busy = uvm_reg_field::type_id::create("hdr_busy");
    hdr_busy.configure(this,1,12,"RO",0,0,1,0,0);

    hdr_done = uvm_reg_field::type_id::create("hdr_done");
    hdr_done.configure(this,1,13,"RO",0,0,1,0,0);

    hdr_bit_done = uvm_reg_field::type_id::create("hdr_bit_done");
    hdr_bit_done.configure(this,1,14,"RO",0,0,1,0,0);

    hdr_bit_busy = uvm_reg_field::type_id::create("hdr_bit_busy");
    hdr_bit_busy.configure(this,1,15,"RO",0,0,1,0,0);

    irq = uvm_reg_field::type_id::create("irq");
    irq.configure(this,1,16,"RO",0,0,1,0,0);

   // reserved = uvm_reg_field::type_id::create("reserved");
 //   reserved.configure(this,15,17,"RO",0,0,1,0,0);

  endfunction

endclass

class i3c_dynaddr_reg extends uvm_reg;

`uvm_object_utils(i3c_dynaddr_reg)

  uvm_reg_field dyn_addr;

  function new(string name="i3c_dynaddr_reg");
    super.new(name,32,UVM_NO_COVERAGE);
  endfunction

  virtual function void build();

    dyn_addr=uvm_reg_field::type_id::create("dyn_addr");

    dyn_addr.configure(this,7,0,"RO",0,0,1,0,0);


  endfunction

endclass


 
