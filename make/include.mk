include $(DRUIDFI_TOOLS_MAKE_DIR)common.mk
include $(DRUIDFI_TOOLS_MAKE_DIR)docker.mk
include $(DRUIDFI_TOOLS_MAKE_DIR)qa.mk

#
# Hosting systems
#
# Included before Apps: app .mk files (drupal.mk, symfony.mk) hook their
# post-deploy steps onto --deploy:: from druid_cloud.mk. Double-colon rule
# recipes run in the order they are read, so the hosting system that owns
# the base --deploy:: recipe must be included first.
#

DRUID_CLOUD ?= $(shell test -f compose.live.yaml && echo yes || echo no)
LAGOON ?= $(shell test -f .lagoon.yml && echo yes || echo no)

ifeq ($(DRUID_CLOUD),yes)
	SYSTEM := DRUID_CLOUD
	include $(DRUIDFI_TOOLS_MAKE_DIR)druid_cloud.mk
else ifeq ($(LAGOON),yes)
	SYSTEM := LAGOON
	include $(DRUIDFI_TOOLS_MAKE_DIR)lagoon.mk
else
	SYSTEM := WHOKNOWS
endif

#
# Apps
#

IS_DRUPAL ?= $(shell test -f $(WEBROOT)/sites/default/settings.php && echo yes || echo no)
IS_SYMFONY ?= $(shell test -f config/bundles.php && echo yes || echo no)

ifeq ($(IS_DRUPAL),yes)
include $(DRUIDFI_TOOLS_MAKE_DIR)drupal.mk
endif

ifeq ($(IS_SYMFONY),yes)
include $(DRUIDFI_TOOLS_MAKE_DIR)symfony.mk
endif

#
# Other tools
#

HAS_ANSIBLE ?= $(shell test -d ansible && echo yes || echo no)

ifeq ($(HAS_ANSIBLE),yes)
include $(DRUIDFI_TOOLS_MAKE_DIR)ansible.mk
endif

#
# Package managers
#

COMPOSER_JSON_EXISTS ?= $(shell test -f $(COMPOSER_JSON_PATH)/composer.json && echo yes || echo no)

ifeq ($(COMPOSER_JSON_EXISTS),yes)
include $(DRUIDFI_TOOLS_MAKE_DIR)composer.mk
endif

PACKAGE_JSON_EXISTS ?= $(shell test -f $(PACKAGE_JSON_PATH)/package.json && echo yes || echo no)

ifeq ($(PACKAGE_JSON_EXISTS),yes)
include $(DRUIDFI_TOOLS_MAKE_DIR)javascript.mk
endif
