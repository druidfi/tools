DOWNLOADER_IMAGE := druidfi/backupper-downloader
DOWNLOADER_URL := https://github.com/druidfi/backupper/releases/tag/latest
DOWNLOADER_ERROR := Downloader image "$(DOWNLOADER_IMAGE)" was not found!\n\n   Get it from $(DOWNLOADER_URL)\n\n

DRUPAL_FRESH_TARGETS := download-dump $(DRUPAL_FRESH_TARGETS)

PHONY += download-dump
download-dump: ## Download a database dump
ifeq ($(DUMP_SQL_EXISTS),no)
	$(call step,Download & extract database dump...)
	@docker run -it --rm -v $(PWD)/tmp:/app/downloads $(DOWNLOADER_IMAGE) download $(DOWNLOADER_PROJECT) \
		&& gunzip tmp/$(DUMP_SQL_FILENAME).gz \
		&& mv tmp/$(DUMP_SQL_FILENAME) $(DUMP_SQL_FILENAME) \
		&& rm -rf tmp \
		|| (printf "\n⚠️  $(DOWNLOADER_ERROR)" && exit 1)
endif
