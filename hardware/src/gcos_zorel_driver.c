/**
 * @file gcos_zorel_driver.c
 * @brief Bare-metal MMIO driver for the ZOREL-717 hardware security module.
 *
 * Implements high-assurance interface logic to prevent runtime state corruption.
 */

#include <stdbool.h>
#include <stdint.h>

#ifndef ZOREL_BASE_ADDR
#define ZOREL_BASE_ADDR 0x43C00000u
#endif

#define ZOREL_REG_CSR 0u
#define ZOREL_REG_VCR 1u
#define ZOREL_REG_MTR 2u
#define ZOREL_REG_SRR 3u

#define ZOREL_CSR_SYS_EN_MASK      0x01u
#define ZOREL_CSR_ENG_BUSY_MASK    0x02u
#define ZOREL_CSR_FAULT_ACTIVE_MASK 0x04u

#define zorel_write_reg(reg, val) (*((volatile uint32_t *)(ZOREL_BASE_ADDR + ((reg) * 4u))) = (uint32_t)(val))
#define zorel_read_reg(reg)       (*((volatile uint32_t *)(ZOREL_BASE_ADDR + ((reg) * 4u))))

bool zorel_is_fault_active(void) {
    uint32_t csr = zorel_read_reg(ZOREL_REG_CSR);
    return (csr & ZOREL_CSR_FAULT_ACTIVE_MASK) != 0u;
}

void zorel_set_engine_busy(bool busy) {
    uint32_t current_csr = zorel_read_reg(ZOREL_REG_CSR);

    if (busy) {
        current_csr |= ZOREL_CSR_ENG_BUSY_MASK;
    } else {
        current_csr &= ~ZOREL_CSR_ENG_BUSY_MASK;
    }

    zorel_write_reg(ZOREL_REG_CSR, current_csr);
}

uint32_t zorel_get_violation_count(void) {
    return zorel_read_reg(ZOREL_REG_VCR);
}

void zorel_assert_manual_veto(void) {
    zorel_write_reg(ZOREL_REG_MTR, 0x02u);
}

void zorel_clear_faults(void) {
    zorel_write_reg(ZOREL_REG_SRR, 0x01u);
}
