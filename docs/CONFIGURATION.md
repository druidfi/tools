# Configuration, overriding, and extending

This document explains how a consuming project customizes druidfi/tools:
variables, auto-detection, project-specific make files, and overrides.

## How the framework loads

A project's root `Makefile` (from [`Makefile.project.dist`](../make/Makefile.project.dist))
loads things in this order:

```makefile
PHONY :=
PROJECT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

-include .env                                          # 1. project env vars
-include .env.local                                     # 2. local overrides of env vars

include $(PROJECT_DIR)/tools/make/Makefile              # 3. the framework itself

-include $(PROJECT_DIR)/tools/make/project/*.mk         # 4. project-specific targets
-include $(PROJECT_DIR)/tools/make/override.mk          # 5. project-specific variable overrides

.PHONY: $(PHONY)
```

Later steps win. This gives four ways to customize behavior, from lightest to
heaviest:

1. **`.env` / `.env.local`** — plain `KEY=value` pairs, e.g. `WEBROOT=web`. `.env.local` is meant to be gitignored, for machine-local values.
2. **`tools/make/override.mk`** — override any variable the framework or its feature files set (see below).
3. **`tools/make/project/*.mk`** — add wholly new targets, or hook into existing composite targets (`BUILD_TARGETS`, `TEST_TARGETS`, etc).
4. **A project-specific root `CLAUDE.md`** — not a runtime mechanism, but where you document *why* 1–3 were used, per the harmonization guidance in the monorepo root `CLAUDE.md`.

## Auto-detection & conditional loading

`make/include.mk` decides which feature `.mk` files to load by testing for
files/binaries in the project — no manual configuration needed in the common
case:

| Feature file | Loaded when |
|---|---|
| `docker.mk` | `docker` binary is on `PATH` |
| `drupal.mk` | `$(WEBROOT)/sites/default/settings.php` exists |
| `symfony.mk` | `config/bundles.php` exists |
| `ansible.mk` | `ansible/` directory exists |
| `druid_cloud.mk` | `compose.live.yaml` exists |
| `lagoon.mk` | `.lagoon.yml` exists (checked only if `compose.live.yaml` is absent) |
| `composer.mk` | `composer.json` exists |
| `javascript.mk` | `package.json` exists |
| `qa.mk` | always |
| `kubectl.mk` | **never automatic** — must be included explicitly, see [COMMANDS.md](COMMANDS.md#kubernetes-makekubectlmk-opt-in--not-auto-loaded) |

`RUN_ON` (`docker` vs `host`) is similarly auto-detected in `docker.mk`: `docker`
when a `compose.yaml` exists and you're not already running inside a container
(`/.dockerenv` present), `host` otherwise. Every wrapped tool call (`drush`,
`composer`, `bin/console`, php-cs-fixer, phpcs) branches on `RUN_ON` so the same
`make` target works both inside and outside the container.

Any of the detection variables (`IS_DRUPAL`, `IS_SYMFONY`, `HAS_ANSIBLE`,
`DRUID_CLOUD`, `LAGOON`, `COMPOSER_JSON_EXISTS`, `PACKAGE_JSON_EXISTS`) can be
force-set to `yes`/`no` in `.env`, `.env.local`, or `override.mk` to bypass
detection.

Run `make debug` to print the resolved values for the current project.

## Key variables

### Core (`make/Makefile`, `make/common.mk`)

| Variable | Default | Purpose |
|---|---|---|
| `RUN_ON` | auto | `docker` or `host` |
| `WEBROOT` | `public` | Web root directory |
| `COMPOSER_JSON_PATH` | `.` | Where `composer.json` lives |
| `PACKAGE_JSON_PATH` | `.` | Where `package.json` lives |
| `PROJECT` | `myproject` | Project identifier, used in remote build lookups |
| `DUMP_SQL_FILENAME` | `dump.sql` | Local DB dump filename |
| `CLEAN_EXCLUDE` | `.idea $(DUMP_SQL_FILENAME) .env.local` | Paths `make clean` should not remove |
| `SSH_OPTS` | lenient SSH options | Used by `shell-<name>` and Druid Cloud deploy targets |
| `UPDATE_SCRIPT_URL` | druidfi/tools `update.sh` | Where `make self-update` pulls from |

### Docker (`make/docker.mk`)

| Variable | Default | Purpose |
|---|---|---|
| `CLI_SERVICE` | `app` (`cli` under Lagoon) | Compose service used for `make shell` and all wrapped tool calls |
| `CLI_SHELL` | `sh` (`bash` under Lagoon) | Shell to exec into |
| `CLI_USER` | unset | Container user for exec'd commands, e.g. `druid` |
| `DOCKER_PROJECT_ROOT` | `/app` | Working directory inside the container |
| `DOCKER_COMPOSE_YML_PATH` | `compose.yaml` | Compose file path |

### Drupal (`make/drupal.mk`)

| Variable | Default | Purpose |
|---|---|---|
| `DRUPAL_PROFILE` | `minimal` | Install profile used by `drush-si` when no exported config exists |
| `DRUPAL_SITE_EMAIL` | `maintenance@druid.fi` | Site mail during install |
| `DRUPAL_SYNC_SOURCE` | `main` | Drush alias to sync DB/files from |
| `SYNC_FROM_REMOTE` | `no` (`yes` under Lagoon) | Whether `drush-sync-db`/`-files` pull from `DRUPAL_SYNC_SOURCE` when no local dump exists |
| `DRUPAL_SYNC_FILES` | `no` | Whether to sync public files at all |
| `DRUPAL_ENABLE_MODULES` / `DRUPAL_DISABLE_MODULES` | `no` | Space-separated module machine names |
| `DRUPAL_UID` / `DRUPAL_DESTINATION` | empty / `admin/reports/status` | Options for `drush-uli` |
| `GH_DUMP_ARTIFACT` | unset | Set `yes` to prepend `gh-download-dump` to `make fresh` |
| `DRUPAL_THEME_NAME` | first dir under `$(WEBROOT)/themes/custom` | Theme built by `drupal-build-theme`/`-watch-theme` |
| `DRUSH_RSYNC_MODE`, `DRUSH_RSYNC_OPTS`, `DRUSH_RSYNC_EXCLUDE` | see file | Passed to `drush rsync` for file sync |

### Symfony (`make/symfony.mk`)

| Variable | Purpose |
|---|---|
| `APP_HOST` | URL printed by `make sf-open` |

### JavaScript (`make/javascript.mk`)

| Variable | Default | Purpose |
|---|---|---|
| `JS_PACKAGE_MANAGER` | `pnpm` | `npm`, `yarn`, or `pnpm` |
| `NODE_VERSION` | `24` | Version installed/used when falling back to NVM |
| `NODE_MANAGER` | auto (`volta` if installed, else `nvm`, else `none`) | Override to force one |

### QA (`make/qa.mk`)

> Total refactor planned for this file — see [TODO.md](TODO.md#planned-qa-total-refactor).
> Variables below describe current behavior, subject to change.

| Variable | Default | Purpose |
|---|---|---|
| `TESTSUITES` | `unit,kernel,functional` | PHPUnit `--testsuite` value |
| `CS_STANDARDS` | `Drupal,DrupalPractice` | phpcs standards when no `phpcs.xml.dist` is present |

### Ansible (`make/ansible.mk`)

| Variable | Default | Purpose |
|---|---|---|
| `ANSIBLE_PROVISION` | `ansible/provision.yml` | Playbook run by `provision*` targets |
| `ANSIBLE_REQUIREMENTS` | `ansible/requirements.yml` | Role requirements file |
| `ANSIBLE_ROLES_PATH` | `ansible/roles` | Where roles install to |
| `ANSIBLE_FLAGS` | empty | Extra flags appended to every `ansible-playbook` call |

### Druid Cloud (`make/druid_cloud.mk`)

| Variable | Default | Purpose |
|---|---|---|
| `SSH_USER` | `deployment` | SSH user for deploy/shell targets |
| `SSH_TESTING`, `SSH_STAGING`, `SSH_PRODUCTION` | `*.host` placeholders | **Must be overridden per project** |

### Lagoon (`make/lagoon.mk`)

| Variable | Purpose |
|---|---|
| `LAGOON_PROJECT` | Lagoon project name used by `lagoon` CLI calls |
| `LAGOON_SECRETS` | Space-separated list of variable names to push with `set-lagoon-secrets-<env>` (values read from `.env.local.lagoon`) |
| `INSTANCE_prod_*`, `INSTANCE_test_*` | Host/user/opts for `shell-<name>` |

### Kubernetes (`make/kubectl.mk`, opt-in)

| Variable | Default | Purpose |
|---|---|---|
| `KUBECTL_NAMESPACE` | `foobar-namespace` | **Must be overridden** |
| `KUBECTL_POD_SELECTOR` | `appName=foobar-app` | **Must be overridden** |
| `SYNC_FILES_PATH`, `SYNC_FILES_EXCLUDE` | unset | Used by the file-sync targets |

## Overriding variables

Put overrides in `tools/make/override.mk` (loaded last, so it wins over
everything else in the framework):

```makefile
# tools/make/override.mk
CLI_SERVICE := app
CLI_USER := druid
DOCKER_PROJECT_ROOT := /app
DRUPAL_SYNC_FILES := yes
KUBECTL_NAMESPACE := my-project-prod
```

For values that differ per developer machine rather than per project, prefer
`.env.local` (gitignored) instead — e.g. a personal `GH_REPO` default.

## Extending with project-specific make files

Drop new `.mk` files into `tools/make/project/`; every file matching
`tools/make/project/*.mk` is included automatically. Use this to:

**Add new targets:**

```makefile
# tools/make/project/deploy.mk
PHONY += deploy-preview
deploy-preview: ## Deploy a preview environment
	@echo "deploying preview..."
```

Remember to append any new target name to `PHONY` in the same file — the root
`Makefile` declares `.PHONY: $(PHONY)` once, after all includes.

**Hook into a composite target** by appending to its accumulator variable
(see [COMMANDS.md](COMMANDS.md#meta-targets-built-from-accumulators) for the
full list: `BUILD_TARGETS`, `TEST_TARGETS`, `LINT_PHP_TARGETS`, `FIX_TARGETS`,
`SYNC_TARGETS`):

```makefile
# tools/make/project/deploy.mk
BUILD_TARGETS += drupal-build-theme
```

**Opt in to a non-auto-loaded feature file**, e.g. `kubectl.mk`:

```makefile
# tools/make/project/kubectl.mk
include $(PROJECT_DIR)/tools/make/kubectl.mk
```

## Updating the framework

```console
make self-update
```

Runs [`update.sh`](../update.sh), which re-downloads every file listed in its
`files` array from `druidfi/tools` on the `main` branch, overwriting your local
copies under `tools/make/`. It also deletes any files listed in `remove_files`
(legacy files that no longer belong). It does **not** touch
`tools/make/project/*.mk` or `tools/make/override.mk` — those are yours.

If you're pinned to a branch/tag other than `main`, pass `-b`:

```console
bash update.sh -b some-branch
```
