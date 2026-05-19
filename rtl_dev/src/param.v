// ---------------- REGISTER MAP ----------------

`define REG_CTRL         12'h00C
/*
START_CMD
STOP
R/W direction
Trigger CCC
Trigger SDR transfer
Trigger ENTDAA
*/
`define REG_WDATAB       7'h30 //Master write data - FIFO input
`define REG_RDATAB       7'h40 //Master read data - FIFO output
//CCC_CODES
// --------- BROADCAST CCCs ---------
`define CCC_ENTDAA    8'h07   // Start Dynamic Address Assignment
