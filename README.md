# Sym-Chaos

**Status:** partial infrastructure and hardware scaffold  
**Production status:** not demonstrated  
**Operational authority:** none

Sym-Chaos currently contains a developer Makefile, GCP/Terraform infrastructure material, deployment scripts, and hardware/gateware material. It does **not** currently contain every application/package path referenced by the Makefile, so several convenience targets describe intended structure rather than a complete runnable stack.

## Present at the repository root

- `hardware/` — hardware README, constraints, and source
- `infra/gcp/` — Google Cloud infrastructure configuration
- `scripts/deploy-gcp-coldstart.sh` — deployment helper
- `scripts/dev.sh` — development helper
- `Makefile` — orchestration commands for development, tests, linting, Terraform, containers, and hardware lint

## Important boundary

The Makefile references paths such as `apps/api`, `apps/dashboard`, and `packages/*`. Their presence must be checked before treating commands that depend on them as available. A successful Terraform validation or Verilog lint would support only that bounded component, not the whole architecture.

Useful inspection commands:

```bash
make help
make hardware-lint
make terraform-init
make terraform-validate
```

Run only the targets whose prerequisites are actually present and configured.

## Evidence rule

```text
SCAFFOLD != DEPLOYMENT
CONFIGURATION != RUNNING SERVICE
HARDWARE SOURCE != SILICON VALIDATION
CLOUD PLAN != PRODUCTION AUTHORITY
```

This repository should remain classified as an implementation scaffold until the referenced application/runtime layers, tests, and CI are present and reproducible.

## Portfolio relationship

Sym-Chaos is a satellite research repository. It does not supersede the canonical portfolio evidence status maintained in `ryansctt1994-sudo/Weaver_Os`.

## License

MIT.
