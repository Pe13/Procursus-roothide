ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += mixxx
MIXXX_VERSION := 2.5.0
DEB_MIXXX_V   ?= $(MIXXX_VERSION)

MIXXX_DEPS = ffmpeg hidapi qt rubberband
MIXXX_DEPS_TO_BUILD += qt hidapi
MIXXX_DEPS_TO_DOWNLOAD = $(filter-out $(MIXXX_DEPS_TO_BUILD), $(MIXXX_DEPS))
MIXXX_ALL_DEPS_TO_DOWNLOAD = $(shell $(BUILD_TOOLS)/calc_packages_deps.py $(MIXXX_DEPS_TO_DOWNLOAD))

mixxx-download-prebuilt-deps: setup
	@echo "Dependencies to download: $(MIXXX_DEPS_TO_DOWNLOAD)"
	@echo "List of packages to download:"
	@echo "$(MIXXX_ALL_DEPS_TO_DOWNLOAD)"
	@for dep in $(MIXXX_ALL_DEPS_TO_DOWNLOAD); do \
  		$(BUILD_TOOLS)/try_download_package.sh $$dep; \
  		done

mixxx-setup: setup
	$(call GIT_CLONE,https://github.com/Pe13/mixxx.git,ios,mixxx)
	#$(call DO_PATCH,mixxx,mixxx,-p1)
	mkdir -p $(BUILD_WORK)/mixxx/build

mixxx: setup mixxx-download-prebuilt-deps
	+$(MAKE) -C $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST)))) mixxx-build

ifneq ($(wildcard $(BUILD_WORK)/mixxx/.build_complete),)
mixxx-build:
	@echo "Using previously built mixxx."
else
mixxx-build: mixxx-setup $(MIXXX_DEPS)
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
