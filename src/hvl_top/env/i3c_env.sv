`ifndef I3C_ENV_INCLUDED_
`define I3C_ENV_INCLUDED_

class i3c_env extends uvm_env;

  `uvm_component_utils(i3c_env)

  apb_master_agent       apb_master_agent_h;
  i3c_target_agent       i3c_target_agent_h[];

  top_virtual_sequencer top_virtual_seqr_h;
  i3c_env_config     i3c_env_cfg_h;
  apb_env_config apb_env_cfg_h;

  i3c_scoreboard     i3c_scoreboard_h;

//ral
  i3c_ral_reg_block regmodel;

  apb_master_adapter adapter_inst;

  uvm_reg_predictor#(apb_master_tx) topPredictor;

  extern function new(string name = "i3c_env", uvm_component parent = null);
  extern virtual function void build_phase(uvm_phase phase);
  extern virtual function void connect_phase(uvm_phase phase);

endclass : i3c_env


function i3c_env::new(string name = "i3c_env", uvm_component parent = null);
  super.new(name, parent);
endfunction : new


function void i3c_env::build_phase(uvm_phase phase);
  super.build_phase(phase);

  if(!uvm_config_db #(i3c_env_config)::get(this,"","i3c_env_config",i3c_env_cfg_h)) begin
    `uvm_fatal("CONFIG","cannot get() the i3c_env_cfg_h from the uvm_config_db . Have you set it?")
  end

  if(!uvm_config_db #(apb_env_config)::get(this,"","apb_env_config",apb_env_cfg_h)) begin
    `uvm_fatal("FATAL_ENV_CONFIG", $sformatf("Couldn't get the env_config from config_db"))
  end

  if(i3c_env_cfg_h.has_daa && i3c_env_cfg_h.no_of_daa_devices == 0)
    i3c_env_cfg_h.no_of_daa_devices = i3c_env_cfg_h.no_of_targets;


// Create APB Master
  apb_master_agent_h = apb_master_agent::type_id::create("apb_master_agent_h",this);

   // Create I3C Targets
  i3c_target_agent_h = new[i3c_env_cfg_h.no_of_targets];

  foreach(i3c_target_agent_h[i]) begin
    i3c_target_agent_h[i] =i3c_target_agent::type_id::create(
        $sformatf("i3c_target_agent_h[%0d]",i), this);
  end

// Create Virtual Sequencer
  top_virtual_seqr_h =top_virtual_sequencer::type_id::create("top_virtual_seqr_h", this);

  top_virtual_seqr_h.i3c_env_cfg_h = i3c_env_cfg_h;

  if(i3c_env_cfg_h.has_scoreboard)begin
    i3c_scoreboard_h = i3c_scoreboard::type_id::create("i3c_scoreboard_h", this);
  end

//adapter and predictor
  adapter_inst = apb_master_adapter :: type_id :: create("adapter_inst");
  topPredictor = uvm_reg_predictor#(apb_master_tx) :: type_id :: create("topPredictor",this);

  regmodel =i3c_ral_reg_block::type_id::create("regmodel", this);
  regmodel.build();

  i3c_env_cfg_h.regBlockHandle = regmodel;

endfunction


//connect phase
function void i3c_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  if(i3c_env_cfg_h.has_virtual_sequencer) begin
    foreach(i3c_target_agent_h[i]) begin
      top_virtual_seqr_h.i3c_target_seqr_h = i3c_target_agent_h[i].i3c_target_seqr_h;

      i3c_target_agent_h[i].i3c_target_mon_proxy_h.target_analysis_port.connect(
        i3c_scoreboard_h.target_analysis_fifo.analysis_export
      );
    end
  end

  if(apb_env_cfg_h.has_virtual_seqr) begin
    top_virtual_seqr_h.apb_master_seqr_h = apb_master_agent_h.apb_master_seqr_h;
  end

  apb_master_agent_h.apb_master_mon_proxy_h.apb_master_analysis_port.connect(
    i3c_scoreboard_h.apb_analysis_fifo.analysis_export
  );

  topPredictor.map = regmodel.default_map;
  topPredictor.adapter = adapter_inst;

//reg model connection
  regmodel.default_map.set_sequencer(
    .sequencer(apb_master_agent_h.apb_master_seqr_h),
    .adapter(adapter_inst)
  );

  regmodel.default_map.set_auto_predict(0);

  apb_master_agent_h.apb_master_mon_proxy_h.apb_master_analysis_port.connect(
    topPredictor.bus_in
  );

endfunction

`endif
