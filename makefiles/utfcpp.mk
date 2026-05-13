ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += utfcpp
UTFCPP_VERSION := 4.0.8
DEB_UTFCPP_V   ?= $(UTFCPP_VERSION)

utfcpp-setup: setup
	$(call GITHUB_ARCHIVE,nemtrif,utfcpp,$(UTFCPP_VERSION),v$(UTFCPP_VERSION))
	$(call EXTRACT_TAR,utfcpp-$(UTFCPP_VERSION).tar.gz,utfcpp-$(UTFCPP_VERSION),utfcpp)
	mkdir -p $(BUILD_WORK)/utfcpp/build

ifneq ($(wildcard $(BUILD_WORK)/utfcpp/.build_complete),)
utfcpp:
	@echo "Using previously built utfcpp."
else
utfcpp: utfcpp-setup
	cd $(BUILD_WORK)/utfcpp/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/utfcpp/build
	+$(MAKE) -C $(BUILD_WORK)/utfcpp/build install \
		DESTDIR="$(BUILD_STAGE)/utfcpp"
	$(call AFTER_BUILD,copy)
endif

utfcpp-package: utfcpp-stage
	# utfcpp.mk Package Structure
	rm -rf $(BUILD_DIST)/utfcpp

	# utfcpp.mk Prep utfcpp
	cp -a $(BUILD_STAGE)/utfcpp $(BUILD_DIST)

	# utfcpp.mk Sign
	$(call SIGN,utfcpp,general.xml)

	# utfcpp.mk Make .debs
	$(call PACK,utfcpp,DEB_UTFCPP_V)

	# utfcpp.mk Build cleanup
	rm -rf $(BUILD_DIST)/utfcpp

.PHONY: utfcpp utfcpp-package
