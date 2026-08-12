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

## Planned: drop `ENV`-specific builds

`ENV` (`dev`/`testing`/`production`) dates from when the same repo was cloned
onto local, testing, and production hosts and `make build ENV=$env` picked the
build flavor per host. Not needed here — collapse to one build.

**Touch points:**

- `make/Makefile` — drop `ENV := dev` default var.
- `make/common.mk`:
  - `build` target: drop `ENV=$(ENV)` from the `group_step` message and the
    recursive `$(MAKE) $(BUILD_TARGETS)` call.
  - `build-dev` / `build-testing` / `build-production` targets: delete all
    three, only plain `build` remains.
  - `sync` target: drop `ENV=$(ENV)` from the recursive `$(MAKE)
    $(SYNC_TARGETS)` call — `ENV` isn't used by any current `SYNC_TARGETS`
    member (`drush-sync` and friends in `drupal.mk` don't branch on it).
- `make/composer.mk` — `composer-install`: drop the
  `$(if $(filter production,$(ENV)), $(COMPOSER_PROD_FLAGS),)` branch. Decide
  separately whether `COMPOSER_PROD_FLAGS`
  (`--no-dev --optimize-autoloader --prefer-dist`) should become the
  permanent default, a dedicated `composer-install-prod` target, or get
  dropped — whichever it is, `composer-install` no longer varies by `ENV`.

**Docs to update once this lands:** `README.md` (`make build ENV=production`
row), `docs/COMMANDS.md` (`build`/`build-dev`/`build-testing`/
`build-production` rows, `composer-install` row), `docs/CONFIGURATION.md`
(`ENV` variable row and the `.env`/`ENV=production` example), and this repo's
`CLAUDE.md` (`ENV` in the key-variables table).

**Watch for:** any `tools/make/project/*.mk` files in consumer projects that
call `make build ENV=...` or branch their own `BUILD_TARGETS` steps on `ENV`
— those break silently once the var stops being threaded through. Worth a
grep across the monorepo before landing this.

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
