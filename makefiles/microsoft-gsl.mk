ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += microsoft-gsl
MICROSOFT_GSL_VERSION := 4.1.0
DEB_MICROSOFT_GSL_V   ?= $(MICROSOFT_GSL_VERSION)

microsoft-gsl-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/microsoft-gsl-$(MICROSOFT_GSL_VERSION).tar.gz,https://github.com/microsoft/GSL/archive/refs/tags/v$(MICROSOFT_GSL_VERSION).tar.gz)
	$(call EXTRACT_TAR,microsoft-gsl-$(MICROSOFT_GSL_VERSION).tar.gz,GSL-$(MICROSOFT_GSL_VERSION),microsoft-gsl)
	mkdir -p $(BUILD_WORK)/microsoft-gsl/build

ifneq ($(wildcard $(BUILD_WORK)/microsoft-gsl/.build_complete),)
microsoft-gsl:
	@echo "Using previously built microsoft-gsl."
else
microsoft-gsl: microsoft-gsl-setup
	cd $(BUILD_WORK)/microsoft-gsl/build && cmake \
		$(DEFAULT_CMAKE_FLAGS) \
		-DGSL_TEST=OFF \
		-DGSL_INSTALL=ON \
		..
	+$(MAKE) -C $(BUILD_WORK)/microsoft-gsl/build
	+$(MAKE) -C $(BUILD_WORK)/microsoft-gsl/build install \
		DESTDIR="$(BUILD_STAGE)/microsoft-gsl"
	$(call AFTER_BUILD,copy)
endif

microsoft-gsl-package: microsoft-gsl-stage
	# microsoft-gsl.mk Package Structure
	rm -rf $(BUILD_DIST)/microsoft-gsl

	# microsoft-gsl.mk Prep microsoft-gsl
	cp -a $(BUILD_STAGE)/microsoft-gsl $(BUILD_DIST)

	# microsoft-gsl.mk Sign
	$(call SIGN,microsoft-gsl,general.xml)

	# microsoft-gsl.mk Make .debs
	$(call PACK,microsoft-gsl,DEB_MICROSOFT_GSL_V)

	# microsoft-gsl.mk Build cleanup
	rm -rf $(BUILD_DIST)/microsoft-gsl

.PHONY: microsoft-gsl microsoft-gsl-package
