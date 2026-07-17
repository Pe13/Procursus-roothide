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

mixxx-setup: setup
	$(call GIT_CLONE,https://github.com/Pe13/mixxx.git,ios,mixxx)

mixxx: mixxx-configure mixxx-build mixxx-package


mixxx-remove-shared: $(MIXXX_DEPS)
	rm $(BUILD_BASE)/*/.dylib

mixxx-configure: mixxx-setup $(MIXXX_DEPS)
ifneq ($(UNAME),Linux)
	if [ ! -d $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++ ]; then \
		mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1; \
		cp -arf /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS17.2.sdk/usr/include/c++/v1/stdlib.h \
		$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1; \
		fi
endif
	rm -rf $(BUILD_WORK)/mixxx/cmake-build-relwithdebinfo
	cmake -S $(BUILD_WORK)/mixxx -B $(BUILD_WORK)/mixxx/cmake-build-relwithdebinfo \
		$(DEFAULT_CMAKE_FLAGS) \
		-DRIGHT_PROTOC="$(BUILD_WORK)/libprotobuf/build-host/protoc" \
		-DCMAKE_PREFIX_PATH="$(BUILD_BASE)/usr/;$(TARGET_SYSROOT)/usr" \
		-DCMAKE_FRAMEWORK_PATH="$(TARGET_SYSROOT)/Developer/Library/Frameworks;$(TARGET_SYSROOT)/System/Library/Frameworks" \
		-DCMAKE_FIND_USE_CMAKE_PATH=ON \
		-DCMAKE_FIND_USE_CMAKE_ENVIRONMENT_PATH=OFF \
		-DCMAKE_FIND_USE_SYSTEM_ENVIRONMENT_PATH=ON \
		-DCMAKE_FIND_USE_CMAKE_SYSTEM_PATH=OFF \
		-DCMAKE_FIND_USE_INSTALL_PREFIX=ON \
		-DCMAKE_MAKE_PROGRAM="/usr/bin/ninja" \
		-DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 \
		-G"Ninja" \
		-DIOS=ON \
		-DCMAKE_BUILD_TYPE=RelWithDebInfo \
		-DQT6=ON \
		-DOPUS=ON \
		-DMAD=ON \
		-DMODPLUG=ON \
		-DQTKEYCHAIN=OFF \
		-DBATTERY=OFF \
		-DBUILD_BENCH=OFF \
		-DBUILD_TESTING=OFF \
		-DQT_NO_SET_DEFAULT_IOS_LAUNCH_SCREEN=ON \
		-DQT_NO_ADD_IOS_LAUNCH_SCREEN_TO_BUNDLE=ON

ifneq ($(wildcard $(BUILD_WORK)/mixxx/.build_complete),)
mixxx-build:
	@echo "Using previously built mixxx."
else
mixxx-build: mixxx-setup $(MIXXX_DEPS)
	cmake --build $(BUILD_WORK)/mixxx/cmake-build-relwithdebinfo --target mixxx --config RelWithDebInfo

	$(call AFTER_BUILD)
endif


mixxx-package:
	# Cleanup previous build artifacts if any
	rm -rf $(BUILD_WORK)/mixxx/Mixxx.tipa $(BUILD_WORK)/mixxx/Payload

	# Generate dSYM
	dsymutil $(BUILD_WORK)/mixxx/cmake-build-relwithdebinfo/Mixxx.app/Mixxx \
		-o $(BUILD_WORK)/mixxx/Mixxx.dSYM

	# Add entitlements to the executable
	$(LDID) -S$(BUILD_WORK)/mixxx/packaging/macos/Mixxx.entitlements \
		$(BUILD_WORK)/mixxx/cmake-build-relwithdebinfo/Mixxx.app/Mixxx

	# Tipa time
	mkdir $(BUILD_WORK)/mixxx/Payload
	cp -a $(BUILD_WORK)/mixxx/cmake-build-relwithdebinfo/Mixxx.app \
		$(BUILD_WORK)/mixxx/Payload
	cp -a $(BUILD_WORK)/mixxx/packaging/ios/Assets.xcassets/AppIcon.appiconset/1024x1024.png \
		$(BUILD_WORK)/mixxx/Payload/Mixxx.app/Icon.png
	cd $(BUILD_WORK)/mixxx/ && \
		zip -r Mixxx.tipa Payload

.PHONY: mixxx mixxx-package
