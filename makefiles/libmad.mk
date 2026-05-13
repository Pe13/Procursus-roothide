ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libmad
LIBMAD_VERSION := 0.16.4
DEB_LIBMAD_V   ?= $(LIBMAD_VERSION)

libmad-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/libmad-$(LIBMAD_VERSION).tar.gz,https://codeberg.org/tenacityteam/libmad/archive/$(LIBMAD_VERSION).tar.gz)
	$(call EXTRACT_TAR,libmad-$(LIBMAD_VERSION).tar.gz,libmad-$(LIBMAD_VERSION),libmad)
	mkdir -p $(BUILD_WORK)/libmad/build

ifneq ($(wildcard $(BUILD_WORK)/libmad/.build_complete),)
libmad:
	@echo "Using previously built libmad."
else
libmad: libmad-setup
	cd $(BUILD_WORK)/libmad/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/libmad/build
	+$(MAKE) -C $(BUILD_WORK)/libmad/build install \
		DESTDIR="$(BUILD_STAGE)/libmad"
	$(call AFTER_BUILD,copy)
endif

libmad-package: libmad-stage
	# libmad.mk Package Structure
	rm -rf $(BUILD_DIST)/libmad

	# libmad.mk Prep libmad
	cp -a $(BUILD_STAGE)/libmad $(BUILD_DIST)

	# libmad.mk Sign
	$(call SIGN,libmad,general.xml)

	# libmad.mk Make .debs
	$(call PACK,libmad,DEB_LIBMAD_V)

	# libmad.mk Build cleanup
	rm -rf $(BUILD_DIST)/libmad

.PHONY: libmad libmad-package
