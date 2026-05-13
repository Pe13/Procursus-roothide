ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += chromaprint
CHROMAPRINT_VERSION := 1.6.0
DEB_CHROMAPRINT_V   ?= $(CHROMAPRINT_VERSION)

chromaprint-setup: setup
	$(call GITHUB_ARCHIVE,acoustid,chromaprint,$(CHROMAPRINT_VERSION),v$(CHROMAPRINT_VERSION))
	$(call EXTRACT_TAR,chromaprint-$(CHROMAPRINT_VERSION).tar.gz,chromaprint-$(CHROMAPRINT_VERSION),chromaprint)
	mkdir -p $(BUILD_WORK)/chromaprint/build

ifneq ($(wildcard $(BUILD_WORK)/chromaprint/.build_complete),)
chromaprint:
	@echo "Using previously built chromaprint."
else
chromaprint: chromaprint-setup ffmpeg fftw
	cd $(BUILD_WORK)/chromaprint/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DBUILD_TESTS=OFF \
		-DBUILD_SHARED_LIBS=OFF \
		..
	+$(MAKE) -C $(BUILD_WORK)/chromaprint/build
	+$(MAKE) -C $(BUILD_WORK)/chromaprint/build install \
		DESTDIR="$(BUILD_STAGE)/chromaprint"
	$(call AFTER_BUILD,copy)
endif

chromaprint-package: chromaprint-stage
	# chromaprint.mk Package Structure
	rm -rf $(BUILD_DIST)/chromaprint

	# chromaprint.mk Prep chromaprint
	cp -a $(BUILD_STAGE)/chromaprint $(BUILD_DIST)

	# chromaprint.mk Sign
	$(call SIGN,chromaprint,general.xml)

	# chromaprint.mk Make .debs
	$(call PACK,chromaprint,DEB_CHROMAPRINT_V)

	# chromaprint.mk Build cleanup
	rm -rf $(BUILD_DIST)/chromaprint

.PHONY: chromaprint chromaprint-package
