BUILD_TARGETS += js-install
JS_PACKAGE_MANAGER ?= yarn
JS_PACKAGE_MANAGER_CWD_FLAG_NPM ?= --prefix
JS_PACKAGE_MANAGER_CWD_FLAG_YARN ?= --cwd
INSTALLED_NODE_VERSION := $(shell command -v node > /dev/null && node --version | cut -c2-3 || echo no)
NVM_SH := $(HOME)/.nvm/nvm.sh
NVM := $(shell test -f "$(NVM_SH)" && echo yes || echo no)
VOLTA_BIN := $(shell command -v volta || echo no)
NODE_BIN := $(shell command -v node || echo no)
NPM_BIN := $(shell command -v npm || echo no)
YARN_BIN := $(shell command -v yarn || echo no)
NODE_VERSION ?= 16

# Auto-detect node manager: prefer Volta over NVM. Override with NODE_MANAGER=volta|nvm
ifneq ($(VOLTA_BIN),no)
  NODE_MANAGER ?= volta
else ifeq ($(NVM),yes)
  NODE_MANAGER ?= nvm
else
  NODE_MANAGER ?= none
endif

PHONY += js-install
js-install: ## Install JS packages
ifeq ($(JS_PACKAGE_MANAGER),yarn)
	$(call node_run,install --frozen-lockfile)
else
	$(call node_run,install --no-audit --no-fund --engine-strict true)
endif

PHONY += js-outdated
js-outdated: ## Show outdated JS packages
	$(call step,Show outdated JS packages with $(JS_PACKAGE_MANAGER)...)
	$(call node_run,outdated)

ifeq ($(NODE_MANAGER),volta)
define node_run
	$(call step,Run '$(JS_PACKAGE_MANAGER) $(1)' with Node $(NODE_VERSION)...\n)
	@volta run --node $(NODE_VERSION) $(JS_PACKAGE_MANAGER) $(if $(filter $(JS_PACKAGE_MANAGER),yarn),$(JS_PACKAGE_MANAGER_CWD_FLAG_YARN),$(JS_PACKAGE_MANAGER_CWD_FLAG_NPM)) $(PACKAGE_JSON_PATH) $(1)
endef
else ifeq ($(NODE_MANAGER),nvm)
define node_run
	$(call step,Run '$(JS_PACKAGE_MANAGER) $(1)' with Node $(NODE_VERSION)...\n)
	@. $(NVM_SH) && (nvm which $(NODE_VERSION) > /dev/null 2>&1 || nvm install $(NODE_VERSION)) && \
		nvm exec $(NODE_VERSION) $(JS_PACKAGE_MANAGER) $(if $(filter $(JS_PACKAGE_MANAGER),yarn),$(JS_PACKAGE_MANAGER_CWD_FLAG_YARN),$(JS_PACKAGE_MANAGER_CWD_FLAG_NPM)) $(PACKAGE_JSON_PATH) $(1)
endef
else
define node_run
	$(call error,$(NODE_MANAGER_REQUIRED))
endef
endif

define NODE_MANAGER_REQUIRED


🚫 A node manager is required to run $(JS_PACKAGE_MANAGER) commands and control Node versions!

   Install Volta (recommended): https://volta.sh
   Install NVM:                 https://github.com/nvm-sh/nvm


endef
