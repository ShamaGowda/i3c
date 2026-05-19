module i3c_ibi_fsm(
      
      input  wire        clk,
      input  wire        rst_n,
      
      input  wire        ibi_request,
      
      output reg         be_valid,
      output reg         be_rd_wr,
      
      input  wire [7:0]  be_rx_data,
      input  wire        be_busy,
      input  wire        be_done,
      
      output reg         lookup_en,
      output reg [6:0]   lookup_addr,
      input  wire        device_known,
      
      output reg  [6:0]  ibi_addr,
      output reg  [7:0]  ibi_payload,
      output reg         ibi_valid,
      output reg         hotjoin_req,
      input  wire        daa_done    
);

localparam  IDLE         = 3'd0,
            ACK_IBI      = 3'd1,
            READ_ADDR    = 3'd2,
            CHECK        = 3'd3,
            CHECK_WAIT   = 3'd4,
            READ_DATA    = 3'd5,
            DONE         = 3'd6,
            HOTJOIN      = 3'd7;

reg [2:0] state, next_state;
reg       hotjoin_detected;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= next_state;
end

always @(*) begin
  next_state = state;

  case(state)

    IDLE: begin
      if (ibi_request)
        next_state = ACK_IBI;
    end

    ACK_IBI: begin
      if (!be_busy)
        next_state = READ_ADDR;
    end

    READ_ADDR: begin
      if (!be_busy && be_done)
        next_state = CHECK;
    end

    CHECK: begin
      next_state = CHECK_WAIT;
    end

    CHECK_WAIT: begin
      if (device_known)
        next_state = READ_DATA;
      else
        next_state = HOTJOIN;
    end

    READ_DATA: begin
      if (!be_busy && be_done) begin
        next_state = DONE;
        ibi_valid  = 1;
      end
    end

    HOTJOIN: begin
      if(daa_done)
        next_state = DONE;
    end

    DONE: begin
      next_state = IDLE;
    end

    default:
      next_state = IDLE;

  endcase
end

always @(*) begin

  be_valid    = 0;
  be_rd_wr    = 1'b1;

  lookup_en   = 0;
  lookup_addr = ibi_addr;

  ibi_valid   = 0;
  hotjoin_req = 0;

  case(state)

    READ_ADDR: begin

      if (!be_busy)
        be_valid = 1'b1;

      be_rd_wr = 1'b1;
    end
    
    CHECK,
    CHECK_WAIT: begin

      lookup_en   = 1'b1;
      lookup_addr = ibi_addr;
      be_valid    = 1'b0;

    end

    READ_DATA: begin

      be_valid = 1;

      if (!be_busy)
        be_valid = 1'b0;

      be_rd_wr = 1'b1;

    end

    HOTJOIN: begin

      be_rd_wr    = 1'b0;
      hotjoin_req = 1'b1;

    end

    DONE: begin

      if (!hotjoin_detected) begin
        ibi_valid = 1'b1;
        be_rd_wr  = 1'b0;
      end

    end

  endcase
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin

    ibi_addr         <= 7'd0;
    ibi_payload      <= 8'd0;
    hotjoin_detected <= 1'b0;

  end

  else begin

    if (state == IDLE)
      hotjoin_detected <= 1'b0;

    if (state == READ_ADDR && be_done)
      ibi_addr <= be_rx_data[7:1];

    if (state == READ_DATA && be_done)
      ibi_payload <= be_rx_data;

    if (state == HOTJOIN)
      hotjoin_detected <= 1'b1;

  end
end

endmodule
