ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += taglib
TAGLIB_VERSION := 2.1.1
DEB_TAGLIB_V   ?= $(TAGLIB_VERSION)

taglib-setup: setup
	$(call GITHUB_ARCHIVE,taglib,taglib,$(TAGLIB_VERSION),v$(TAGLIB_VERSION))
	$(call EXTRACT_TAR,taglib-$(TAGLIB_VERSION).tar.gz,taglib-$(TAGLIB_VERSION),taglib)
	mkdir -p $(BUILD_WORK)/taglib/build

ifneq ($(wildcard $(BUILD_WORK)/taglib/.build_complete),)
taglib:
	@echo "Using previously built taglib."
else
taglib: taglib-setup utfcpp
	cd $(BUILD_WORK)/taglib/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/taglib/build
	+$(MAKE) -C $(BUILD_WORK)/taglib/build install \
		DESTDIR="$(BUILD_STAGE)/taglib"
	$(call AFTER_BUILD,copy)
endif

taglib-package: taglib-stage
	# taglib.mk Package Structure
	rm -rf $(BUILD_DIST)/taglib

	# taglib.mk Prep taglib
	cp -a $(BUILD_STAGE)/taglib $(BUILD_DIST)

	# taglib.mk Sign
	$(call SIGN,taglib,general.xml)

	# taglib.mk Make .debs
	$(call PACK,taglib,DEB_TAGLIB_V)

	# taglib.mk Build cleanup
	rm -rf $(BUILD_DIST)/taglib

.PHONY: taglib taglib-package
