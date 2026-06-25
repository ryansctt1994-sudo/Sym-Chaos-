# SYM-13: GCOS-ZOREL Register Mapping

SYM-13 introduces the first hardware-facing boundary for ZOREL-717. The module wraps the deterministic veto FSM in a hand-coded AXI4-Lite slave peripheral suitable for integration with a soft-core processor on the Digilent Arty A7-35T.

## Target platform

- Board: Digilent Arty A7-35T
- FPGA: Artix-7 XC7A35TICSG324-1L
- Soft-core options: MicroBlaze, NEORV32, or equivalent RISC-V core
- Bus: AXI4-Lite slave peripheral

## Files

- `hardware/src/zorel_veto_axi.v`: AXI4-Lite ZOREL veto peripheral.
- `hardware/src/gcos_zorel_driver.c`: Bare-metal GCOS MMIO driver stub.
- `hardware/constraints/arty_a7_35t.xdc`: Physical board constraints for clock, reset, LED, and PMOD interrupt output.

## Register map

| Offset | Register | Access | Description |
| --- | --- | --- | --- |
| `0x00` | CSR | RW | Bit 0: `SYS_EN`, Bit 1: `ENG_BUSY`, Bit 2: `FAULT_ACTIVE` readback |
| `0x04` | VCR | RO | Monotonic violation counter from hardware-side veto assertions |
| `0x08` | MTR | RW | Manual trigger register. Bit 1 asserts a simulated veto. |
| `0x0C` | SRR | WO | Software reset register. Bit 0 clears active fault state. |

## Security boundary

The `irq_veto` line is asserted when `FAULT_ACTIVE && SYS_EN` is true. This lets the veto output bypass GCOS and directly drive physical safety interlocks or interrupt routing. The violation counter is not writable from the CPU bus, preserving a hardware-owned evidence channel even if GCOS is compromised.

## Local lint

Install either `verilator` or `iverilog`, then run:

```bash
make hardware-lint
```

This performs a syntax/lint pass on the Verilog source. Full board validation still requires Vivado synthesis, implementation, timing analysis, bitstream generation, and hardware smoke testing on the Arty A7-35T.
