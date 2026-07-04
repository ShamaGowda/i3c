module i3c_hdr_ddr_engine (

  input  wire clk,
  input  wire rst_n,

  input  wire valid,
  input  wire rw,
  input  wire [15:0] tx_data,
  output reg  [15:0] rx_data,

  input  wire scl_i,
  input  wire sda_i,
  output reg  sda_o,
  output reg  sda_oe,

  input  wire hdr_start,
  input  wire hdr_stop,

  output reg  busy,
  output reg  done
);

reg [15:0] shift_reg;
reg [4:0]  bit_cnt;

reg scl_q, scl_qq;

always @(posedge clk) begin
  scl_q  <= scl_i;
  scl_qq <= scl_q;
end

wire scl_rise = (scl_q && !scl_qq);
wire scl_fall = (!scl_q && scl_qq);

reg bit_rise, bit_fall;
reg capture_fall;

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    busy         <= 0;
    done         <= 0;
    bit_cnt      <= 0;
    shift_reg    <= 0;
    rx_data      <= 0;
    capture_fall <= 0;
  end else begin

    done <= 0;

    if (valid && !busy) begin
        $display("[%0t] HDR_DDR: START rw=%0b tx_data=0x%04h", $time, rw, tx_data);
      busy      <= 1;
      bit_cnt   <= 16;
      shift_reg <= (rw) ? 16'b0 : tx_data;
    end

    else if (busy && rw) begin

      if (scl_fall) begin
        bit_fall <= sda_i;
        capture_fall <= 1;
      end

      if (scl_rise && capture_fall) begin
        bit_rise <= sda_i;

        shift_reg <= {shift_reg[13:0], bit_fall, sda_i};
        bit_cnt   <= bit_cnt - 2;

        capture_fall <= 0;

        if (bit_cnt == 2) begin
            $display("[%0t] HDR_DDR: RX COMPLETE data=0x%04h",
                         $time,
                                  {shift_reg[13:0], bit_fall, sda_i});
          rx_data <= {shift_reg[13:0], bit_fall, sda_i};
          busy    <= 0;
          done    <= 1;
        end
      end
    end

    else if (busy && !rw) begin

      if (scl_rise || scl_fall) begin
           $display("[%0t] HDR_DDR: TX shift_reg=0x%04h bit_cnt=%0d",
                                $time, shift_reg, bit_cnt);

        shift_reg <= {shift_reg[14:0], 1'b0};
        bit_cnt   <= bit_cnt - 1;

        if (bit_cnt == 1) begin
            $display("[%0t] HDR_DDR: TX COMPLETE", $time);
          busy <= 0;
          done <= 1;
        end
      end
    end

    if (hdr_stop) begin
        $display("[%0t] HDR_DDR: hdr_stop received", $time);
      busy <= 0;
    end

  end
end

always @(*) begin
  if (busy && !rw) begin
    sda_oe = 1'b1;
    sda_o  = shift_reg[15];
  end else begin
    sda_oe = 1'b0;
    sda_o  = 1'b1;
  end
end

endmodule
