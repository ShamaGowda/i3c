`define REG_STATUS       12'h008
/*
 * BUSY
 * ERROR
 * DAA_ACTIVE
 * RX_READY
 * TX_EMPTY
 * TRANSFER_DONE etc
 * */
`define REG_CTRL         12'h00C
/*
 * START_CMD
 * STOP
 * R/W direction
 * Trigger CCC
 * Trigger SDR transfer
 * Trigger ENTDAA
 * */
`define REG_WDATAB       7'h30 //Master write data - FIFO input
`define REG_RDATAB       7'h40 //Master read data - FIFO output
`define REG_DYNADDR      7'h64 //This stores the dynamic address
`define CCC_RSTDAA       8'h06   // Reset Dynamic Address Assignment
`define CCC_ENTDAA       8'h07   // Start Dynamic Address Assignment
`define CCC_GETPID       8'h8D   // Read Provisional ID
`define CCC_GETBCR       8'h8E   // Read Bus Characteristics Register
`define CCC_GETDCR       8'h8F   // Read Device Characteristics Register

