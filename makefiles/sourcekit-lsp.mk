ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += sourcekit-lsp
SOURCEKIT_LSP_VERSION := 5.7
DEB_SOURCEKIT_LSP_V   ?= $(SOURCEKIT_LSP_VERSION)

DEPENDENCIES_CMAKE_ARGS := -DCMAKE_GENERATOR="Ninja" -DCMAKE_MAKE_PROGRAM="/opt/procursus/bin/ninja" \
				-DCMAKE_Swift_FLAGS="-target arm64-apple-ios15.0 -sdk $(TARGET_SYSROOT) -iframeworkXCTest"

sourcekit-lsp-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/sourcekit-lsp-$(SOURCEKIT_LSP_VERSION).tar.gz,https://github.com/swiftlang/sourcekit-lsp/archive/refs/heads/release/$(SOURCEKIT_LSP_VERSION).tar.gz)
	$(call EXTRACT_TAR,sourcekit-lsp-$(SOURCEKIT_LSP_VERSION).tar.gz,sourcekit-lsp-release-$(SOURCEKIT_LSP_VERSION),sourcekit-lsp)
#	$(call DO_PATCH,sourcekit-lsp,sourcekit-lsp,-p1)
	mkdir -p $(BUILD_WORK)/sourcekit-lsp/build

ifneq ($(wildcard $(BUILD_WORK)/sourcekit-lsp/.build_complete),)
sourcekit-lsp:
	@echo "Using previously built sourcekit-lsp."
else
sourcekit-lsp: sourcekit-lsp-setup
	# First fetch dependencies
	cd $(BUILD_WORK)/sourcekit-lsp && swift package show-dependencies
	# Then confiugre dependencies
	cd $(BUILD_WORK)/sourcekit-lsp/.build/checkouts/swift-argument-parser; mkdir -p build; cd build; \
		cmake . $(DEFAULT_CMAKE_FLAGS) \
			 $(DEPENDENCIES_CMAKE_ARGS) ..; \
		cmake --build . -j $$(sysctl -n hw.ncpu)
	cd $(BUILD_WORK)/sourcekit-lsp/.build/checkouts/swift-system; mkdir -p build; cd build; \
                cmake . $(DEFAULT_CMAKE_FLAGS) \
			 $(DEPENDENCIES_CMAKE_ARGS) ..
	# And finally build sourcekit
	cd $(BUILD_WORK)/sourcekit-lsp/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_GENERATOR="Ninja" \
		-DCMAKE_MAKE_PROGRAM="/opt/procursus/bin/ninja" \
		-DCMAKE_Swift_FLAGS="-target arm64-apple-ios15.0 -sdk $(TARGET_SYSROOT)" \
		-DArgumentParser_DIR="$(BUILD_WORK)/sourcekit-lsp/.build/checkouts/swift-argument-parser/build/cmake/modules" \
		-DSwiftSystem_DIR="$(BUILD_WORK)/sourcekit-lsp/.build/checkouts/swift-system/build/cmake/modules" ..
	+$(MAKE) -C $(BUILD_WORK)/sourcekit-lsp/build
	+$(MAKE) -C $(BUILD_WORK)/sourcekit-lsp/build install \
		DESTDIR="$(BUILD_STAGE)/sourcekit-lsp"
	$(call AFTER_BUILD)
endif

sourcekit-lsp-package: sourcekit-lsp-stage
	# sourcekit-lsp.mk Package Structure
	rm -rf $(BUILD_DIST)/sourcekit-lsp

	# sourcekit-lsp.mk Prep sourcekit-lsp
	cp -a $(BUILD_STAGE)/sourcekit-lsp $(BUILD_DIST)

	# sourcekit-lsp.mk Sign
	$(call SIGN,sourcekit-lsp,general.xml)

	# sourcekit-lsp.mk Make .debs
	$(call PACK,sourcekit-lsp,DEB_SOURCEKIT_LSP_V)

	# sourcekit-lsp.mk Build cleanup
	rm -rf $(BUILD_DIST)/sourcekit-lsp

.PHONY: sourcekit-lsp sourcekit-lsp-package
