# druidfi/tools

[![Build Status](https://travis-ci.com/druidfi/tools.svg?branch=master)](https://travis-ci.com/druidfi/tools)

Set of tools meant for ease the development.

## Features

- Generalized Make commands (build, up, down, etc)
- Same command can be run on Docker container and on host
- Extendable in your project
- Easily Updatable

## How to use in the project

Download oneliner (source is [update.sh](update.sh)):

```
$ bash -c "$(curl -fsSL -H 'Cache-Control: no-cache' https://git.io/fh771)"
```

## Project specific

Makefiles: you can add project specific Make files to `tools/make/project`.

See the example below to see how they are loaded with:

`-include $(PROJECT_DIR)/tools/make/project/*.mk`.

## Default commands

Command | Description
--- | ---
make build | Build for dev env
make build ENV=production | Build for specified env
make debug | Show debug information
make down | Tear down the environment
make help | List all make commands
make shell | Login to CLI container
make self-update | Self-update all the tools from druidfi/tools. See [update.sh](update.sh).
make up | Launch the environment

## Example on Makefile in your project root

```
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

```
$ make self-update
```

## Where this is used

- https://github.com/druidfi/spell

## FAQ

*Why cannot the makefiles be included with Composer and from `vendor/druidfi/tools/make`?*

As one of the operations `make clean` will remove the `vendor` folder.

## Developing

Run tests:

```
tests/tests.sh && echo "success" || echo "fail"
```

Read more about testing [here](tests/README.md).

## Other information

This project is found from the Packagist: https://packagist.org/packages/druidfi/tools
