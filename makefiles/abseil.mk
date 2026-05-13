ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += abseil
ABSEIL_VERSION := 20250127.1
DEB_ABSEIL_V   ?= $(ABSEIL_VERSION)

abseil-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/abseil-cpp-$(ABSEIL_VERSION).tar.gz,https://github.com/abseil/abseil-cpp/archive/refs/tags/$(ABSEIL_VERSION).tar.gz)
	$(call EXTRACT_TAR,abseil-cpp-$(ABSEIL_VERSION).tar.gz,abseil-cpp-$(ABSEIL_VERSION),abseil)
	mkdir -p $(BUILD_WORK)/abseil/build

ifneq ($(wildcard $(BUILD_WORK)/abseil/.build_complete),)
abseil:
	@echo "Using previously built abseil."
else
abseil: abseil-setup
	cd $(BUILD_WORK)/abseil/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DABSL_PROPAGATE_CXX_STD=ON \
		..
	+$(MAKE) -C $(BUILD_WORK)/abseil/build
	+$(MAKE) -C $(BUILD_WORK)/abseil/build install \
		DESTDIR="$(BUILD_STAGE)/abseil"
	$(call AFTER_BUILD,copy)
endif

abseil-package: abseil-stage
	# abseil.mk Package Structure
	rm -rf $(BUILD_DIST)/abseil

	# abseil.mk Prep abseil
	cp -a $(BUILD_STAGE)/abseil $(BUILD_DIST)

	# abseil.mk Sign
	$(call SIGN,abseil,general.xml)

	# abseil.mk Make .debs
	$(call PACK,abseil,DEB_ABSEIL_V)

	# abseil.mk Build cleanup
	rm -rf $(BUILD_DIST)/abseil

.PHONY: abseil abseil-package
