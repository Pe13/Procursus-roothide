ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libid3tag
LIBID3TAG_VERSION := 0.16.3
DEB_LIBID3TAG_V   ?= $(LIBID3TAG_VERSION)

libid3tag-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/libid3tag-$(LIBID3TAG_VERSION).tar.gz,https://codeberg.org/tenacityteam/libid3tag/archive/$(LIBID3TAG_VERSION).tar.gz)
	$(call EXTRACT_TAR,libid3tag-$(LIBID3TAG_VERSION).tar.gz,libid3tag-$(LIBID3TAG_VERSION),libid3tag)
	mkdir -p $(BUILD_WORK)/libid3tag/build

ifneq ($(wildcard $(BUILD_WORK)/libid3tag/.build_complete),)
libid3tag:
	@echo "Using previously built libid3tag."
else
libid3tag: libid3tag-setup
	cd $(BUILD_WORK)/libid3tag/build && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/libid3tag/build
	+$(MAKE) -C $(BUILD_WORK)/libid3tag/build install \
		DESTDIR="$(BUILD_STAGE)/libid3tag"
	$(call AFTER_BUILD,copy)
endif

libid3tag-package: libid3tag-stage
	# libid3tag.mk Package Structure
	rm -rf $(BUILD_DIST)/libid3tag

	# libid3tag.mk Prep libid3tag
	cp -a $(BUILD_STAGE)/libid3tag $(BUILD_DIST)

	# libid3tag.mk Sign
	$(call SIGN,libid3tag,general.xml)

	# libid3tag.mk Make .debs
	$(call PACK,libid3tag,DEB_LIBID3TAG_V)

	# libid3tag.mk Build cleanup
	rm -rf $(BUILD_DIST)/libid3tag

.PHONY: libid3tag libid3tag-package
