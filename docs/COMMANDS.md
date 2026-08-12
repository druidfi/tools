# Command reference

Full list of `make` targets provided by druidfi/tools. Which files get loaded (and
so which commands become available) depends on auto-detection — see
[CONFIGURATION.md](CONFIGURATION.md#auto-detection--conditional-loading).

Run `make help` in any project for the live list of targets actually available there.

## Core (always available)

From `make/common.mk` and `make/utils.mk`.

| Command | Description |
|---|---|
| `make help` | List all make commands |
| `make debug` | Show detected environment and variables |
| `make build` | Build codebase(s) for `ENV` (default `dev`), runs `BUILD_TARGETS` |
| `make build-dev` | Alias for `build` |
| `make build-testing` | `build` with `ENV=testing` |
| `make build-production` | `build` with `ENV=production` |
| `make clean` | Remove `vendor/` and git-clean untracked files (see `CLEAN_EXCLUDE`) |
| `make self-update` | Re-download the `tools/make/*` framework files from druidfi/tools |
| `make sync` | Sync data from other environments, runs `SYNC_TARGETS` |
| `make gh-download-dump` | Download a DB dump from GitHub Actions artifacts (`gh run download`) |
| `make shell-<name>` | SSH into a configured remote instance (`INSTANCE_<name>_*` vars) |
| `make lt` | Open a localtunnel (`npm install -g localtunnel` required) |

## Docker (`make/docker.mk`, loaded when the `docker` binary exists)

| Command | Description |
|---|---|
| `make up` | Launch the environment (`docker compose up --wait --remove-orphans`) |
| `make down` | Tear down the environment (removes volumes, orphans, local images) |
| `make stop` | Stop the containers without removing them |
| `make ps` | List containers |
| `make pull` | Pull the latest Docker images |
| `make config` | Show resolved `docker compose config` |
| `make shell` | Log in to the CLI container (`CLI_SERVICE`, `CLI_SHELL`) |
| `make ssh-check` | Check SSH keys forwarded into the CLI container |

`RUN_ON` is auto-detected: `docker` when a `compose.yaml` exists and you're not
already inside a container, `host` otherwise. Commands like `drush`, `composer`,
`bin/console` transparently run inside the container or on the host depending
on this.

## Drupal (`make/drupal.mk`, loaded when `<WEBROOT>/sites/default/settings.php` exists)

| Command | Description |
|---|---|
| `make fresh` | Full setup: runs `DRUPAL_FRESH_TARGETS` (`up build sync post-install`, plus `gh-download-dump` first if `GH_DUMP_ARTIFACT=yes`) |
| `make new` | Create an empty install from config: `up build drush-si drush-uli` |
| `make post-install` | Run `DRUPAL_POST_INSTALL_TARGETS` (`drush-deploy`, plus `drush-enable-modules` if configured) then `drush-uli` |
| `make drush-si` | Site install — uses `--existing-config` if `conf/cmi/core.extension.yml` exists, else installs `DRUPAL_PROFILE` |
| `make drush-deploy` | Run `drush deploy` |
| `make drush-updb` | Run pending database updates |
| `make drush-cex` / `make drush-cim` | Export / import configuration |
| `make drush-cr` | Clear caches |
| `make drush-status` | Show Drupal status |
| `make drush-uli` | Print a login link (`DRUPAL_UID`, `DRUPAL_DESTINATION`) |
| `make drush-uli-<uid>` | Login link for a specific user id |
| `make drush-reset-local` | `cim`, `cr`, `updb --no-cache-clear`, `cr` in sequence |
| `make drush-sync` | `drush-sync-db` + `drush-sync-files` |
| `make drush-sync-db` | Import local `dump.sql` if present, else `sql-sync` from `DRUPAL_SYNC_SOURCE` when `SYNC_FROM_REMOTE=yes` |
| `make drush-sync-files` | rsync public files from `DRUPAL_SYNC_SOURCE` (only if `DRUPAL_SYNC_FILES=yes`) |
| `make drush-create-dump` | Dump current DB to `dump.sql` |
| `make drush-download-dump` | Dump `DRUPAL_SYNC_SOURCE`'s DB straight to local `dump.sql` |
| `make drush-enable-modules` / `make drush-disable-modules` | En-/disable modules listed in `DRUPAL_ENABLE_MODULES` / `DRUPAL_DISABLE_MODULES` |
| `make drupal-update` | `composer update -W "drupal/core-*"` |
| `make open-db-gui` | Open the DB in a `mysql://` GUI client (`DB_SERVICE`, `DB_NAME`, `DB_USER`, `DB_PASS`) |
| `make lint-drupal` | phpcs with `Drupal,DrupalPractice` standards |
| `make fix-drupal` | phpcbf auto-fix |
| `make drupal-build-theme` / `make drupal-watch-theme` | Build/watch the custom theme (`DRUPAL_THEME_NAME`) with pnpm |

## Symfony (`make/symfony.mk`, loaded when `config/bundles.php` exists)

| Command | Description |
|---|---|
| `make fresh` | `up build sf-cw sf-about sf-open` |
| `make sf-about` | `bin/console about` |
| `make sf-cc` / `make sf-cw` | Clear / warm Symfony caches |
| `make sf-db-init` | `doctrine:schema:update --force` + load fixtures |
| `make sf-open` | Print the app URL (`APP_HOST`) |
| `make sf-update` | Update `doctrine/*`, `symfony/*`, `twig/*` via Composer |
| `make lint-symfony` | php-cs-fixer dry-run diff |
| `make fix-symfony` | php-cs-fixer auto-fix |
| `make encore-dev` / `make encore-watch` | Webpack Encore dev build / watch |
| `make update-symfony-docker` | Pull latest Symfony Docker files from druidfi/tools |

## Composer (`make/composer.mk`, loaded when `composer.json` exists)

| Command | Description |
|---|---|
| `make composer-install` | Install packages (adds `--no-dev --optimize-autoloader --prefer-dist` when `ENV=production`) |
| `make composer-update` | Update packages |
| `make composer-outdated` | Show outdated direct dependencies |
| `make composer-info` | `composer info` |

## JavaScript (`make/javascript.mk`, loaded when `package.json` exists)

| Command | Description |
|---|---|
| `make js-install` | Install JS packages with `JS_PACKAGE_MANAGER` (default `pnpm`, frozen lockfile) |
| `make js-outdated` | Show outdated JS packages |

Node version manager (Volta preferred, falls back to NVM) is auto-detected;
see [CONFIGURATION.md](CONFIGURATION.md#javascript--node).

## QA (`make/qa.mk`, always available)

| Command | Description |
|---|---|
| `make test` | Run `TEST_TARGETS` (`test-phpunit` by default) |
| `make test-phpunit` | Run PHPUnit (`TESTSUITES`, default `unit,kernel,functional`); runs directly on host when `CI=true` |
| `make lint` | `lint-php` + `lint-js` |
| `make lint-php` | Runs `LINT_PHP_TARGETS` (populated by `drupal.mk` / `symfony.mk`) |
| `make lint-js` | Drupal core JS lint via a throwaway `node` Docker container |
| `make fix` | Runs `FIX_TARGETS` (populated by `drupal.mk` / `symfony.mk`) |

## Ansible (`make/ansible.mk`, loaded when `ansible/` directory exists)

| Command | Description |
|---|---|
| `make provision` | Run the playbook (`ANSIBLE_PROVISION`) |
| `make provision-dry-run` | Same, with `--check` |
| `make provision-<tag>` | Run only tasks tagged `<tag>` |
| `make ansible-install-roles` | `ansible-galaxy install` from `ANSIBLE_REQUIREMENTS` |
| `make ansible-update-roles` | Remove and reinstall all roles |

Provisioning targets auto-install roles first if `ANSIBLE_CHECK_ROLE` isn't present yet.

## Hosting: Druid Cloud (`make/druid_cloud.mk`, loaded when `compose.live.yaml` exists)

| Command | Description |
|---|---|
| `make deploy-testing` / `deploy-staging` / `deploy-production` | Deploy the current build via `op run` + `docker compose up` on the matching host, then run `drush deploy` remotely |
| `make shell-testing` / `shell-staging` / `shell-production` | SSH into the matching remote host |

Requires the 1Password CLI (`op`) and SSH access; hosts/user configured via
`SSH_USER`, `SSH_TESTING`, `SSH_STAGING`, `SSH_PRODUCTION`.

## Hosting: Lagoon (`make/lagoon.mk`, loaded when `.lagoon.yml` exists)

| Command | Description |
|---|---|
| `make lagoon-env` | Print `LAGOON_*` env vars from the CLI container |
| `make deploy-lagoon-<branch>` | `lagoon deploy branch -b <branch>` |
| `make set-lagoon-secrets-<env>` | Push `LAGOON_SECRETS` (read from `.env.local.lagoon`) to environment `<env>` |
| `make list-lagoon-vars-<env>` | List Lagoon variables for environment `<env>` |

When Lagoon is detected, `SYNC_FROM_REMOTE` defaults to `yes` and Drupal sync
targets pull from Lagoon automatically.

## Kubernetes (`make/kubectl.mk`, opt-in — not auto-loaded)

This file is downloaded by `make self-update` but is **not** included by
`make/include.mk` automatically. To use it, include it explicitly from a
project make file, e.g. in `tools/make/project/kubectl.mk`:

```makefile
include $(PROJECT_DIR)/tools/make/kubectl.mk
```

| Command | Description |
|---|---|
| `make kubectl-sync-db` | Dump DB from a pod (`KUBECTL_POD_SELECTOR`) and import locally, or import an existing `dump.sql` |
| `make kubectl-sync-files-tar` | Copy files out of a pod with `tar` |
| `make kubectl-rsync-files` | Copy files out of a pod with `rsync` |
| `make kubectl-shell` | Open a shell in the selected pod |

## Meta-targets built from accumulators

Some targets don't do anything themselves — they run whatever list of targets
other `.mk` files have appended to their name. Order in the list depends on the
order `.mk` files are included in `make/include.mk`.

| Meta-target | Accumulator variable | Populated by |
|---|---|---|
| `make build` | `BUILD_TARGETS` | `composer.mk` (`composer-install`), `drupal.mk` (`drupal-create-folders`) |
| `make test` | `TEST_TARGETS` | `qa.mk` (`test-phpunit`) |
| `make lint-php` | `LINT_PHP_TARGETS` | `drupal.mk` (`lint-drupal`), `symfony.mk` (`lint-symfony`) |
| `make fix` | `FIX_TARGETS` | `drupal.mk` (`fix-drupal`), `symfony.mk` (`fix-symfony`) |
| `make sync` | `SYNC_TARGETS` | `drupal.mk` (`drush-sync`, `drush-disable-modules`) |

Add your own project-specific step to one of these from
`tools/make/project/*.mk` — see [CONFIGURATION.md](CONFIGURATION.md#extending-with-project-specific-make-files).
