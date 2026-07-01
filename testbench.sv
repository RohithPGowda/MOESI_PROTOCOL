`timescale 1ns/1ps
`include "interface.sv"
`include "test.sv"

module testbench;

  // Clock and reset
  logic clk;
  logic rst;

  // Clock generation
  initial clk = 0;
  always #5 clk = ~clk;

  // Reset generation
  initial begin
    rst = 1;
    #20 rst = 0;
  end

  // Interface instantiation
  cache_if cif(clk, rst);

  // DUT instantiation
  top_cache_system dut (
    .clk        (clk),
    .rst        (rst),
    // Core interface - corrected signals
    .core_read  (cif.local_read),
    .core_write (cif.local_write),
    .core_addr  (cif.addr),
    .core_wdata (cif.wdata),
    .core_rdata (cif.rdata),
    // Memory interface (can leave as default for now)
    .mem_read   (),
    .mem_write  (),
    .mem_addr   (),
    .mem_wdata  (),
    .mem_rdata  (32'hDEADBEEF)  // Stub memory response
  );

  // Test program
  test t1(cif);

endmodule
