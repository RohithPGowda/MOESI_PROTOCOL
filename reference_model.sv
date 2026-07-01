`include "transaction.sv"

class cache_reference_model;
  // Mailbox from generator/driver (receives stimulus)
  mailbox #(cache_transaction) in_mbox;
  // Mailbox to scoreboard (sends expected responses)
  mailbox #(cache_transaction) out_mbox;
  // Internal memory model (optional, for tracking written data)
  bit [31:0] mem[int];

  function new(mailbox #(cache_transaction) in_mbox, mailbox #(cache_transaction) out_mbox);
    this.in_mbox = in_mbox;
    this.out_mbox = out_mbox;
  endfunction

  task run();
    cache_transaction tr, exp_tr;
    forever begin
      in_mbox.get(tr); // Get stimulus from generator/driver

      // Display incoming transaction details
      $display("[%0t] Reference Model: Received transaction addr=0x%0h, %s, data=0x%0h",
               $time,
               tr.addr,
               tr.local_write ? "WRITE" : (tr.local_read ? "READ" : "OTHER"),
               tr.wdata);

      // Create expected transaction
      exp_tr = new();
      exp_tr.addr = tr.addr;
      exp_tr.local_read = tr.local_read;
      exp_tr.local_write = tr.local_write;

      // Predict expected data
      if (tr.local_write) begin
        // For WRITE: update memory and expect same data back on READ
        mem[tr.addr] = tr.wdata;
        exp_tr.wdata = tr.wdata;
        $display("[%0t] Reference Model: WRITE addr=0x%0h, updated mem=0x%0h",
                 $time, tr.addr, tr.wdata);
      end else if (tr.local_read) begin
        // For READ: expect data from memory (or 0xdeadbeef if not written)
        exp_tr.wdata = mem.exists(tr.addr) ? mem[tr.addr] : 32'hdeadbeef;
        $display("[%0t] Reference Model: READ addr=0x%0h, predicted data=0x%0h",
                 $time, tr.addr, exp_tr.wdata);
      end

      // Send expected transaction to scoreboard
      out_mbox.put(exp_tr);
      $display("[%0t] Reference Model: Sent expected transaction for addr=0x%0h, data=0x%0h",
               $time, exp_tr.addr, exp_tr.wdata);
    end
  endtask
endclass
