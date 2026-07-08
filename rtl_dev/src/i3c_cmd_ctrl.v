`include "param.v"

module i3c_cmd_ctrl (

  input  wire        clk,
  input  wire        rst_n,

  input  wire        cmd_start,
  input  wire [1:0]  cmd_type,
  input  wire [6:0]  cmd_addr,
  input  wire        cmd_mode,
  input  wire [7:0]  cmd_ccc,
  input  wire [7:0]  cmd_len,
  input  wire        cmd_dir,

  output reg         start_sdr,
  output reg  [6:0]  sdr_addr,
  output reg  [7:0]  sdr_len,
  output reg         sdr_dir,

  output reg         sdr_is_ccc,
  output reg  [7:0]  sdr_ccc_code,
  output reg         sdr_ccc_is_read,
  output reg [7:0]   sdr_read_len,
  output reg         sdr_has_restart,
  output reg         start_daa,
  output reg         start_hdr,

  input  wire        sdr_done,
  input  wire        daa_done,
  input  wire        hdr_done,
  input  wire        be_done,
  
  output reg         hdr_pending,
  output reg         cmd_busy,
  output reg         shift_hold,
  output reg         rstdaa_done
);

wire ccc_is_entdaa;
wire ccc_is_rstdAA;
wire ccc_is_directed;
wire ccc_is_read;
wire ccc_is_getpid;
wire ccc_is_getbcr;
wire ccc_is_getdcr;

assign ccc_is_getpid   = (cmd_ccc == `CCC_GETPID);
assign ccc_is_getbcr   = (cmd_ccc == `CCC_GETBCR);
assign ccc_is_getdcr   = (cmd_ccc == `CCC_GETDCR);
assign ccc_is_entdaa   = (cmd_ccc == `CCC_ENTDAA);
assign ccc_is_rstdAA   = (cmd_ccc == `CCC_RSTDAA);

assign ccc_is_directed = cmd_ccc[7];
assign ccc_is_read     = cmd_ccc[7];

always @(posedge clk or negedge rst_n) begin
  
  if (!rst_n) begin
    start_sdr        <= 0;
    start_daa        <= 0;
    start_hdr        <= 0;
    cmd_busy         <= 0;
    sdr_addr         <= 0;
    sdr_len          <= 0;
    sdr_dir          <= 0;
    sdr_is_ccc       <= 0;
    sdr_ccc_code     <= 0;
    sdr_ccc_is_read  <= 0;
    sdr_read_len     <= 0;
    sdr_has_restart  <= 0;
    hdr_pending      <= 0;
    shift_hold       <= 0;
    rstdaa_done      <= 1'b0;
  end
  
  else begin
    rstdaa_done <= 1'b0;
    start_sdr <= 0;
    start_daa <= 0;
    start_hdr <= 0;
      
    if (cmd_start && !cmd_busy) begin
$display("[%0t] CMD_CTRL: cmd_start=%0b mode=%0b type=%0d addr=0x%02h dir=%0b len=%0d",
         $time, cmd_start, cmd_mode, cmd_type, cmd_addr, cmd_dir, cmd_len);
      cmd_busy <= 1'b1;
      hdr_pending <= 1'b0;

      if (cmd_mode == 1'b0) begin
        sdr_has_restart <= 1'b0;
        sdr_read_len    <= 8'd0;

        case (cmd_type)
      
          2'd0,
          2'd1: begin

            start_sdr  <= 1'b1;
            sdr_addr   <= cmd_addr;
            sdr_len    <= cmd_len;
            sdr_dir    <= cmd_dir;
            sdr_is_ccc <= 1'b0;
          end

          2'd2: begin
            sdr_is_ccc       <= 1'b1;
            sdr_ccc_code     <= cmd_ccc;
            sdr_ccc_is_read  <= ccc_is_read;

            if (ccc_is_directed)
              sdr_addr <= cmd_addr;
            else
              sdr_addr <= 7'h7E;

            if (ccc_is_entdaa) begin
              start_daa <= 1'b1;
            end

            else if (ccc_is_getpid) begin
              start_sdr       <= 1'b1;
              sdr_is_ccc      <= 1'b1;
              sdr_ccc_code    <= cmd_ccc;
              sdr_dir         <= 1'b0;
              sdr_len         <= 1;
              sdr_read_len    <= 6;
              sdr_has_restart <= 1'b1;
              shift_hold      <= 1'b1;
            end

            else if (ccc_is_getbcr) begin
              start_sdr       <= 1'b1;
              sdr_is_ccc      <= 1'b1;
              sdr_ccc_code    <= cmd_ccc;
              sdr_dir         <= 1'b0;
              sdr_len         <= 1;
              sdr_read_len    <= 1;
              sdr_has_restart <= 1'b1;
              shift_hold      <= 1'b0;
            end

            else if (ccc_is_getdcr) begin  
              start_sdr       <= 1'b1;
              sdr_dir         <= 1'b0;
              sdr_len         <= 1;
              sdr_read_len    <= 1;
              sdr_has_restart <= 1'b1;
            end    

            else if (ccc_is_rstdAA) begin
              start_sdr       <= 1'b1;
              sdr_is_ccc      <= 1'b0;
              sdr_ccc_code    <= cmd_ccc;
              sdr_dir         <= 1'b0;
              sdr_len         <= 1;
              sdr_has_restart <= 1'b1;      
            end

            else begin   
              start_sdr       <= 1'b1;
              sdr_len         <= cmd_len;
              sdr_dir         <= cmd_dir;
              sdr_has_restart <= 1'b0; 
            end
          end 

          2'd3: begin
            start_daa <= 1'b1;
          end

        endcase 
      end 
    
      else begin
       $display("[%0t] CMD_CTRL: HDR command received", $time);
        start_sdr    <= 1'b1;
        sdr_addr     <= cmd_addr;
        sdr_len      <= 0;
        sdr_dir      <= cmd_dir;
        sdr_is_ccc   <= 1'b0;
        sdr_ccc_code <= 0;
        hdr_pending  <= 1'b1;
      end

    end 

    if (be_done && hdr_pending) begin
$display("[%0t] CMD_CTRL: be_done=%0b hdr_pending=%0b -> starting HDR",
         $time, be_done, hdr_pending);
   
    $display("[%0t] CMD_CTRL: start_hdr=%0b hdr_pending=%0b sdr_done=%0b hdr_done=%0b",
         $time,
         start_hdr,
         hdr_pending,
         sdr_done,
         hdr_done); 
     
     
     
     start_hdr   <= 1'b1;
      hdr_pending <= 1'b0;
      sdr_len     <= cmd_len;
      sdr_dir     <= cmd_dir;
    end
    
    if (daa_done || hdr_done || (sdr_done && !hdr_pending)) begin
$display("[%0t] CMD_CTRL: Transaction completed   hdr_done  =  %d  , sdr_done = %d  , hdr_pending = %d ", $time, hdr_done , sdr_done  , hdr_pending );
      cmd_busy <= 1'b0;
      
      if (ccc_is_rstdAA && sdr_done)
        rstdaa_done <= 1'b1;
    end 

  end
end

endmodule
