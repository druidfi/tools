# druidfi/tools

Set of tools meant for ease the development.

## How to use in the project

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
