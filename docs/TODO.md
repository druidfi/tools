# TODO / future improvements

Living list of known bugs, inconsistencies, and refactoring ideas found while
working on this framework. Not prioritized against a roadmap — pick up
whatever's relevant when touching that area.

## Planned: drop `RUN_ON` / host-execution support

Commands are meant to run outside the app container only. `RUN_ON`
(host-vs-docker dual-path execution) earns its weight nowhere near what it
costs in lines/branches across the framework. Replace it with one check: are
we inside the container right now? If yes, print
`Run these commands outside Docker container` and stop. If no, always exec
into the container — no more "host" branch.

**Touch points** (every `ifeq ($(RUN_ON),docker)` / host-else pair):

- `make/Makefile` — drop `RUN_ON := host` default var.
- `make/docker.mk`:
  - Remove `RUN_ON` autodetection block (`DOCKER_ENV` sets `RUN_ON`,
    `DOCKER_COMPOSE_YML_EXISTS` sets `RUN_ON`). Keep `DOCKER_ENV` itself
    (`test -f /.dockerenv`) — it's the one check we keep.
  - `shell` target: replace the `ifeq ($(RUN_ON),docker)` / else-warn pair
    with `ifeq ($(DOCKER_ENV),yes)` → warn + stop, else exec.
  - `docker_compose_exec` macro: same collapse — single definition, guarded
    by `DOCKER_ENV`, no host fallback branch (drop the `@$(1) && echo $(2)`
    direct-execution branch entirely).
  - `docker_compose` macro: same collapse for `up`/`down`/`ps`/`stop`/`pull`/
    `config`.
  - `docker` macro (lines ~62-69): dead code already — grepped, nothing
    calls `$(call docker,...)` anywhere in the framework. Delete outright,
    don't bother collapsing it.
- `make/composer.mk` — `composer` macro: drop the `ifeq ($(RUN_ON),docker)`
  branch, keep only the `docker_compose_exec` version.
- `make/drupal.mk` — `drush` macro: same collapse.
- `make/symfony.mk` — `sf_console` macro: same collapse.
- `make/qa.mk` — `cs` and `test-phpunit` already call `docker_compose_exec`
  unconditionally (no `RUN_ON` branch of their own) — no change needed there
  beyond whatever `docker_compose_exec` becomes.

**Net result:** one variable removed (`RUN_ON`), one message
(`Run these commands outside Docker container`) instead of scattered
`$(DOCKER_WARNING_INSIDE)` / silent host-exec branches, and every wrapped
macro (`composer`, `drush`, `sf_console`, `docker_compose_exec`,
`docker_compose`) drops from two `ifeq` branches to one unconditional body.
`docs/CONFIGURATION.md` and `docs/COMMANDS.md` need the `RUN_ON` references
removed once this lands.

**Watch for:** `make/qa.mk`'s `test-phpunit` branches on `CI=true` to run
`vendor/bin/phpunit` directly on the runner instead of through Docker — that
stays as-is, it's a separate concern from `RUN_ON` (CI runners aren't "inside
the app container" in the sense this refactor cares about).

## Planned: QA total refactor

`make/qa.mk` (`lint`, `lint-php`, `lint-js`, `fix`, `test`, `test-phpunit`,
`test-phpunit-locally`, the `cs`/`test_result` macros) needs a ground-up
rework — no detailed shape yet, flagging it so nobody invests in the current
structure. Related known issues to fold in when this starts: the `lint-js`
wrong-variable bug and `test-phpunit-locally` `PHONY`/help gaps listed below,
plus whatever falls out of the `RUN_ON` removal above (`cs` and `test-phpunit`
both call `docker_compose_exec`).

## Planned: drop common `shell-%` in favor of hosting-specific shell targets

`make/common.mk` carries a generic `shell-%` pattern target (`OPTS`/`USER`/
`HOST`/`EXTRA` pulled from `INSTANCE_$*_OPTS`/`_USER`/`_HOST`/`_EXTRA`) plus
the shared `SSH_OPTS` default, meant as a hosting-agnostic "shell into a named
remote instance" primitive. In practice only `lagoon.mk` feeds it
(`INSTANCE_prod_*`, `INSTANCE_test_*` → `make shell-prod`, `make shell-test`).
`druid_cloud.mk` never uses it — it already defines its own concrete
`shell-testing`/`shell-staging`/`shell-production` targets via a private
`--shell-remote` target and `SSH_USER`/`SSH_TESTING`/`SSH_STAGING`/
`SSH_PRODUCTION`. Two mechanisms doing the same job, one of them abstracted
for a single caller — collapse to one per hosting system.

**Plan:**

- `make/common.mk` — delete the `shell-%` pattern target. Decide whether
  `SSH_OPTS` moves to `lagoon.mk` (its only real consumer) or gets dropped in
  favor of Lagoon defining its own SSH flags inline like Druid Cloud does.
- `make/lagoon.mk` — replace `INSTANCE_prod_*`/`INSTANCE_test_*` +
  `shell-%` with concrete `shell-prod`/`shell-test` targets, mirroring the
  `druid_cloud.mk` `--shell-remote` pattern (private helper target + two
  public targets setting `SSH`/user/host per environment).

  Lagoon SSH user is `<project>-<branch>`, e.g. `taitoliitto-arvi-master` for
  prod (`master` branch). Current `INSTANCE_prod_USER ?= project-name-branch`
  is a literal placeholder string, not a template — every consuming project
  has to override the whole user string per environment today. The concrete
  targets should build it from parts instead: existing `PROJECT` var (already
  in `common.mk`, default `myproject`) + a per-environment branch var (e.g.
  `LAGOON_PROD_BRANCH ?= master`, `LAGOON_TEST_BRANCH`), so
  `USER := $(PROJECT)-$(LAGOON_PROD_BRANCH)` — one var to override
  (`PROJECT`) instead of the whole user string, and the branch convention is
  visible instead of buried in a placeholder default.
- `make/druid_cloud.mk` — no change; already hosting-specific.

**Docs to update once this lands:** `docs/COMMANDS.md` (`shell-<name>` row
under Core, Lagoon section's targets), `docs/CONFIGURATION.md` (`SSH_OPTS`,
`INSTANCE_*` references).

**Watch for:** any consumer project overriding `INSTANCE_*_*` directly in
`override.mk`/`.env` for Lagoon — those need to move to whatever concrete
target/vars replace them.

## Planned: `V=1` verbose mode to show suppressed commands

Every recipe line is hardcoded `@cmd` (~57 lines across `make/*.mk`), so the
actual command run is never echoed — only the `step`/`sub_step`/`group_step`
banner text. Right now the only way to see the real command is `make -n
<target>` (dry run, doesn't execute). Add the standard kernel-Makefile-style
toggle instead: an `AT` variable that's `@` by default and empty when `V=1`
(or `VERBOSE=1`) is passed, so `make <target> V=1` runs for real *and* echoes
every command.

**Plan:**

- `make/Makefile` (or `utils.mk`): `AT := @` by default;
  `ifeq ($(V)$(VERBOSE),)` stays as-is, else `AT :=`. Exact var name/gating
  logic TBD — just needs one flip point.
- Replace hardcoded `@` with `$(AT)` on the commands that actually matter
  (the wrapped tool calls — `docker compose ...`, `drush ...`, `composer
  ...`, `bin/console ...`, `ssh ...` — not the cosmetic `step`/`warn` print
  macros in `utils.mk`, which should stay silent-banner regardless of `V`).
  Touches most `.mk` files; do it file by file, not all at once.

**Docs to update once this lands:** `docs/COMMANDS.md` or
`docs/CONFIGURATION.md` gets a short "debugging: `make <target> V=1`" note
next to the existing `make -n` / `make debug` guidance.

## Bugs

- **`DOCKER_COMPOSE_YML_PATH` override is dead.** `make/docker.mk` `docker_compose`
  macro does `$(filter $(DOCKER_COMPOSE_YML_PATH),$(DOCKER_COMPOSE_YML_PATH))` —
  filtering a value against itself always matches, so the `-f <path>` flag is
  never actually appended to `docker compose`. Setting a custom
  `DOCKER_COMPOSE_YML_PATH` in `override.mk` silently does nothing. Should
  filter against the literal default (`compose.yaml`), same pattern already
  used correctly in `composer.mk` for `COMPOSER_JSON_PATH`.
- **`lint-js` prints the wrong variable.** `make/qa.mk` `lint-js` echoes
  `$(DRUPAL_LINT_PATHS)` in its step message, but the actual eslint invocation
  uses `LINT_PATHS_JS`. `DRUPAL_LINT_PATHS` doesn't exist anywhere — the
  printed path list is always blank. Cosmetic only, but confusing.
- **`test-phpunit-locally` has no `PHONY` entry or `##` help text**, so it's
  invisible to `make help` and not covered by the `PHONY` accumulator
  convention documented in this repo's `CLAUDE.md`. It also references
  `DRUPAL_HOSTNAME` and `DB_URL`, which are not defined or documented anywhere
  in the framework — unclear if this target is still used by any project.
- **`kubectl.mk` assumes `drush` macro exists.** Its sync targets call
  `$(call drush,...)`, but that macro is only defined in `drupal.mk`. If a
  non-Drupal project opts into `kubectl.mk` (see `docs/CONFIGURATION.md`),
  `kubectl-sync-db` breaks with an undefined macro. Either guard it or
  document Drupal as a hard prerequisite.
- **`KUBECTL_CONTAINER` has no default.** `KUBECTL_EXEC_FLAGS` references it
  (`-c $(KUBECTL_CONTAINER)`) but no `?=` default is set, unlike
  `KUBECTL_NAMESPACE`/`KUBECTL_POD_SELECTOR`. An unset value produces
  `-c ''` on the `kubectl` command line.

## Security

- **`set_lagoon_secret` prints secret values in plaintext** (`make/lagoon.mk`):
  `printf "Setting secret on ${2}: %s = %s \n" "${1}" "${${1}}"`. Fine for a
  local terminal, but if `set-lagoon-secrets-*` is ever run in CI, this leaks
  secrets straight into build logs. Should mask the value or drop it from the
  message.

## Consistency / refactoring

- **`kubectl.mk` is downloaded by `make self-update` but never auto-included**
  by `make/include.mk`, unlike every other feature file. This is documented
  now (see `docs/CONFIGURATION.md`), but it's an easy trap: a project can end
  up with the file on disk and reasonably assume it's active. Consider either
  auto-including it behind its own detection variable (e.g. presence of a
  `k8s/` dir or `KUBECTL_NAMESPACE` in `.env`), or moving it out of the
  default download list entirely so "downloaded" and "active" mean the same
  thing everywhere else.
- **Placeholder defaults that look like real config.** `SSH_TESTING`,
  `SSH_STAGING`, `SSH_PRODUCTION` default to `testing.host`/`staging.host`/
  `production.host`; `KUBECTL_NAMESPACE`/`KUBECTL_POD_SELECTOR` default to
  `foobar-namespace`/`appName=foobar-app`; Lagoon `INSTANCE_prod_USER`
  defaults to `project-name-branch`. None of these fail loudly if a project
  forgets to override them — a `deploy-production` or `kubectl-shell` typo'd
  into a real project could silently target nothing (or the wrong thing) with
  no error until the SSH/kubectl call itself fails. Worth a guard clause that
  errors out early ("`SSH_PRODUCTION` looks unset — check override.mk") when
  a variable is still equal to its placeholder default.
- **`update.sh`'s `VERSION` constant is purely cosmetic.** It's a
  hand-maintained timestamp string with no relationship to the `main` branch
  it always pulls from, and no relationship to whatever `make release` bumps.
  Either wire it to the real release version or drop it from the banner to
  avoid implying pinned/versioned installs.
- **No guard against both `IS_DRUPAL` and `IS_SYMFONY` being `yes`.**
  Detection is independent per flag; if a repo happens to have both marker
  files, both `drupal.mk` and `symfony.mk` load and both define a `fresh`
  target — last include wins silently. Not a realistic layout today, but
  worth an explicit `debug` warning if it ever happens.
- **Emoji/step-banner helpers (`step`, `sub_step`, `group_step`, `warn`) are
  hardcoded strings in `utils.mk`** with no way to disable emoji/color for
  non-TTY or CI log consumers. Low priority, but noisy in CI output.

## Documentation gaps

- `make lt` depends on `COMPOSE_PROJECT_NAME` being set (used as the
  localtunnel subdomain) but that variable isn't defined or documented
  anywhere in the framework — it must come from a project's `compose.yaml`
  env. Worth a line in `docs/CONFIGURATION.md`.
- 1Password (`op run --env-file=...`) and GitHub Actions build-label
  (`gha.build` Docker label) conventions that `druid_cloud.mk` depends on
  aren't documented anywhere — someone setting up Druid Cloud deploy for a
  new project has to reverse-engineer them from the Makefile.
- No `CHANGELOG.md` — `make release` bumps a version and pushes, but there's
  no record of what changed between versions for consumers running
  `make self-update` to check against.

## Testing

- Test suite (`tests/tests.sh`) only exercises `make -n` dry-run output
  against `make/` in isolation — it doesn't cover combined detection
  scenarios (e.g. Drupal + Ansible + Druid Cloud all present at once) or
  catch macro-expansion bugs like the `DOCKER_COMPOSE_YML_PATH` one above,
  since dry-run output for a `define` macro that always takes its "no flag"
  branch looks identical to one that's working as intended unless the test
  specifically sets a non-default path.
