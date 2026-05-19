module i3c_hdr_fsm (

  input  wire        clk,
  input  wire        rst_n,

  input  wire        start_hdr,
  input  wire [7:0]  hdr_len,
  input  wire        hdr_dir,

  input  wire [7:0]  tx_data,
  input  wire        tx_valid,
  output reg         tx_ready,

  output reg  [7:0]  rx_data,
  output reg         rx_valid,
  input  wire        rx_ready,

  output reg         hdr_valid,
  output reg         hdr_rw,
  output reg  [15:0] hdr_tx_data,

  input  wire [15:0] hdr_rx_data,
  input  wire        hdr_done,
  input  wire        hdr_busy,

  output reg         hdr_start,
  output reg         hdr_stop,

  output reg         busy,
  output reg         done

);

localparam IDLE  = 2'd0,
           SEND  = 2'd1,
           RECV  = 2'd2,
           STOP  = 2'd3;

reg [1:0] state, next;
reg [7:0] byte_cnt;

reg [7:0] byte_buf;
reg       byte_buf_valid;

reg [7:0] rx_buf;
reg       push_second;
reg       done_second;
reg       first_read_done;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= next;
end

always @(*) begin
  next = state;

  case (state)

    IDLE:
      if (start_hdr)
        next = (hdr_dir) ? RECV : SEND;

    SEND:
      if (hdr_done && byte_cnt <= 2)
        next = STOP;

    RECV:
      if (done_second)
        next = STOP;

    STOP:
      next = IDLE;

  endcase
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    byte_cnt        <= 0;
    busy            <= 0;
    done            <= 0;
    hdr_start       <= 0;
    hdr_stop        <= 0;

    byte_buf        <= 0;
    byte_buf_valid  <= 0;

    rx_buf          <= 0;
    push_second     <= 0;

    hdr_valid       <= 0;
    hdr_rw          <= 0;
    hdr_tx_data     <= 0;

    tx_ready        <= 0;
    rx_valid        <= 0;
    rx_data         <= 0;
    first_read_done <= 1'b0;
    done_second     <= 1'b0;

  end else begin

    done        <= 0;
    hdr_valid   <= 0;
    tx_ready    <= 0;
    rx_valid    <= 0;

    case (state)

    IDLE: begin
      busy <= 0;
      hdr_stop <= 0;

      if (start_hdr) begin
        byte_cnt       <= hdr_len;
        busy           <= 1;
        hdr_start      <= 1;
        byte_buf_valid <= 0;
        push_second    <= 0;
        done_second    <= 0;
        tx_ready       <= 1'b1;
      end else begin
        hdr_start <= 0;
      end
    end

    SEND: begin
      hdr_start <= 0;

      if (!hdr_busy) begin

        if (!first_read_done) begin
          tx_ready        <= 1'b1;
          first_read_done <= 1'b1;
        end

        else if (!byte_buf_valid && tx_valid) begin
          byte_buf       <= tx_data;
          byte_buf_valid <= 1'b1;
        end

        else if (byte_buf_valid && tx_valid) begin
          hdr_valid      <= 1'b1;
          hdr_rw         <= 1'b0;
          hdr_tx_data    <= {byte_buf, tx_data};
          byte_buf_valid <= 1'b0;
        end

        else if (byte_buf_valid && (byte_cnt == 1)) begin
          hdr_valid      <= 1'b1;
          hdr_rw         <= 1'b0;
          hdr_tx_data    <= {byte_buf, 8'h00};

          byte_buf_valid <= 1'b0;
        end
      end

      if (hdr_done) begin
        if (byte_cnt > 1)
          byte_cnt <= byte_cnt - 2;
        else
          byte_cnt <= 0;
      end
    end

    RECV: begin
      hdr_start <= 0;

      if (push_second) begin
        rx_data     <= rx_buf;
        rx_valid    <= 1'b1;
        push_second <= 1'b0;
        done_second <= 1'b1;
      end

      else if (hdr_done) begin
        rx_data     <= hdr_rx_data[15:8];
        rx_valid    <= 1'b1;

        rx_buf      <= hdr_rx_data[7:0];
        push_second <= 1'b1;

        if (byte_cnt > 1)
          byte_cnt <= byte_cnt - 2;
        else
          byte_cnt <= 0;
      end

      else if (!hdr_busy && !push_second && (byte_cnt != 0)) begin
        hdr_valid <= 1'b1;
        hdr_rw    <= 1'b1;
      end

    end

    STOP: begin
      hdr_stop <= 1'b1;
      done     <= 1'b1;
    end

    endcase
  end
end

endmodule
