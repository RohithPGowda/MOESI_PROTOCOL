interface cache_if #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 15) (input bit clk, input bit rst);

  // Core interface
  logic                   local_read;
  logic                   local_write;
  logic [ADDR_WIDTH-1:0]  addr;
  logic [DATA_WIDTH-1:0]  wdata;
  logic [DATA_WIDTH-1:0]  rdata;

  // Bus interface (L1 <-> L2)
  logic                   busRd;
  logic                   busRdX;
  logic                   busUpgr;
  logic                   supplyData;
  logic                   invalidate;
  logic                   shared;

  // Memory interface
  logic                   mem_read;
  logic                   mem_write;
  logic [ADDR_WIDTH-1:0]  mem_addr;
  logic [DATA_WIDTH-1:0]  mem_wdata;
  logic [DATA_WIDTH-1:0]  mem_rdata;

  // Clocking block for synchronous signals with #1 delay for sample-and-hold
  clocking cb @(posedge clk);
    // Outputs driven by testbench, delayed by one delta cycle after posedge clk
    output #1 local_read, local_write, addr, wdata;
    output #1 busRd, busRdX, busUpgr;
    output #1 mem_read, mem_write, mem_addr, mem_wdata;

    // Inputs sampled by testbench, delayed by one delta cycle after posedge clk
    input  #1 rdata;
    input  #1 supplyData, invalidate, shared;
    input  #1 mem_rdata;
  endclocking

endinterface
