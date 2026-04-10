# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

**druidfi/tools** is a Makefile framework that provides unified `make` commands across Drupal, Symfony, and other
PHP/Node projects. The same command (e.g., `make build`, `make shell`) works whether the developer is inside Docker or
on the host — the framework detects the environment automatically.

## Repository Commands

```bash
make test          # Run test suite (requires Node.js v20)
make test-linux    # Run tests inside Docker Linux container
make release       # Create new release (bumps version, commits, pushes)
make debug         # Show detected environment and variables
```

Running tests directly:
```bash
tests/tests.sh     # Run all output comparison tests
```

## Architecture

### Framework Entry Point

Projects include the framework via their root `Makefile`:
```makefile
PHONY :=
PROJECT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))
-include .env
-include .env.local
include $(PROJECT_DIR)/tools/make/Makefile
-include $(PROJECT_DIR)/tools/make/project/*.mk
-include $(PROJECT_DIR)/tools/make/override.mk
.PHONY: $(PHONY)
```

### Make File Loading Chain

1. `make/Makefile` — sets core variables (`DRUIDFI_TOOLS_MAKE_DIR`, `PROJECT_DIR`, `WEBROOT`, `RUN_ON`, etc.)
2. `make/utils.mk` — helper macros (`step`, `warn`, `dbg`, `has`, colors)
3. `make/include.mk` — conditionally includes feature modules based on detection:
   - `docker.mk` — if `docker` binary exists
   - `drupal.mk` — if `$(WEBROOT)/sites/default/settings.php` exists
   - `symfony.mk` — if `config/bundles.php` exists
   - `ansible.mk` — if `ansible/` directory exists
   - `lagoon.mk` — if `.lagoon.yml` exists
   - `composer.mk` — if `composer.json` exists
   - `javascript.mk` — if `package.json` exists

### Variable Override Hierarchy

From lowest to highest precedence:
1. Defaults in `make/*.mk`
2. Auto-detection at runtime (Docker vs host, OS type)
3. `.env` / `.env.local` files in project root
4. `tools/make/override.mk` (project-specific overrides)

### Key Variables

| Variable | Purpose | Default |
|---|---|---|
| `RUN_ON` | `docker` or `host` — auto-detected | auto |
| `CLI_SERVICE` | Docker service for `make shell` | `app` |
| `DOCKER_PROJECT_ROOT` | Working dir inside container | `/app` |
| `WEBROOT` | Web root directory | `public` |
| `ENV` | Build environment | `dev` |
| `IS_DRUPAL` / `IS_SYMFONY` | Type detection flags | auto |

### PHONY Accumulator Pattern

Each `.mk` file appends to the `PHONY` variable instead of declaring `.PHONY` directly. The root `Makefile` declares `.PHONY: $(PHONY)` at the end. New targets must be added to `PHONY` within their `.mk` file:
```makefile
PHONY += my-new-target
my-new-target:
	@echo "doing something"
```

### BUILD_TARGETS / TEST_TARGETS / FIX_TARGETS

Composite targets like `make build`, `make test`, and `make fix` iterate over these accumulator variables. Add to them in feature `.mk` files to hook into the composite targets:
```makefile
BUILD_TARGETS += composer-install
TEST_TARGETS += test-phpunit
FIX_TARGETS += fix-drupal
```

## Test Framework

Tests compare `make -n` dry-run output to expected output files in `tests/outputs/`. Each test file format:
```
{make-target-name}
---
{expected output line 1}
{expected output line 2}
```

Placeholders replaced at test time: `__PWD__`, `__HOME__`, `__MAKE__`.

Tests run against `make/` directory: `make -n --no-print-directory --directory=make {target}`.

**Node.js v20 is required** to run tests.

## Adding or Changing Make Targets

When modifying `make/*.mk`:
1. Add the target name to `PHONY`
2. Add expected output file to `tests/outputs/` if the target has testable dry-run output
3. Run `make test` to verify all existing tests still pass
4. Update `make/Makefile.project.dist` if the project template needs updating

## Self-Update Mechanism

`update.sh` downloads the `make/` directory files from the GitHub release. Projects call `make self-update` which executes this script. When removing a `.mk` file from the framework, add its filename to the cleanup list in `update.sh` so it gets deleted from consumer projects.
