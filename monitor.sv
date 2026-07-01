`include "transaction.sv"

class cache_monitor;
  virtual cache_if vif;
  mailbox #(cache_transaction) act_mbox;
  event transaction_sent;

  function new(virtual cache_if vif, mailbox #(cache_transaction) act_mbox, event transaction_sent = null);
    this.vif = vif;
    this.act_mbox = act_mbox;
    this.transaction_sent = transaction_sent;
  endfunction

  task run();
    cache_transaction tr;
    forever begin
      @(posedge vif.clk);
      if (vif.rst) begin
        $display("--------------------------------------------------");
        $display("[%0t] Monitor: Reset active", $time);
        $display("--------------------------------------------------");
      end else begin
        $display("--------------------------------------------------");
        if (vif.local_read || vif.local_write) begin
          $display("[%0t] Monitor: %s request - addr=0x%h, data=0x%h",
                  $time,
                  vif.local_read ? "READ" : "WRITE",
                  vif.addr,
                  vif.local_read ? vif.rdata : vif.wdata);
          // Capture transaction with correct data assignment
          tr = new();
          tr.addr = vif.addr;
          tr.local_read = vif.local_read;
          tr.local_write = vif.local_write;
          // Assign rdata or wdata to wdata in transaction (as in your setup)
          tr.wdata = vif.local_read ? vif.rdata : vif.wdata;
          act_mbox.put(tr);
        end else begin
          $display("[%0t] Monitor: No active operation", $time);
        end
        $display("--------------------------------------------------");
      end
    end
  endtask
endclass
