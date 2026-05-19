module i3c_ibi_detector(
      
      input  wire clk,
      input  wire rst_n,
      
      input  wire scl,
      input  wire sda,
      
      input  wire bus_idle,
      
      output reg  ibi_request
);

reg       sda_prev;
reg [3:0] idle_cnt;

always @(posedge clk) begin
  if (bus_idle)
    idle_cnt <= idle_cnt + 1;
  else
    idle_cnt <= 0;
end

wire stable_idle = (idle_cnt > 2);

always @(posedge clk or negedge rst_n) begin

  if(!rst_n) begin
    sda_prev    <= 1'b1;
    ibi_request <= 1'b0;
  end
  else begin
    sda_prev <= sda;
    ibi_request <= 1'b0;

    if (stable_idle && scl && sda_prev && !sda)
    ibi_request <= 1'b1;

  end

end
endmodule

