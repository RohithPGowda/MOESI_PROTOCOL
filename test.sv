`include "env.sv"

program test(cache_if vif);
  cache_environment env;

  initial begin
    env = new(vif);
    env.run();
    #100; // Wait for 1000 time units (adjust as needed)
    
    $finish;
  end
endprogram
