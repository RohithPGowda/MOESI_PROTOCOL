//------------------------------------------------------------------------------
// Single-Core Cache Hierarchy: L1 (MOESI) & L2 Stub (Fully Functional)
// Verilog-2001, 32-bit data, 15-bit address, 1024-entry direct-mapped cache
//------------------------------------------------------------------------------

module top_cache_system #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 15,
    parameter CACHE_DEPTH = 1024
)(
    input  wire                   clk,
    input  wire                   rst,
    // Core interface
    input  wire                   core_read,
    input  wire                   core_write,
    input  wire [ADDR_WIDTH-1:0]  core_addr,
    input  wire [DATA_WIDTH-1:0]  core_wdata,
    output wire [DATA_WIDTH-1:0]  core_rdata,
    // Memory interface
    output wire                   mem_read,
    output wire                   mem_write,
    output wire [ADDR_WIDTH-1:0]  mem_addr,
    output wire [DATA_WIDTH-1:0]  mem_wdata,
    input  wire [DATA_WIDTH-1:0]  mem_rdata
);

    // Signals between L1 and L2
    wire        busRd, busRdX;
    wire        supplyL2;
    wire        invalidateL2;
    wire [DATA_WIDTH-1:0] l2_data_to_l1;

    // L1 instance
    wire [DATA_WIDTH-1:0] l1_rdata_out;
    l1_moesi #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .CACHE_DEPTH(CACHE_DEPTH)
    ) L1 (
        .clk        (clk),
        .rst        (rst),
        // Core side
        .local_read (core_read),
        .local_write(core_write),
        .addr_in    (core_addr),
        .wdata_in   (core_wdata),
        .rdata_out  (l1_rdata_out),
        // L2 side
        .busRd      (busRd),
        .busRdX     (busRdX),
        .shared     (supplyL2),
        .supplyData (supplyL2),
        .invalidate (invalidateL2),
        .l2_data    (l2_data_to_l1)
    );

    assign core_rdata = l1_rdata_out;

    // L2 instance (functional stub)
    l2_stub #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) L2 (
        .clk        (clk),
        .rst        (rst),
        .busRd_in   (busRd),
        .busRdX_in  (busRdX),
        .addr_in    (core_addr),
        .supplyData (supplyL2),
        .invalidate (invalidateL2),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .mem_addr   (mem_addr),
        .mem_wdata  (mem_wdata),
        .mem_rdata  (mem_rdata),
        .l2_data    (l2_data_to_l1)
    );

endmodule

//------------------------------------------------------------------------------
// L1 Cache: MOESI protocol + functional data array
//------------------------------------------------------------------------------
module l1_moesi #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 15,
    parameter CACHE_DEPTH = 1024
)(
    input  wire                   clk,
    input  wire                   rst,
    // Core side
    input  wire                   local_read,
    input  wire                   local_write,
    input  wire [ADDR_WIDTH-1:0]  addr_in,
    input  wire [DATA_WIDTH-1:0]  wdata_in,
    output reg  [DATA_WIDTH-1:0]  rdata_out,
    // L2 side
    output reg                    busRd,
    output reg                    busRdX,
    input  wire                   shared,
    input  wire                   supplyData,
    input  wire                   invalidate,
    input  wire [DATA_WIDTH-1:0]  l2_data
);

    // Cache storage
    reg [DATA_WIDTH-1:0] cache_data [0:CACHE_DEPTH-1];
    reg [ADDR_WIDTH-1:0] cache_tags [0:CACHE_DEPTH-1];
    reg [2:0]            cache_state[0:CACHE_DEPTH-1]; // MOESI state
    reg                  cache_valid[0:CACHE_DEPTH-1];
    wire [9:0] index = addr_in[9:0]; // 1024-entry cache

    // MOESI states
    localparam I = 3'd0, S = 3'd1, O = 3'd2, E = 3'd3, M = 3'd4;

    // State machine
    wire [2:0] next_state;
    wire issueBusRd, issueBusRdX, issueBusUpgr, doSupply, doInvalidate;

    moesi_controller ctrl(
        .local_read(local_read),
        .local_write(local_write),
        .busRd(1'b0), // Single-core, so no snoop
        .busRdX(1'b0),
        .busUpgr(1'b0),
        .shared(shared),
        .state(cache_state[index]),
        .next_state(next_state),
        .issueBusRd(issueBusRd),
        .issueBusRdX(issueBusRdX),
        .issueBusUpgr(issueBusUpgr),
        .supplyData(doSupply),
        .invalidate(doInvalidate)
    );

    // Bus signals
    always @(posedge clk) begin
        if (rst) begin
            busRd  <= 0;
            busRdX <= 0;
            rdata_out <= 0;
            for (int i = 0; i < CACHE_DEPTH; i = i + 1) begin
                cache_valid[i] <= 0;
                cache_tags[i]  <= 0;
                cache_data[i]  <= 0;
                cache_state[i] <= I;
            end
        end else begin
            busRd  <= issueBusRd;
            busRdX <= issueBusRdX;

            // State update
            cache_state[index] <= next_state;

            // Data and tag handling
            if (local_write) begin
                cache_data[index] <= wdata_in;
                cache_tags[index] <= addr_in;
                cache_valid[index] <= 1'b1;
            end

            // Read operation
            if (local_read) begin
                if (cache_valid[index] && cache_tags[index] == addr_in) begin
                    rdata_out <= cache_data[index]; // Read hit
                end else begin
                    rdata_out <= 32'hdeadbeef; // Read miss; will be updated by L2
                end
            end

            // On supplyData from L2, update cache and output
            if (supplyData) begin
                cache_data[index] <= l2_data;
                cache_tags[index] <= addr_in;
                cache_valid[index] <= 1'b1;
                rdata_out <= l2_data;
            end

            // On invalidate, mark as invalid
            if (invalidate) begin
                cache_valid[index] <= 1'b0;
            end
        end
    end
endmodule

//------------------------------------------------------------------------------
// L2 Stub: Memory controller, returns data for each address
//------------------------------------------------------------------------------
module l2_stub #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 15
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   busRd_in,
    input  wire                   busRdX_in,
    input  wire [ADDR_WIDTH-1:0]  addr_in,
    output reg                    supplyData,
    output reg                    invalidate,
    output reg                    mem_read,
    output reg                    mem_write,
    output reg  [ADDR_WIDTH-1:0]  mem_addr,
    output reg  [DATA_WIDTH-1:0]  mem_wdata,
    input  wire [DATA_WIDTH-1:0]  mem_rdata,
    output reg  [DATA_WIDTH-1:0]  l2_data
);
    // Memory model: returns data for each address (for demo, use mem_rdata)
    always @(posedge clk) begin
        if (rst) begin
            supplyData <= 0;
            invalidate <= 0;
            mem_read   <= 0;
            mem_write  <= 0;
            mem_addr   <= 0;
            mem_wdata  <= 0;
            l2_data    <= 0;
        end else begin
            supplyData <= 0;
            invalidate <= 0;
            mem_read   <= 0;
            mem_write  <= 0;
            mem_addr   <= addr_in;
            // For demo, use mem_rdata as returned data (you can replace with your own memory model)
            l2_data    <= mem_rdata;
            if (busRd_in) begin
                mem_read   <= 1;
                supplyData <= 1;
            end else if (busRdX_in) begin
                mem_read   <= 1;
                supplyData <= 1;
                invalidate <= 1;
            end
        end
    end
endmodule

//------------------------------------------------------------------------------
// MOESI Controller: State machine for MOESI protocol
//------------------------------------------------------------------------------
module moesi_controller(
    input  wire        local_read,
    input  wire        local_write,
    input  wire        busRd,
    input  wire        busRdX,
    input  wire        busUpgr,
    input  wire        shared,
    input  wire [2:0]  state,
    output reg [2:0]   next_state,
    output reg         issueBusRd,
    output reg         issueBusRdX,
    output reg         issueBusUpgr,
    output reg         supplyData,
    output reg         invalidate
);
    localparam I=3'd0, S=3'd1, O=3'd2, E=3'd3, M=3'd4;

    always @(*) begin
        next_state   = state;
        issueBusRd   = 0;
        issueBusRdX  = 0;
        issueBusUpgr = 0;
        supplyData   = 0;
        invalidate   = 0;

        case(state)
            I: begin
                if (local_read) begin
                    issueBusRd = 1;
                    next_state = shared ? S : E;
                end
                if (local_write) begin
                    issueBusRdX = 1;
                    next_state = M;
                end
            end
            S: begin
                if (local_read || busRd) next_state = S;
                if (local_write) begin
                    issueBusUpgr = 1;
                    next_state = M;
                end
                if (busRdX || busUpgr) begin
                    invalidate = 1;
                    next_state = I;
                end
            end
            E: begin
                if (local_read) next_state = E;
                if (local_write) next_state = M;
                if (busRd) next_state = S;
                if (busRdX || busUpgr) begin
                    invalidate = 1;
                    next_state = I;
                end
            end
            M: begin
                if (local_read || local_write) next_state = M;
                if (busRd) begin
                    supplyData = 1;
                    next_state = O;
                end
                if (busRdX || busUpgr) begin
                    invalidate = 1;
                    next_state = I;
                end
            end
            O: begin
                if (local_read) next_state = O;
                if (local_write) begin
                    issueBusUpgr = 1;
                    next_state = M;
                end
                if (busRd) next_state = S;
                if (busRdX || busUpgr) begin
                    invalidate = 1;
                    next_state = I;
                end
            end
        endcase
    end
endmodule
