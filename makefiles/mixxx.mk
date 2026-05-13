ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += mixxx
MIXXX_VERSION := 2.5.0
DEB_MIXXX_V   ?= $(MIXXX_VERSION)

MIXXX_DEPS_TO_BUILD = chromaprint ffmpeg flac fftw googletest hidapi libdjinterop libebur128 libid3tag libkeyfinder libmad libmodplug libogg libopus libprotobuf libsndfile libtheora libvorbis lilv microsoft-gsl mpg123 opusfile portaudio portmidi qt rubberband soundtouch taglib wavpack
MIXXX_DEPS_TO_DOWNLOAD =
MIXXX_DEPS = $(MIXXX_DEPS_TO_BUILD) $(MIXXX_DEPS_TO_DOWNLOAD)
MIXXX_ALL_DEPS_TO_DOWNLOAD = $(shell $(BUILD_TOOLS)/calc_packages_deps.py $(MIXXX_DEPS_TO_DOWNLOAD))

mixxx-download-prebuilt-deps: setup
	@echo "Dependencies to download: $(MIXXX_DEPS_TO_DOWNLOAD)"
	@echo "List of packages to download:"
	@echo "$(MIXXX_ALL_DEPS_TO_DOWNLOAD)"
	@export BUILD_BASE="$(BUILD_BASE)" BUILD_DIST="$(BUILD_DIST)" \
		BUILD_WORK="$(BUILD_WORK)" DEB_ARCH="$(DEB_ARCH)" \
		MACOSX_SUITE_NAME="$(MACOSX_SUITE_NAME)" MAKE="$(MAKE)" \
		MEMO_CFVER="$(MEMO_CFVER)" MEMO_TARGET="$(MEMO_TARGET)"; \
		for dep in $(MIXXX_ALL_DEPS_TO_DOWNLOAD); do \
  			$(BUILD_TOOLS)/try_download_package.sh $$dep; \
  		done

mixxx-setup: setup
	$(call GIT_CLONE,https://github.com/Pe13/mixxx.git,ios,mixxx)

mixxx: setup mixxx-download-prebuilt-deps
	# Call the mixxx-build rule as another make run in order to not build the
	#  packages that are being downloaded
	+$(MAKE) -C $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST)))) mixxx-build NO_PGP=1

mixxx-remove-shared: $(MIXXX_DEPS)
	rm $(BUILD_BASE)/*/.dylib

ifneq ($(wildcard $(BUILD_WORK)/mixxx/.build_complete),)
mixxx-build:
	@echo "Using previously built mixxx."
else
mixxx-build: mixxx-setup $(MIXXX_DEPS)
	if [ ! -d $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++ ]; then \
		mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1; \
		cp -arf /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS17.2.sdk/usr/include/c++/v1/stdlib.h \
		$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1; \
		fi
	# Cleanup previous build artifacts if any
	rm -rf $(BUILD_WORK)/mixxx/Mixxx.tipa $(BUILD_WORK)/mixxx/Payload
	unset CC CXX LD CFLAGS CPPFLAGS CXXFLAGS LDFLAGS &&  \
		cmake -S $(BUILD_WORK)/mixxx -B $(BUILD_WORK)/mixxx/build \
		-DCMAKE_CROSSCOMPILING=true \
		-DCMAKE_SYSTEM_NAME=Darwin \
		-DCMAKE_SYSTEM_PROCESSOR="$(shell echo $(GNU_HOST_TRIPLE) | cut -f1 -d-)" \
		-DCMAKE_FIND_ROOT_PATH="$(BUILD_BASE)" \
		-DPKG_CONFIG_EXECUTABLE="$(BUILD_TOOLS)/cross-pkg-config" \
		-DCMAKE_OSX_SYSROOT="$(TARGET_SYSROOT)" \
		-DCMAKE_OSX_ARCHITECTURES="$(MEMO_ARCH)" \
		-G"Xcode" \
		-DIOS=ON \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DQT6=ON \
		-DOPUS=ON \
		-DMAD=ON \
		-DMODPLUG=ON \
		-DQTKEYCHAIN=OFF \
		-DBATTERY=OFF \
		-DBUILD_BENCH=OFF \
		-DBUILD_TESTING=OFF
	unset CC CXX LD CFLAGS CPPFLAGS CXXFLAGS LDFLAGS && \
		cmake --build $(BUILD_WORK)/mixxx/build --target mixxx --config RelWithDebInfo -- \
		IPHONEOS_DEPLOYMENT_TARGET=14.0 \
		CODE_SIGN_IDENTITY="" \
		CODE_SIGNING_REQUIRED=NO \
		OTHER_CPLUSPLUSFLAGS=" --std=c++20 -I$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1 -isystem$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include"
	# Tipa time
	mkdir $(BUILD_WORK)/mixxx/Payload
	cp -a $(BUILD_WORK)/mixxx/build/RelWithDebInfo-iphoneos/Mixxx.app $(BUILD_WORK)/mixxx/Payload
	cp -a $(BUILD_WORK)/mixxx/build/RelWithDebInfo-iphoneos/Mixxx.app.dSYM $(BUILD_WORK)/mixxx/Payload
	cd $(BUILD_WORK)/mixxx/; zip -r Mixxx.tipa Payload
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
