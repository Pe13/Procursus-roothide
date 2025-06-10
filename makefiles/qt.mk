ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += qt
QT_VERSION    := 6.5.3
DEB_QT_V      ?= $(QT_VERSION)

qt-setup: setup
	$(call GITHUB_ARCHIVE,qt,qtbase,$(QT_VERSION),$(QT_VERSION))
	$(call EXTRACT_TAR,qtbase-$(QT_VERSION).tar.gz,qtbase-$(QT_VERSION),qt)
	#$(call DO_PATCH,qt,qt,-p1)
	mkdir -p $(BUILD_WORK)/qt/build

ifneq ($(wildcard $(BUILD_WORK)/qt/.build_complete),)
qt:
	@echo "Using previously built qt."
else
qt: qt-setup
	cd $(BUILD_WORK)/qt/build && ../configure \
		-platform macx-ios-clang -release \
		-qt-host-path /usr/local/Cellar/qt
	cmake --build $(BUILD_WORK)/qt/build --parallel
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
