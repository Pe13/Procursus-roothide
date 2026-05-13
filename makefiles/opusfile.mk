ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += opusfile
OPUSFILE_VERSION := 0.12
DEB_OPUSFILE_V   ?= $(OPUSFILE_VERSION)

opusfile-setup: setup
	$(call GITHUB_ARCHIVE,xiph,opusfile,$(OPUSFILE_VERSION),refs/tags/v$(OPUSFILE_VERSION))
	$(call EXTRACT_TAR,opusfile-$(OPUSFILE_VERSION).tar.gz,opusfile-$(OPUSFILE_VERSION),opusfile)

ifneq ($(wildcard $(BUILD_WORK)/opusfile/.build_complete),)
opusfile:
	@echo "Using previously built opusfile."
else
opusfile: opusfile-setup openssl
	cd $(BUILD_WORK)/opusfile && autoreconf -fi && \
		./configure -C \
		$(DEFAULT_CONFIGURE_FLAGS)
	+$(MAKE) -C $(BUILD_WORK)/opusfile
	+$(MAKE) -C $(BUILD_WORK)/opusfile install \
		DESTDIR=$(BUILD_STAGE)/opusfile
	$(call AFTER_BUILD,copy)
endif

opusfile-package: opusfile-stage
	# opusfile.mk Package Structure
	rm -rf $(BUILD_DIST)/opusfile

	# opusfile.mk Prep opusfile
	cp -a $(BUILD_STAGE)/opusfile $(BUILD_DIST)

	# opusfile.mk Sign
	$(call SIGN,opusfile,general.xml)

	# opusfile.mk Make .debs
	$(call PACK,opusfile,DEB_OPUSFILE_V)

	# opusfile.mk Build cleanup
	rm -rf $(BUILD_DIST)/opusfile

.PHONY: opusfile opusfile-package
