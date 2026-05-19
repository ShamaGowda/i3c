`ifndef I3C_TARGET_CFG_CONVERTER_INCLUDED_
`define I3C_TARGET_CFG_CONVERTER_INCLUDED_

class i3c_target_cfg_converter extends uvm_object;

  extern function new(string name = "i3c_target_cfg_converter");

  extern static function void from_class(
    input  i3c_target_agent_config input_conv_h,
    output i3c_transfer_cfg_s      output_conv);

  extern function void do_print(uvm_printer printer);

endclass : i3c_target_cfg_converter



function i3c_target_cfg_converter::new(string name = "i3c_target_cfg_converter");
  super.new(name);
endfunction : new



function void i3c_target_cfg_converter::from_class(
  input  i3c_target_agent_config input_conv_h,
  output i3c_transfer_cfg_s      output_conv);

  output_conv.targetAddress        = input_conv_h.targetAddress;
  output_conv.dataTransferDirection =
      dataTransferDirection_e'(input_conv_h.dataTransferDirection);
  output_conv.defaultReadData      = input_conv_h.defaultReadData;


  output_conv.pid                  = input_conv_h.pid;
  output_conv.bcr                  = input_conv_h.bcr;
  output_conv.dcr                  = input_conv_h.dcr;
  output_conv.daa_accept_address   = input_conv_h.daa_accept_address;

endfunction : from_class


function void i3c_target_cfg_converter::do_print(uvm_printer printer);
  super.do_print(printer);
endfunction : do_print

`endif
