# druidfi/tools

![Tests](https://github.com/druidfi/tools/workflows/Tests/badge.svg)

Set of tools meant for ease the development.

## Features

- Generalized Make commands (build, up, down, etc)
- Same command can be run on Docker container and on host
- Extendable in your project
- Easily Updatable

## How to use in the project

Download oneliner (source is [update.sh](update.sh)):

```shell
bash -c "$(curl -fsSL -H 'Cache-Control: no-cache' https://git.io/JP10q)"
```

## Documentation

- [docs/COMMANDS.md](docs/COMMANDS.md) — full `make` command reference, grouped by feature (Docker, Drupal, Symfony, Composer, JavaScript, QA, Ansible, Druid Cloud, Lagoon, Kubernetes)
- [docs/CONFIGURATION.md](docs/CONFIGURATION.md) — how loading/auto-detection works, all configuration variables, and how to override or extend the framework in your project
- [docs/TODO.md](docs/TODO.md) — known bugs, inconsistencies, and refactoring ideas

## Project specific

Makefiles: you can add project specific Make files to `tools/make/project`.

See the example below to see how they are loaded with:

`-include $(PROJECT_DIR)/tools/make/project/*.mk`.

See [docs/CONFIGURATION.md](docs/CONFIGURATION.md#extending-with-project-specific-make-files)
for how to add new targets or hook into composite targets like `build`/`test`/`lint`/`fix`/`sync`.

### Override variables

You can also add `tools/make/override.mk` to override variables.

For example if you want to force certain CLI values for your local setup even if something is autodetected:

```makefile
# Custom Docker CLI container
CLI_SERVICE := app
CLI_USER := druid
DOCKER_PROJECT_ROOT := /app
```

Full variable reference: [docs/CONFIGURATION.md](docs/CONFIGURATION.md#key-variables).

## Default commands

Always-available commands only — see [docs/COMMANDS.md](docs/COMMANDS.md) for
the complete list, including Docker, Drupal, Symfony, and hosting-specific
commands that load automatically based on project type.

| Command                   | Description                                                               |
|---------------------------|---------------------------------------------------------------------------|
| make build                | Build codebase(s)                                                         |
| make debug                | Show debug information                                                    |
| make down                 | Tear down the environment                                                 |
| make help                 | List all make commands                                                    |
| make shell                | Login to CLI container                                                    |
| make self-update          | Self-update all the tools from druidfi/tools. See [update.sh](update.sh). |
| make up                   | Launch the environment                                                    |

## Example on Makefile in your project root

```makefile
PHONY :=
PROJECT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

# Include project env vars (if exists)
-include .env

# Include druidfi/tools config
include $(PROJECT_DIR)/tools/make/Makefile

# Include project specific make files (if they exist)
-include $(PROJECT_DIR)/tools/make/project/*.mk

.PHONY: $(PHONY)
```

## Update the tools

Update general tools by downloading new versions of the files:

```shell
make self-update
```

## Where this is used

- https://github.com/druidfi/spell

## FAQ

*Why cannot the makefiles be included with Composer and from `vendor/druidfi/tools/make`?*

As one of the operations `make clean` will remove the `vendor` folder.

## Developing

Set Git hook. This will run tests pre-commit and if all is good, then update version.

```console
ln -sf ../../hooks/pre-commit .git/hooks/pre-commit
```

Run tests:

```console
make test
```

Read more about testing [here](tests/README.md).
