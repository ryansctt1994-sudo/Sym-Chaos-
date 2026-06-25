`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: High-Assurance AI Platforms Group
// Design Name: ZOREL-717
// Module Name: zorel_veto_axi
// Target Devices: Digilent Arty A7-35T (Artix-7 XC7A35TICSG324-1L)
// Description: Custom AXI4-Lite Slave peripheral implementing deterministic
//              hardware veto invariants for the Symchaos Engine.
//////////////////////////////////////////////////////////////////////////////////

module zorel_veto_axi #(
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    input  wire                              s_axi_aclk,
    input  wire                              s_axi_aresetn,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_awaddr,
    input  wire [2:0]                        s_axi_awprot,
    input  wire                              s_axi_awvalid,
    output reg                               s_axi_awready,

    input  wire [C_S_AXI_DATA_WIDTH-1:0]     s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                              s_axi_wvalid,
    output reg                               s_axi_wready,

    output reg  [1:0]                        s_axi_bresp,
    output reg                               s_axi_bvalid,
    input  wire                              s_axi_bready,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]     s_axi_araddr,
    input  wire [2:0]                        s_axi_arprot,
    input  wire                              s_axi_arvalid,
    output reg                               s_axi_arready,

    output reg  [C_S_AXI_DATA_WIDTH-1:0]     s_axi_rdata,
    output reg  [1:0]                        s_axi_rresp,
    output reg                               s_axi_rvalid,
    input  wire                              s_axi_rready,

    output wire                              irq_veto,
    output wire                              led_fault_active
);

    localparam [1:0] AXI_RESP_OKAY = 2'b00;
    localparam [1:0] AXI_RESP_SLVERR = 2'b10;

    reg        r_sys_en;
    reg        r_eng_busy;
    reg        r_fault_active;
    reg [31:0] r_violation_count;
    reg [1:0]  r_trigger_bit;

    assign irq_veto         = r_fault_active && r_sys_en;
    assign led_fault_active = r_fault_active;

    reg [C_S_AXI_ADDR_WIDTH-1:0] w_addr_latched;
    reg [C_S_AXI_DATA_WIDTH-1:0] w_data_latched;
    reg [(C_S_AXI_DATA_WIDTH/8)-1:0] w_strb_latched;
    reg w_addr_received;
    reg w_data_received;

    wire unsupported_write_strobe;
    assign unsupported_write_strobe = (w_strb_latched != {(C_S_AXI_DATA_WIDTH/8){1'b1}});

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready     <= 1'b0;
            s_axi_wready      <= 1'b0;
            s_axi_bvalid      <= 1'b0;
            s_axi_bresp       <= AXI_RESP_OKAY;
            w_addr_latched    <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            w_data_latched    <= {C_S_AXI_DATA_WIDTH{1'b0}};
            w_strb_latched    <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
            w_addr_received   <= 1'b0;
            w_data_received   <= 1'b0;

            r_sys_en          <= 1'b1;
            r_eng_busy        <= 1'b0;
            r_fault_active    <= 1'b0;
            r_violation_count <= 32'd0;
            r_trigger_bit     <= 2'b00;
        end else begin
            if (s_axi_awvalid && !s_axi_awready && !w_addr_received) begin
                s_axi_awready   <= 1'b1;
                w_addr_latched  <= s_axi_awaddr;
                w_addr_received <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end

            if (s_axi_wvalid && !s_axi_wready && !w_data_received) begin
                s_axi_wready    <= 1'b1;
                w_data_latched  <= s_axi_wdata;
                w_strb_latched  <= s_axi_wstrb;
                w_data_received <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
            end

            if (w_addr_received && w_data_received && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= unsupported_write_strobe ? AXI_RESP_SLVERR : AXI_RESP_OKAY;

                if (!unsupported_write_strobe) begin
                    case (w_addr_latched[3:2])
                        2'b00: begin
                            r_sys_en   <= w_data_latched[0];
                            r_eng_busy <= w_data_latched[1];
                        end
                        2'b01: begin
                            // VCR is read-only from the CPU bus.
                        end
                        2'b10: begin
                            r_trigger_bit <= w_data_latched[1:0];
                            if (w_data_latched[1] == 1'b1) begin
                                r_fault_active    <= 1'b1;
                                r_violation_count <= r_violation_count + 1'b1;
                            end
                        end
                        2'b11: begin
                            if (w_data_latched[0] == 1'b1) begin
                                r_fault_active <= 1'b0;
                                r_trigger_bit  <= 2'b00;
                            end
                        end
                    endcase
                end
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid    <= 1'b0;
                w_addr_received <= 1'b0;
                w_data_received <= 1'b0;
            end
        end
    end

    reg [C_S_AXI_ADDR_WIDTH-1:0] r_addr_latched;
    reg r_addr_received;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready   <= 1'b0;
            s_axi_rvalid    <= 1'b0;
            s_axi_rresp     <= AXI_RESP_OKAY;
            s_axi_rdata     <= 32'h00000000;
            r_addr_latched  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
            r_addr_received <= 1'b0;
        end else begin
            if (s_axi_arvalid && !s_axi_arready && !r_addr_received) begin
                s_axi_arready   <= 1'b1;
                r_addr_latched  <= s_axi_araddr;
                r_addr_received <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (r_addr_received && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= AXI_RESP_OKAY;

                case (r_addr_latched[3:2])
                    2'b00: s_axi_rdata <= {29'd0, r_fault_active, r_eng_busy, r_sys_en};
                    2'b01: s_axi_rdata <= r_violation_count;
                    2'b10: s_axi_rdata <= {30'd0, r_trigger_bit};
                    2'b11: s_axi_rdata <= 32'd0;
                    default: s_axi_rdata <= 32'hDEADBEEF;
                endcase
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid    <= 1'b0;
                r_addr_received <= 1'b0;
            end
        end
    end

endmodule
