`include "transaction.sv"


class cache_generator;
  mailbox #(cache_transaction) mbox, gen2ref; // mbox: to driver; gen2ref: to reference model
  event transaction_sent;

  function new(mailbox #(cache_transaction) mbox, mailbox #(cache_transaction) gen2ref, event transaction_sent);
    this.mbox = mbox;
    this.gen2ref = gen2ref;
    this.transaction_sent = transaction_sent;
  endfunction

  task run();
    int i = 0;
    repeat (20) begin
      cache_transaction tr = new();
      if (!tr.randomize()) begin
        $display("Randomization failed for transaction %0d", i);
      end else begin
        $display("Generated transaction %0d: addr=0x%0h, local_read=%0b, local_write=%0b, busRd=%0b, busRdX=%0b, wdata=0x%0h",
                 i, tr.addr, tr.local_read, tr.local_write, tr.busRd, tr.busRdX, tr.wdata);
        mbox.put(tr);      // Send to driver
        gen2ref.put(tr);   // Send to reference model
        ->transaction_sent; // Signal transaction sent
      end
      i++;
    end
  endtask
endclass
