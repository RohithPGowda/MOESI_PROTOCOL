# Cache Hierarchy Verification Project

This project contains a SystemVerilog-based simulation environment for a simple cache hierarchy with a MOESI-style L1 cache and a functional L2 stub. It includes a testbench, interface, generator, driver, monitor, scoreboard, and reference model to verify basic cache behavior.

## Overview

The design models:
- A top-level cache system with an L1 cache and L2 stub
- A MOESI controller for cache-state transitions
- A simple testbench that drives read/write transactions
- A verification environment with transaction-based checking

## Project Structure

- `design.sv` – DUT definition, including L1 cache, L2 stub, and MOESI controller
- `testbench.sv` – Top-level testbench instantiating the DUT and interface
- `interface.sv` – SystemVerilog interface for core and memory signals
- `test.sv` – Test program that starts the environment
- `env.sv` – Environment class that connects generator, driver, monitor, scoreboard, and reference model
- `generator.sv` – Generates random stimulus transactions
- `driver.sv` – Drives transactions into the DUT through the interface
- `monitor.sv` – Observes DUT activity and forwards results
- `scoreboard.sv` – Compares actual vs. expected results
- `reference_model.sv` – Implements a simple expected-behavior model
- `transaction.sv` – Transaction definition used across the environment
- `run.sh` – Script to compile and run the simulation with Xcelium

## Prerequisites

To run this project, you need:
- Xcelium or a compatible Cadence simulation tool
- A Unix-like shell environment
- Standard shell tools such as `zip`

## Running the Simulation

From the project root, run:

```bash
sh run.sh
```

This script executes:

```bash
xrun -Q -unbuffered -timescale 1ns/1ns -sysv -access +rw design.sv testbench.sv
```

## Expected Output

When the simulation executes successfully, you should see:
- Transaction generation messages
- Monitor output for read/write activity
- Scoreboard pass/fail messages
- The simulation finishing cleanly

## Notes

- The current L2 implementation is a functional stub rather than a full memory hierarchy.
- The reference model is intentionally simple and is meant for demonstration and basic verification.
- You may extend the design with a more realistic memory model or a fuller MOESI implementation.
