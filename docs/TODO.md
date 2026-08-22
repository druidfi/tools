# TODO / future improvements

Living list of known bugs, inconsistencies, and refactoring ideas found while
working on this framework. Not prioritized against a roadmap — pick up
whatever's relevant when touching that area.

## Planned: QA total refactor

`make/qa.mk` (`lint`, `lint-php`, `lint-js`, `fix`, `test`, `test-phpunit`,
`test-phpunit-locally`, the `cs`/`test_result` macros) needs a ground-up
rework — no detailed shape yet, flagging it so nobody invests in the current
structure. Related known issues to fold in when this starts: the `lint-js`
wrong-variable bug and `test-phpunit-locally` `PHONY`/help gaps listed below.

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
  `foobar-namespace`/`appName=foobar-app`. None of these fail loudly if a
  project forgets to override them — a `deploy-production` or `kubectl-shell`
  typo'd into a real project could silently target nothing (or the wrong
  thing) with no error until the SSH/kubectl call itself fails. Worth a guard
  clause that errors out early ("`SSH_PRODUCTION` looks unset — check
  override.mk") when a variable is still equal to its placeholder default.
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
