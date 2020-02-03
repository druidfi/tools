ARTIFACT_INCLUDE_EXISTS := $(shell test -f conf/artifact/include && echo yes || echo no)
ARTIFACT_EXCLUDE_EXISTS := $(shell test -f conf/artifact/exclude && echo yes || echo no)
ARTIFACT_CMD := tar -hczf artifact.tar.gz
SSH_OPTS ?= -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no

ifeq ($(ARTIFACT_EXCLUDE_EXISTS),yes)
	ARTIFACT_CMD := ${ARTIFACT_CMD} --exclude-from=conf/artifact/exclude
endif

ifeq ($(ARTIFACT_INCLUDE_EXISTS),yes)
	ARTIFACT_CMD := ${ARTIFACT_CMD} --files-from=conf/artifact/include
else
	ARTIFACT_CMD := ${ARTIFACT_CMD} *
endif

PHONY += artifact
# This command can always be run on host
artifact: RUN_ON := host
artifact: ## Make tar.gz package from the current build
	$(call step,Create artifact (${RUN_ON})...)
	@${ARTIFACT_CMD}

PHONY += build
build: $(BUILD_TARGETS) ## Build codebase(s)
	$(call step,Start build for env: $(ENV)\n- Following targets will be run: $(BUILD_TARGETS))
	@$(MAKE) $(BUILD_TARGETS) ENV=$(ENV)
	$(call step,Build completed.)

PHONY += build-dev
build-dev: build

PHONY += build-testing
build-testing: ENV := testing
build-testing: build

PHONY += build-production
build-production: ENV := production
build-production: build

PHONY += clean
clean: ## Clean folders
	$(call step,Clean folders:\n- Following folders will be removed: ${CLEAN_FOLDERS})
	@rm -rf ${CLEAN_FOLDERS}

PHONY += help
help: ## List all make commands
	$(call step,Available make commands:)
	@cat $(MAKEFILE_LIST) | grep -e "^[a-zA-Z_\-]*: *.*## *" | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' | sort

PHONY += self-update
self-update: ## Self-update makefiles from druidfi/tools
	$(call step,Update makefiles from druidfi/tools)
	@bash -c "$$(curl -fsSL ${UPDATE_SCRIPT_URL})"

PHONY += shell-%
shell-%: OPTS = $(INSTANCE_$*_OPTS)
shell-%: USER = $(INSTANCE_$*_USER)
shell-%: HOST = $(INSTANCE_$*_HOST)
shell-%: ## Login to remote instance
	ssh $(OPTS) $(USER)@$(HOST)

PHONY += self-update
sync: ## Sync data from other environments
	$(call step,Start sync:\n- Following targets will be run: $(SYNC_TARGETS))
	@$(MAKE) $(SYNC_TARGETS) ENV=$(ENV)
	$(call step,Sync completed.)
