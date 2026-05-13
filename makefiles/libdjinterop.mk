ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libdjinterop
LIBDJINTEROP_VERSION := 0.24.3
DEB_LIBDJINTEROP_V   ?= $(LIBDJINTEROP_VERSION)

libdjinterop-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/libdjinterop-$(LIBDJINTEROP_VERSION).tar.gz,https://github.com/xsco/libdjinterop/archive/refs/tags/$(LIBDJINTEROP_VERSION).tar.gz)
	$(call EXTRACT_TAR,libdjinterop-$(LIBDJINTEROP_VERSION).tar.gz,libdjinterop-$(LIBDJINTEROP_VERSION),libdjinterop)

ifneq ($(wildcard $(BUILD_WORK)/libdjinterop/.build_complete),)
libdjinterop:
	@echo "Using previously built libdjinterop."
else
libdjinterop: libdjinterop-setup
	cmake -S $(BUILD_WORK)/libdjinterop -B $(BUILD_WORK)/libdjinterop/build \
		$(DEFAULT_CMAKE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/libdjinterop/build
	+$(MAKE) -C $(BUILD_WORK)/libdjinterop/build install \
		DESTDIR="$(BUILD_STAGE)/libdjinterop"
	$(call AFTER_BUILD,copy)
endif

libdjinterop-package: libdjinterop-stage
	# libdjinterop.mk Package Structure
	rm -rf $(BUILD_DIST)/libdjinterop

	# libdjinterop.mk Prep libdjinterop
	cp -a $(BUILD_STAGE)/libdjinterop $(BUILD_DIST)

	# libdjinterop.mk Sign
	$(call SIGN,libdjinterop,general.xml)

	# libdjinterop.mk Make .debs
	$(call PACK,libdjinterop,DEB_LIBDJINTEROP_V)

	# libdjinterop.mk Build cleanup
	rm -rf $(BUILD_DIST)/libdjinterop

.PHONY: libdjinterop libdjinterop-package
