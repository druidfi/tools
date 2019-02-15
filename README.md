# druidfi/tools

Set of tools meant for ease the development.

## Features

- Generalized Make commands (build, up, down, etc)
- Same command can be run on Docker container and on host
- Extendable in your project
- Easily Updatable

## How to use in the project

Download oneliner:

```
$ sh -c "$(curl -fsSL https://raw.githubusercontent.com/druidfi/tools/master/update.sh)"
```

Require with Composer

```
$ composer require druidfi/tools:dev-master
```

Or add manually following to your project's composer.json file:

```
"require-dev": {
    "druidfi/tools": "dev-master"
},
```

## Default commands

Command | Description
--- | ---
make build | Build for dev env
make build ENV=production | Build for specified env
make debug | Show debug information
make down | Tear down the environment
make help | List all make commands
make shell | Login to CLI container
make self-update | Self-update all the tools from druidfi/tools
make up | Launch the environment

## Example on Makefile in your project root

```
PHONY :=
PROJECT_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

# Include project env vars
include .env

# Include druidfi/tools config
include $(PROJECT_DIR)/vendor/druidfi/tools/make/Makefile

# Include project specific make files if they exist
-include $(PROJECT_DIR)/make/*.mk

.PHONY: $(PHONY)
```

## Update the tools

TODO: there will be a command `make self-update`

## Where this is used

- https://github.com/druidfi/amazeeio-scripts
- https://github.com/druidfi/spell

## Other information

This project is found from the Packagist: https://packagist.org/packages/druidfi/tools
