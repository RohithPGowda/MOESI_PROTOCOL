class cache_scoreboard;
  mailbox #(cache_transaction) act_mbox, exp_mbox;
  cache_transaction exp_tr_queue[int]; // key = addr
  cache_transaction act_tr_queue[int]; // key = addr

  function new(mailbox #(cache_transaction) act_mbox, mailbox #(cache_transaction) exp_mbox);
    this.act_mbox = act_mbox;
    this.exp_mbox = exp_mbox;
  endfunction

  task run();
    cache_transaction tr;
    forever begin
      if (act_mbox.try_get(tr)) begin
        $display("[%0t] SCOREBOARD: Got actual transaction for addr=0x%0h", $time, tr.addr);
        if (exp_tr_queue.exists(tr.addr)) begin
          if (exp_tr_queue[tr.addr].wdata !== tr.wdata) begin
            $display("[%0t] SCOREBOARD ERROR: Mismatch detected at addr=0x%0h", $time, tr.addr);
            $display("  Expected: addr=0x%0h, wdata=0x%0h", exp_tr_queue[tr.addr].addr, exp_tr_queue[tr.addr].wdata);
            $display("  Actual:   addr=0x%0h, wdata=0x%0h", tr.addr, tr.wdata);
          end else begin
            $display("[%0t] SCOREBOARD PASS: Transaction matched at addr=0x%0h", $time, tr.addr);
          end
          exp_tr_queue.delete(tr.addr);
        end else begin
          act_tr_queue[tr.addr] = tr;
        end
      end
      if (exp_mbox.try_get(tr)) begin
        $display("[%0t] SCOREBOARD: Got expected transaction for addr=0x%0h", $time, tr.addr);
        if (act_tr_queue.exists(tr.addr)) begin
          if (tr.wdata !== act_tr_queue[tr.addr].wdata) begin
            $display("[%0t] SCOREBOARD ERROR: Mismatch detected at addr=0x%0h", $time, tr.addr);
            $display("  Expected: addr=0x%0h, wdata=0x%0h", tr.addr, tr.wdata);
            $display("  Actual:   addr=0x%0h, wdata=0x%0h", act_tr_queue[tr.addr].addr, act_tr_queue[tr.addr].wdata);
          end else begin
            $display("[%0t] SCOREBOARD PASS: Transaction matched at addr=0x%0h", $time, tr.addr);
          end
          act_tr_queue.delete(tr.addr);
        end else begin
          exp_tr_queue[tr.addr] = tr;
        end
      end
      #1; // Small delay to avoid tight loop
    end
  endtask
endclass
