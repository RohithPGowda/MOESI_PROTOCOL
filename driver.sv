`include "transaction.sv"
class cache_driver;
  virtual cache_if vif;
  mailbox #(cache_transaction) mbox;

  function new(virtual cache_if vif, mailbox #(cache_transaction) mbox);
    this.vif  = vif;
    this.mbox = mbox;
  endfunction

  task run();
    cache_transaction tr;
    int i = 0;

    forever begin
      mbox.get(tr);

   

      vif.cb.local_read  <= tr.local_read;
      vif.cb.local_write <= tr.local_write;
      vif.cb.addr        <= tr.addr;
      vif.cb.wdata       <= tr.wdata;

      @(vif.cb);
      i++;

      vif.cb.local_read  <= 0;
      vif.cb.local_write <= 0;
    end
  endtask
endclass
