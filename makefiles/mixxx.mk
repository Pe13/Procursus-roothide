ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += mixxx
MIXXX_VERSION := 2.5.0
DEB_MIXXX_V   ?= $(MIXXX_VERSION)

mixxx-setup: setup
	$(call GIT_CLONE,https://github.com/Pe13/mixxx.git,ios,mixxx)
	#$(call DO_PATCH,mixxx,mixxx,-p1)
	mkdir -p $(BUILD_WORK)/mixxx/build

ifneq ($(wildcard $(BUILD_WORK)/mixxx/.build_complete),)
mixxx:
	@echo "Using previously built mixxx."
else
mixxx: mixxx-setup ffmpeg qt rubberband
	cd $(BUILD_WORK)/mixxx/build && cmake . \
		-G"Xcode" \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DQT6=ON \
		-DQTKEYCHAIN=OFF \
		-DBATTERY=OFF \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		..
	+$(MAKE) -C $(BUILD_WORK)/mixxx/build
	+$(MAKE) -C $(BUILD_WORK)/mixxx/build install \
		DESTDIR="$(BUILD_STAGE)/mixxx"
	$(call AFTER_BUILD)
endif

mixxx-package: mixxx-stage
	# mixxx.mk Package Structure
	rm -rf $(BUILD_DIST)/mixxx

	# mixxx.mk Prep mixxx
	cp -a $(BUILD_STAGE)/mixxx $(BUILD_DIST)

	# mixxx.mk Sign
	$(call SIGN,mixxx,general.xml)

	# mixxx.mk Make .debs
	$(call PACK,mixxx,DEB_MIXXX_V)

	# mixxx.mk Build cleanup
	rm -rf $(BUILD_DIST)/mixxx

.PHONY: mixxx mixxx-package
