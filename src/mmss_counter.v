`timescale 1ns/1ps

module mmss_counter #(
  parameter integer CLK_HZ = 50_000_000
)(
  input wire clk,
  input wire rst_p,
  output reg [3:0] minute_tens,
  output reg [3:0] minute_ones,
  output reg [3:0] second_tens,
  output reg [3:0] second_ones
);

  localparam integer COUNT_WIDTH = (CLK_HZ < 2) ? 1 : $clog2(CLK_HZ);
  reg [COUNT_WIDTH-1:0] subsecond;

  // 1초 단위 clock-enable 생성 및 BCD 계수 로직 (00:00 ~ 59:59 순환)
  always @(posedge clk or posedge rst_p) begin
    if (rst_p) begin
      subsecond   <= {COUNT_WIDTH{1'b0}};
      minute_tens <= 4'd0;
      minute_ones <= 4'd0;
      second_tens <= 4'd0;
      second_ones <= 4'd0;
    end else if (subsecond == CLK_HZ - 1) begin
      subsecond <= {COUNT_WIDTH{1'b0}};
      if (second_ones != 4'd9) begin
        second_ones <= second_ones + 1'b1;
      end else begin
        second_ones <= 4'd0;
        if (second_tens != 4'd5) begin
          second_tens <= second_tens + 1'b1;
        end else begin
          second_tens <= 4'd0;
          if (minute_ones != 4'd9) begin
            minute_ones <= minute_ones + 1'b1;
          end else begin
            minute_ones <= 4'd0;
            if (minute_tens != 4'd5) begin
              minute_tens <= minute_tens + 1'b1;
            end else begin
              minute_tens <= 4'd0;
            end
          end
        end
      end
    end else begin
      subsecond <= subsecond + 1'b1;
    end
  end

endmodule