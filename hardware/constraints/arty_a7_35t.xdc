## ====================================================================
## Digilent Arty A7-35T Master Physical Constraints File (SYM-13)
## Board Variant: Artix-7 XC7A35TICSG324-1L
## ====================================================================

## 1. System Clock (100MHz Oscillator Pin)
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { s_axi_aclk }]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { s_axi_aclk }]

## 2. Global Reset Button (CPU Reset Button - Active Low)
set_property -dict { PACKAGE_PIN C2    IOSTANDARD LVCMOS33 } [get_ports { s_axi_aresetn }]

## 3. Physical Status LED (Single-Color LED 4 - Visual Fault Monitor)
set_property -dict { PACKAGE_PIN H5    IOSTANDARD LVCMOS33 } [get_ports { led_fault_active }]

## 4. Hardware Safety Interrupt Line (Mapped to PMOD Header JA, Pin 1)
## PMOD Port JA is a high-speed logic connector. Mapped to physical Pin G13.
set_property -dict { PACKAGE_PIN G13   IOSTANDARD LVCMOS33 } [get_ports { irq_veto }]
