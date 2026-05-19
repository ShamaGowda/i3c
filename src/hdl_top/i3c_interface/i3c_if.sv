interface i3c_if(input pclk, input areset, inout SCL, inout SDA);

// Internal signals
logic scl_i;
logic scl_o;
logic scl_oen;

logic sda_i;
logic sda_o;
logic sda_oen;

//---------------------------------
// OPEN-DRAIN / TRI-STATE MODEL
//---------------------------------
assign SCL = (scl_oen) ? scl_o : 1'bz;
assign SDA = (sda_oen) ? sda_o : 1'bz;

//---------------------------------
// Sampling
//---------------------------------
assign scl_i = SCL;
assign sda_i = SDA;

endinterface

