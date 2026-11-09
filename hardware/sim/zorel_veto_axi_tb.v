`timescale 1ns / 1ps
// Self-checking behavioural testbench for zorel_veto_axi.
// Run with: make hardware-sim
// Exercises the register map and the security-boundary properties stated in
// hardware/README.md. Passing this is RTL-simulation evidence only; it does
// not replace Vivado synthesis, timing closure, or on-board testing.

module zorel_veto_axi_tb;
    localparam [3:0] CSR = 4'h0, VCR = 4'h4, MTR = 4'h8, SRR = 4'hC;
    localparam [1:0] OKAY = 2'b00, SLVERR = 2'b10;

    reg         clk = 1'b0;
    reg         aresetn = 1'b0;
    reg  [3:0]  awaddr = 4'h0;
    reg         awvalid = 1'b0;
    wire        awready;
    reg  [31:0] wdata = 32'h0;
    reg  [3:0]  wstrb = 4'h0;
    reg         wvalid = 1'b0;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready = 1'b0;
    reg  [3:0]  araddr = 4'h0;
    reg         arvalid = 1'b0;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready = 1'b0;
    wire        irq_veto;
    wire        led_fault_active;

    integer failures = 0;
    integer checks = 0;
    reg [31:0] rd;
    reg [1:0]  resp;

    zorel_veto_axi dut (
        .s_axi_aclk(clk), .s_axi_aresetn(aresetn),
        .s_axi_awaddr(awaddr), .s_axi_awprot(3'b000), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
        .s_axi_wdata(wdata), .s_axi_wstrb(wstrb), .s_axi_wvalid(wvalid), .s_axi_wready(wready),
        .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
        .s_axi_araddr(araddr), .s_axi_arprot(3'b000), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
        .s_axi_rdata(rdata), .s_axi_rresp(rresp), .s_axi_rvalid(rvalid), .s_axi_rready(rready),
        .irq_veto(irq_veto), .led_fault_active(led_fault_active)
    );

    always #5 clk = ~clk;

    task check(input [31:0] got, input [31:0] want, input [8*48-1:0] what);
        begin
            checks = checks + 1;
            if (got !== want) begin
                failures = failures + 1;
                $display("FAIL %0s: got 0x%08h want 0x%08h", what, got, want);
            end else begin
                $display("ok   %0s = 0x%08h", what, got);
            end
        end
    endtask

    // AXI4-Lite write: address and data presented together, wait for response.
    task axi_write(input [3:0] addr, input [31:0] data, input [3:0] strb, output [1:0] r);
        integer t;
        begin
            @(negedge clk);
            awaddr = addr; awvalid = 1'b1; wdata = data; wstrb = strb; wvalid = 1'b1; bready = 1'b1;
            t = 0;
            while (!(awvalid == 1'b0 && wvalid == 1'b0 && bvalid) && t < 50) begin
                @(posedge clk); #1;
                if (awready) awvalid = 1'b0;
                if (wready)  wvalid  = 1'b0;
                t = t + 1;
            end
            if (t >= 50) begin failures = failures + 1; $display("FAIL write timeout @0x%h", addr); end
            r = bresp;
            @(posedge clk); #1;
            bready = 1'b0;
        end
    endtask

    task axi_read(input [3:0] addr, output [31:0] data);
        integer t;
        begin
            @(negedge clk);
            araddr = addr; arvalid = 1'b1; rready = 1'b1;
            t = 0;
            while (!(arvalid == 1'b0 && rvalid) && t < 50) begin
                @(posedge clk); #1;
                if (arready) arvalid = 1'b0;
                t = t + 1;
            end
            if (t >= 50) begin failures = failures + 1; $display("FAIL read timeout @0x%h", addr); end
            data = rdata;
            @(posedge clk); #1;
            rready = 1'b0;
        end
    endtask

    initial begin
        repeat (4) @(posedge clk);
        aresetn = 1'b1;
        repeat (2) @(posedge clk);

        // Reset state: SYS_EN=1, no fault, counter zero, interrupt low.
        axi_read(CSR, rd); check(rd, 32'h1, "reset CSR");
        axi_read(VCR, rd); check(rd, 32'h0, "reset VCR");
        check(irq_veto, 1'b0, "reset irq_veto");

        // MTR bit 0 alone must not raise a veto.
        axi_write(MTR, 32'h1, 4'hF, resp); check(resp, OKAY, "MTR=1 resp");
        check(led_fault_active, 1'b0, "MTR bit0 no fault");

        // MTR bit 1 raises the veto and increments the counter.
        axi_write(MTR, 32'h2, 4'hF, resp); check(resp, OKAY, "MTR=2 resp");
        check(irq_veto, 1'b1, "veto irq asserted");
        check(led_fault_active, 1'b1, "fault LED asserted");
        axi_read(CSR, rd); check(rd, 32'h5, "CSR fault+en");
        axi_read(VCR, rd); check(rd, 32'h1, "VCR after 1 veto");

        // VCR is read-only from the bus.
        axi_write(VCR, 32'h0, 4'hF, resp); check(resp, OKAY, "VCR write resp");
        axi_read(VCR, rd); check(rd, 32'h1, "VCR unchanged by write");

        // Partial strobes are rejected with SLVERR and change no state.
        axi_write(SRR, 32'h1, 4'h1, resp); check(resp, SLVERR, "partial strobe SLVERR");
        check(led_fault_active, 1'b1, "fault kept after SLVERR");

        // Clearing SYS_EN masks the interrupt but not the fault itself.
        axi_write(CSR, 32'h0, 4'hF, resp);
        check(irq_veto, 1'b0, "irq masked by SYS_EN=0");
        check(led_fault_active, 1'b1, "fault LED still on");
        axi_write(CSR, 32'h1, 4'hF, resp);
        check(irq_veto, 1'b1, "irq back with SYS_EN=1");

        // SRR clears the fault; the counter stays (monotonic evidence channel).
        axi_write(SRR, 32'h1, 4'hF, resp); check(resp, OKAY, "SRR resp");
        check(irq_veto, 1'b0, "irq cleared by SRR");
        axi_read(MTR, rd); check(rd, 32'h0, "trigger bits cleared");
        axi_read(VCR, rd); check(rd, 32'h1, "VCR survives SRR");

        // A second veto keeps counting.
        axi_write(MTR, 32'h2, 4'hF, resp);
        axi_read(VCR, rd); check(rd, 32'h2, "VCR after 2 vetoes");

        // Reserved/RO addresses read back as expected; SRR reads as zero.
        axi_read(SRR, rd); check(rd, 32'h0, "SRR reads zero");

        if (failures != 0) $fatal(1, "FAILED: %0d of %0d checks", failures, checks);
        $display("PASS: %0d checks", checks);
        $finish;
    end

    initial begin
        #100000;
        $fatal(1, "FAIL: global timeout");
    end
endmodule
