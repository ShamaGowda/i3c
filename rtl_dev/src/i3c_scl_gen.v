module i3c_scl_gen #(
  parameter integer CLK_FREQ_HZ    = 100_000_000,
  parameter integer DEFAULT_SCL_HZ = 1_000_000,
  parameter integer MIN_SCL_HZ     = 1_000_000,
  parameter integer MAX_SCL_HZ     = 12_500_000
) (
  input  wire        clk,
  input  wire        rst_n,
  
  input  wire        scl_start,
  input  wire        scl_stop,
  input  wire        push_pull,
  input  wire [31:0] scl_hz_cfg,
  
  output reg         scl_o,
  output reg         scl_oe
);

localparam [1:0]
  IDLE = 2'b00,
  RUN  = 2'b01,
  STOP = 2'b11;

reg       [1:0] state, next;

reg [31:0]  half_period;
reg [31:0]  half_period_n;
reg [31:0]  count;
reg         scl_phase;
reg         bus_idle;
reg [7:0]   bus_idle_cnt;

integer req_hz = 0;
integer tmp = 0;

always @ * begin
  half_period_n = 32'd1;
  
  req_hz = (scl_hz_cfg == 32'd0) ? DEFAULT_SCL_HZ : scl_hz_cfg;

  if (req_hz < MIN_SCL_HZ)
    req_hz = MIN_SCL_HZ;

  if (req_hz > MAX_SCL_HZ)
    req_hz = MAX_SCL_HZ;
  
  tmp = CLK_FREQ_HZ / (2 * req_hz);

  if (tmp < 1)
    tmp = 1;

  half_period_n = tmp;
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    state <= IDLE;
  else
    state <= next;
end

always @ * begin
  case (state)

    IDLE   : next = scl_start ? RUN  : IDLE;

    RUN    : next = scl_stop  ? STOP : RUN;

    STOP   : next = bus_idle  ? IDLE : STOP;

    default: next = IDLE;

  endcase
end

always @ * begin
  case (state)

    IDLE:
      {scl_o, scl_oe} = 2'b10;

    RUN: begin

      if (push_pull) begin
        scl_oe  = 1'b1;
        scl_o   = scl_phase;
      end

      else begin
        scl_oe  = scl_phase ? 1'b0 : 1'b1;
        scl_o   = 1'b0;
      end

    end

    STOP:
      {scl_o, scl_oe} = 2'b10;

  endcase
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin

    half_period  <= 'd0;
    count        <= 'd0;
    scl_phase    <= 'b1;
    bus_idle     <= 'b0;
    bus_idle_cnt <= 8'b0;

  end else begin

    case (state)

      IDLE : begin
      end

      RUN: begin

        half_period <= half_period_n;

        if (count == half_period - 1) begin
          count     <= 32'd0;
          scl_phase <= ~scl_phase;
        end

        else begin
          count <= count + 1;
        end

      end

      STOP: begin

        if (bus_idle_cnt < 19) begin
          bus_idle_cnt <= bus_idle_cnt + 1;
          bus_idle     <= 1'b0;
        end

        else begin
          bus_idle     <= 1'b1;
          bus_idle_cnt <= 8'b0;
        end

      end

      default: begin

        half_period  <= 'd0;
        count        <= 'd0;
        scl_phase    <= 'b1;
        bus_idle     <= 'b0;
        bus_idle_cnt <= 8'b0;

      end

    endcase
  end
end

endmodule
