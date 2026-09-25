`timescale 1ns/1ps

module tb_mmss_counter;
  reg clk_50mhz = 0, rst_p = 1;
  wire [3:0] mt, mo, st, so;
  reg [3:0] decode_digit;
  wire [7:0] decoded_segments;
  integer checks = 0;

  // 50 MHz 클록 (#10 = 20 ns 주기)
  always #10 clk_50mhz = ~clk_50mhz;

  // 빠른 검증을 위해 1초 = 2클록(40 ns)으로 축소 설정
  mmss_counter #(.CLK_HZ(2)) dut (
    .clk(clk_50mhz),
    .rst_p(rst_p),
    .minute_tens(mt),
    .minute_ones(mo),
    .second_tens(st),
    .second_ones(so)
  );

  sevenseg_decode decoder (
    .digit(decode_digit),
    .segments(decoded_segments)
  );

  // n초(seconds * 2 클록) 전진 태스크
  task advance(input integer seconds);
    begin
      repeat (seconds * 2) @(posedge clk_50mhz);
      #1;
    end
  endtask

  // BCD 시·분·초 값 검증 태스크
  task check_time(input integer emt, input integer emo, input integer est, input integer eso);
    begin
      if (mt !== emt || mo !== emo || st !== est || so !== eso)
        $fatal(1, "time=%0d%0d:%0d%0d expected=%0d%0d:%0d%0d", mt, mo, st, so, emt, emo, est, eso);
      checks++;
    end
  endtask

  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_mmss_counter);

    // Check 1: 세그먼트 디코더 digit 0 검증
    decode_digit = 0; #1;
    if (decoded_segments !== 8'b1111_1100) $fatal(1, "digit 0 decode");
    checks++;

    // Check 2: 세그먼트 디코더 digit 9 검증
    decode_digit = 9; #1;
    if (decoded_segments !== 8'b1111_0110) $fatal(1, "digit 9 decode");
    checks++;

    // Check 3: 리셋 초기화 00:00 검증
    repeat(2) @(posedge clk_50mhz);
    rst_p = 0;
    check_time(0, 0, 0, 0);

    // Check 4: 10초 경계 전이 (00:09 -> 00:10)
    advance(10);
    check_time(0, 0, 1, 0);

    // Check 5: 1분 경계 전이 (00:59 -> 01:00, 누적 60초)
    advance(50);
    check_time(0, 1, 0, 0);

    // Check 6: 59분 59초 경계 전이 (누적 3599초)
    advance(3539);
    check_time(5, 9, 5, 9);

    // Check 7: 3600초 완료 후 00:00 순환(Wrap-around) 검증
    advance(1);
    check_time(0, 0, 0, 0);

    $display("LAB3_MMSS_PASS checks=%0d", checks);
    $finish;
  end

  initial begin
    #200000;
    $fatal(1, "timeout");
  end

endmodule