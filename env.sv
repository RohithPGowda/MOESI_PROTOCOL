`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
`include "scoreboard.sv"
`include "transaction.sv"
`include "reference_model.sv"

class cache_environment;
  cache_generator        gen;
  cache_driver           drv;
  cache_monitor          mon;
  cache_scoreboard       scb;
  cache_reference_model  ref_model; // Reference model instance

  // Mailboxes for communication
  mailbox #(cache_transaction) mbox;      // Generator to Driver
  mailbox #(cache_transaction) gen2ref;   // Generator to Reference Model
  mailbox #(cache_transaction) act_mbox;  // Monitor to Scoreboard
  mailbox #(cache_transaction) exp_mbox;  // Reference Model to Scoreboard

  event transaction_sent;
  virtual cache_if vif;

  function new(virtual cache_if vif);
    this.vif = vif;
    mbox     = new();
    gen2ref  = new();
    act_mbox = new();
    exp_mbox = new();

    // Instantiate components with correct mailboxes
    gen      = new(mbox, gen2ref, transaction_sent); // Generator sends to Driver and Reference Model
    drv      = new(vif, mbox);
    mon      = new(vif, act_mbox, transaction_sent);
    ref_model= new(gen2ref, exp_mbox);               // Reference Model receives from Generator, sends to Scoreboard
    scb      = new(act_mbox, exp_mbox);              // Scoreboard receives from Monitor and Reference Model
  endfunction

  task run();
    fork
      gen.run();      // Generate transactions
      drv.run();      // Drive transactions to DUT
      mon.run();      // Monitor DUT responses
      ref_model.run();// Run reference model
      scb.run();      // Compare expected vs. actual
    join_none
  endtask
endclass
