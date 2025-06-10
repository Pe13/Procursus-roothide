ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += qt
QT_VERSION    := 6.5.3
DEB_QT_V      ?= $(QT_VERSION)

qt-setup: setup
	$(call GITHUB_ARCHIVE,qt,qtbase,$(QT_VERSION),$(QT_VERSION))
	$(call EXTRACT_TAR,qtbase-$(QT_VERSION).tar.gz,qtbase-$(QT_VERSION),qt)
	mkdir -p $(BUILD_WORK)/qt/build-macos
	mkdir -p $(BUILD_WORK)/qt/build-ios

ifneq ($(wildcard $(BUILD_WORK)/qt/.build_complete),)
qt:
	@echo "Using previously built qt."
else
qt: qt-setup
	# Build for macos first, since this version won't probably match the system one
	cd $(BUILD_WORK)/qt/build-macos && ../configure \
		-prefix $(BUILD_WORK)/qt/macos-qt \
		-release \
		CC="$(CC_FOR_BUILD)" \
		CXX="$(CXX_FOR_BUILD)" \
		CPP="$(CPP_FOR_BUILD)" \
		AR="$(AR_FOR_BUILD)" \
		RANLIB="$(RANLIB_FOR_BUILD)" \
		STRIP="$(STRIP_FOR_BUILD)" \
		CFLAGS="$(CFLAGS_FOR_BUILD)" \
		CXXFLAGS="$(CXXFLAGS_FOR_BUILD)" \
		CPPFLAGS="$(CPPFLAGS_FOR_BUILD)" \
		ASFLAGS="$(ASFLAGS_FOR_BUILD)" \
		LDFLAGS="$(LDFLAGS_FOR_BUILD)"
	cmake --build $(BUILD_WORK)/qt/build-macos --parallel
	cmake --install $(BUILD_WORK)/qt/build-macos

	# Finally built Qt for iOS
	cd $(BUILD_WORK)/qt/build-ios && ../configure \
		-platform macx-ios-clang -release \
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
