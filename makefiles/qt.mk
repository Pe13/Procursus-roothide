ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += qt
QT_VERSION    := 6.5.3
DEB_QT_V      ?= $(QT_VERSION)


qt-setup: setup libpng16-setup
	$(call GITHUB_ARCHIVE,qt,qtbase,$(QT_VERSION),$(QT_VERSION))
	$(call EXTRACT_TAR,qtbase-$(QT_VERSION).tar.gz,qtbase-$(QT_VERSION),qt)
	
	# Bundle an updated libpng too since I can't let qt find the system one :'(
	$(BUILD_WORK)/qt/src/3rdparty/libpng/import_from_libpng_tarball.sh \
		$(BUILD_WORK)/libpng16 \
		$(BUILD_WORK)/qt/src/3rdparty/libpng
	
	mkdir -p $(BUILD_WORK)/qt/build-macos
	mkdir -p $(BUILD_WORK)/qt/build-ios

ifneq ($(wildcard $(BUILD_WORK)/qt/.macos_build_complete),)
qt-macos:
	@echo "Using previously built macos qt."
else
qt-macos: qt-setup
	# Build for macos first, since this version won't probably match the system one
	cd $(BUILD_WORK)/qt/build-macos && \
		unset CFLAGS CXXFLAGS ASFLAGS CXXFLAGS CPPFLAGS LDFLAGS && \
		../configure \
		-prefix $(BUILD_WORK)/qt/macos-qt \
		-release \
		-system-zlib \
		-qt-libjpeg \
		-no-libpng \
		-qt-freetype \
		-qt-pcre \
		-qt-harfbuzz
	cmake --build $(BUILD_WORK)/qt/build-macos --parallel
	cmake --install $(BUILD_WORK)/qt/build-macos
	touch $(BUILD_WORK)/qt/.macos_build_complete
endif

ifneq ($(wildcard $(BUILD_WORK)/qt/.build_complete),)
qt:
	@echo "Using previously built qt."
else
qt: qt-setup qt-macos libpng16
	cd $(BUILD_WORK)/qt/build-ios && \
		unset CFLAGS CXXFLAGS ASFLAGS CXXFLAGS CPPFLAGS LDFLAGS && \
		../configure \
		-platform macx-ios-clang \
		-release \
		-qt-host-path $(BUILD_WORK)/qt/macos-qt \
		-sdk iphoneos \
		-prefix $(BUILD_STAGE)/qt
	cmake --build $(BUILD_WORK)/qt/build-ios --parallel
	cmake --install $(BUILD_WORK)/qt/build-ios
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
