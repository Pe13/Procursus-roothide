ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += soundtouch
SOUNDTOUCH_VERSION := 2.4.0
DEB_SOUNDTOUCH_V   ?= $(SOUNDTOUCH_VERSION)

soundtouch-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://www.surina.net/soundtouch/soundtouch-$(SOUNDTOUCH_VERSION).tar.gz)
	$(call EXTRACT_TAR,soundtouch-$(SOUNDTOUCH_VERSION).tar.gz,soundtouch-$(SOUNDTOUCH_VERSION),soundtouch)
	mkdir -p $(BUILD_WORK)/soundtouch/build

ifneq ($(wildcard $(BUILD_WORK)/soundtouch/.build_complete),)
soundtouch:
	@echo "Using previously built soundtouch."
else
soundtouch: soundtouch-setup
	cd $(BUILD_WORK)/soundtouch/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/soundtouch/build
	+$(MAKE) -C $(BUILD_WORK)/soundtouch/build install \
		DESTDIR="$(BUILD_STAGE)/soundtouch"
	$(call AFTER_BUILD,copy)
endif

soundtouch-package: soundtouch-stage
	# soundtouch.mk Package Structure
	rm -rf $(BUILD_DIST)/soundtouch

	# soundtouch.mk Prep soundtouch
	cp -a $(BUILD_STAGE)/soundtouch $(BUILD_DIST)

	# soundtouch.mk Sign
	$(call SIGN,soundtouch,general.xml)

	# soundtouch.mk Make .debs
	$(call PACK,soundtouch,DEB_SOUNDTOUCH_V)

	# soundtouch.mk Build cleanup
	rm -rf $(BUILD_DIST)/soundtouch

.PHONY: soundtouch soundtouch-package
