ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libmodplug
LIBMODPLUG_VERSION := 0.8.9.0
DEB_LIBMODPLUG_V   ?= $(LIBMODPLUG_VERSION)

libmodplug-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/libmodplug-$(LIBMODPLUG_VERSION).tar.gz/download,https://sourceforge.net/projects/modplug-xmms/files/libmodplug/$(LIBMODPLUG_VERSION)/libmodplug-$(LIBMODPLUG_VERSION).tar.gz/download)
	$(call EXTRACT_TAR,libmodplug-$(LIBMODPLUG_VERSION).tar.gz/download,libmodplug-$(LIBMODPLUG_VERSION),libmodplug)

ifneq ($(wildcard $(BUILD_WORK)/libmodplug/.build_complete),)
libmodplug:
	@echo "Using previously built libmodplug."
else
libmodplug: libmodplug-setup
	cd $(BUILD_WORK)/libmodplug && ./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libmodplug
	+$(MAKE) -C $(BUILD_WORK)/libmodplug install \
		DESTDIR=$(BUILD_STAGE)/libmodplug
	$(call AFTER_BUILD,copy)
endif

libmodplug-package: libmodplug-stage
	# libmodplug.mk Package Structure
	rm -rf $(BUILD_DIST)/libmodplug

	# libmodplug.mk Prep libmodplug
	cp -a $(BUILD_STAGE)/libmodplug $(BUILD_DIST)

	# libmodplug.mk Sign
	$(call SIGN,libmodplug,general.xml)

	# libmodplug.mk Make .debs
	$(call PACK,libmodplug,DEB_LIBMODPLUG_V)

	# libmodplug.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmodplug

.PHONY: libmodplug libmodplug-package
