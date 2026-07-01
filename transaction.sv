`ifndef TRANSACTION_SV
`define TRANSACTION_SV

class cache_transaction;
  // Randomizable inputs (stimulus)
  rand bit [14:0] addr;          // Address (15-bit)
  rand bit        local_read;    // Core read request
  rand bit        local_write;   // Core write request
  rand bit        busRd;         // Bus read signal
  rand bit        busRdX;        // Bus read exclusive
  rand bit        busUpgr;       // Bus upgrade

  // Data associated with write requests
  rand bit [31:0] wdata;         // Write data

  // Outputs / Flags from protocol FSM
  bit            supplyData;    // Supply data flag
  bit            invalidate;    // Invalidate flag
  bit            shared;        // Shared line indicator

  // Constructor
  function new();
    addr       = 0;
    local_read = 0;
    local_write= 0;
    busRd      = 0;
    busRdX     = 0;
    busUpgr    = 0;
    wdata      = 0;
    supplyData = 0;
    invalidate = 0;
    shared     = 0;
  endfunction

  // Constraint to prevent both read and write from being 1 at the same time
 /* constraint read_write_exclusive {
    !(local_read && local_write);
  }*/

endclass

`endif
