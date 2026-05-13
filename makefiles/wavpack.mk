ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += wavpack
WAVPACK_VERSION := 5.8.1
DEB_WAVPACK_V   ?= $(WAVPACK_VERSION)

wavpack-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/wavpack-$(WAVPACK_VERSION).tar.xz,https://github.com/dbry/WavPack/releases/download/$(WAVPACK_VERSION)/wavpack-$(WAVPACK_VERSION).tar.xz)
	$(call EXTRACT_TAR,wavpack-$(WAVPACK_VERSION).tar.xz,wavpack-$(WAVPACK_VERSION),wavpack)

ifneq ($(wildcard $(BUILD_WORK)/wavpack/.build_complete),)
wavpack:
	@echo "Using previously built wavpack."
else
wavpack: wavpack-setup
	cd $(BUILD_WORK)/wavpack && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/wavpack
	+$(MAKE) -C $(BUILD_WORK)/wavpack install \
		DESTDIR=$(BUILD_STAGE)/wavpack
	$(call AFTER_BUILD,copy)
endif

wavpack-package: wavpack-stage
	# wavpack.mk Package Structure
	rm -rf $(BUILD_DIST)/wavpack

	# wavpack.mk Prep wavpack
	cp -a $(BUILD_STAGE)/wavpack $(BUILD_DIST)

	# wavpack.mk Sign
	$(call SIGN,wavpack,general.xml)

	# wavpack.mk Make .debs
	$(call PACK,wavpack,DEB_WAVPACK_V)

	# wavpack.mk Build cleanup
	rm -rf $(BUILD_DIST)/wavpack

.PHONY: wavpack wavpack-package
