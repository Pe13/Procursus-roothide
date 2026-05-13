ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libebur128
LIBEBUR128_VERSION := 1.2.6
DEB_LIBEBUR128_V   ?= $(LIBEBUR128_VERSION)

libebur128-setup: setup
	$(call GITHUB_ARCHIVE,jiixyj,libebur128,$(LIBEBUR128_VERSION),v$(LIBEBUR128_VERSION))
	$(call EXTRACT_TAR,libebur128-$(LIBEBUR128_VERSION).tar.gz,libebur128-$(LIBEBUR128_VERSION),libebur128)
	mkdir -p $(BUILD_WORK)/libebur128/build

ifneq ($(wildcard $(BUILD_WORK)/libebur128/.build_complete),)
libebur128:
	@echo "Using previously built libebur128."
else
libebur128: libebur128-setup
	cd $(BUILD_WORK)/libebur128/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/libebur128/build
	+$(MAKE) -C $(BUILD_WORK)/libebur128/build install \
		DESTDIR="$(BUILD_STAGE)/libebur128"
	$(call AFTER_BUILD,copy)
endif

libebur128-package: libebur128-stage
	# libebur128.mk Package Structure
	rm -rf $(BUILD_DIST)/libebur128

	# libebur128.mk Prep libebur128
	cp -a $(BUILD_STAGE)/libebur128 $(BUILD_DIST)

	# libebur128.mk Sign
	$(call SIGN,libebur128,general.xml)

	# libebur128.mk Make .debs
	$(call PACK,libebur128,DEB_LIBEBUR128_V)

	# libebur128.mk Build cleanup
	rm -rf $(BUILD_DIST)/libebur128

.PHONY: libebur128 libebur128-package
