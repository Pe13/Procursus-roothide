ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += libkeyfinder
LIBKEYFINDER_VERSION := 2.2.8
DEB_LIBKEYFINDER_V   ?= $(LIBKEYFINDER_VERSION)

libkeyfinder-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/libkeyfinder-$(LIBKEYFINDER_VERSION).tar.gz,https://github.com/mixxxdj/libkeyfinder/archive/refs/tags/$(LIBKEYFINDER_VERSION).tar.gz)
	$(call EXTRACT_TAR,libkeyfinder-$(LIBKEYFINDER_VERSION).tar.gz,libkeyfinder-$(LIBKEYFINDER_VERSION),libkeyfinder)

ifneq ($(wildcard $(BUILD_WORK)/libkeyfinder/.build_complete),)
libkeyfinder:
	@echo "Using previously built libkeyfinder."
else
libkeyfinder: libkeyfinder-setup fftw
	cmake -S $(BUILD_WORK)/libkeyfinder -B $(BUILD_WORK)/libkeyfinder/build \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_TESTING=OFF
	+$(MAKE) -C $(BUILD_WORK)/libkeyfinder/build
	+$(MAKE) -C $(BUILD_WORK)/libkeyfinder/build install \
		DESTDIR="$(BUILD_STAGE)/libkeyfinder"
	$(call AFTER_BUILD,copy)
endif

libkeyfinder-package: libkeyfinder-stage
	# libkeyfinder.mk Package Structure
	rm -rf $(BUILD_DIST)/libkeyfinder

	# libkeyfinder.mk Prep libkeyfinder
	cp -a $(BUILD_STAGE)/libkeyfinder $(BUILD_DIST)

	# libkeyfinder.mk Sign
	$(call SIGN,libkeyfinder,general.xml)

	# libkeyfinder.mk Make .debs
	$(call PACK,libkeyfinder,DEB_LIBKEYFINDER_V)

	# libkeyfinder.mk Build cleanup
	rm -rf $(BUILD_DIST)/libkeyfinder

.PHONY: libkeyfinder libkeyfinder-package
