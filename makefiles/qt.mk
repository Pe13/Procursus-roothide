ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += qt
QT_VERSION    := 6.5.3
DEB_QT_V      ?= $(QT_VERSION)

space := $(subst ,, )

QT_SUBMODULES = qt5compat qtbase qtdeclarative qtshadertools qtsvg qttools qttranslations
QT_SUBMODULES_WITH_COMMAS = $(subst $(space),$(comma),$(QT_SUBMODULES))

SUBMODULES_FLAGS = -submodules $(QT_SUBMODULES_WITH_COMMAS)

ifneq ($(wildcard $(BUILD_WORK)/qt/.setup-complete),)
qt-setup:
	@echo "Qt build tree already setupped"
else
qt-setup: setup libpng16-setup
	# Download qt main build tree and all the submodules needed
	$(call GITHUB_ARCHIVE,qt,qt5,$(QT_VERSION),v$(QT_VERSION))
	for module in $(QT_SUBMODULES); do \
  		if [ ! -f "$(BUILD_SOURCE)/$${module}-$(QT_VERSION).tar.gz" ]; then \
		  cd $(BUILD_SOURCE); \
		  wget https://github.com/qt/$${module}/archive/v$(QT_VERSION).tar.gz \
		    -O $${module}-$(QT_VERSION).tar.gz; \
  		fi \
	done

	# Recreate the entire build tree
	$(call EXTRACT_TAR,qt5-$(QT_VERSION).tar.gz,qt5-$(QT_VERSION),qt)
	rm -r $(BUILD_WORK)/qt/{$(QT_SUBMODULES_WITH_COMMAS)}
	for module in $(QT_SUBMODULES); do \
	  cd $(BUILD_WORK); \
	  tar -xf "$(BUILD_SOURCE)/$${module}-$(QT_VERSION).tar.gz"; \
	  mkdir qt/$${module}; \
	  cp -a $${module}-$(QT_VERSION)/. qt/$${module}; \
	  rm -rf $${module}-$(QT_VERSION); \
	done
	cd $(BUILD_WORK)/qt/qttools/src/assistant && \
		git clone https://code.qt.io/playground/qlitehtml.git && \
		(cd qlitehtml && git checkout f05f78e && git submodule update --init --recursive) && \
		rm -rf qlitehtml/.git

	mkdir -p $(BUILD_WORK)/qt/build-host
	mkdir -p $(BUILD_WORK)/qt/build-ios

	# Bundle an updated libpng too since I can't get qt finding the system one :'(
	$(BUILD_WORK)/qt/qtbase/src/3rdparty/libpng/import_from_libpng_tarball.sh \
		$(BUILD_WORK)/libpng16 \
		$(BUILD_WORK)/qt/qtbase/src/3rdparty/libpng

	touch $(BUILD_WORK)/qt/.setup-complete
endif

ifneq ($(wildcard $(BUILD_WORK)/qt/.host_build_complete),)
qt-host:
	@echo "Using previously built host qt."
else
qt-host: qt-setup
	# Build for host first, since this version won't probably match the system one
	cd $(BUILD_WORK)/qt/build-host && \
		unset CC CXX CPP CFLAGS CXXFLAGS ASFLAGS CXXFLAGS CPPFLAGS LDFLAGS && \
		../configure \
		-prefix $(BUILD_WORK)/qt/host-qt \
		-release \
		-static \
		-system-zlib \
		-qt-libjpeg \
		-qt-libpng \
		-qt-freetype \
		-qt-pcre \
		-qt-harfbuzz \
		$(SUBMODULES_FLAGS) \
		-feature-assistant \
		-developer-build \
		-nomake tests
	cmake --build $(BUILD_WORK)/qt/build-host --parallel --target host_tools
	# cmake --install $(BUILD_WORK)/qt/build-host
	touch $(BUILD_WORK)/qt/.host_build_complete
endif

ifneq ($(wildcard $(BUILD_WORK)/qt/.build_complete),)
qt:
	@echo "Using previously built qt."
else
qt: qt-setup qt-host libpng16
	# Qt relies on the SDK os/log.h, we must temporarily move the pure Darwin
	# one away
	mv $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os/log.h $(BUILD_WORK)/log.h
	cd $(BUILD_WORK)/qt/build-ios && \
		export SDKROOT="$(TARGET_SYSROOT)" && \
		../configure \
		-platform macx-ios-clang \
		-release \
		-static \
		-qt-host-path $(BUILD_WORK)/qt/build-host \
		-prefix $(BUILD_STAGE)/qt/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(SUBMODULES_FLAGS) \
		-- \
		-DCMAKE_TOOLCHAIN_FILE=$(BUILD_ROOT)/build_tools/cmake/ios.toolchain.cmake \
		-DQT_UIKIT_SDK=iphoneos \
		-DQT_BUILD_SIMULATOR=OFF
	cmake --build $(BUILD_WORK)/qt/build-ios --parallel
	cmake --install $(BUILD_WORK)/qt/build-ios
	# Restore the Darwin log.h
	mv $(BUILD_WORK)/log.h $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/os/log.h
	$(call AFTER_BUILD,copy)
endif

qt-package: qt-stage
	# qt.mk Package Structure
	rm -rf $(BUILD_DIST)/qt

	# qt.mk Prep qt
	cp -a $(BUILD_STAGE)/qt $(BUILD_DIST)

	# qt.mk Sign
	$(call SIGN,qt,general.xml)

	# qt.mk Make .debs
	$(call PACK,qt,DEB_QT_V)

	# qt.mk Build cleanup
	rm -rf $(BUILD_DIST)/qt

.PHONY: qt qt-package
