ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += mixxx
MIXXX_VERSION := 2.6.0
DEB_MIXXX_V   ?= $(MIXXX_VERSION)

mixxx-setup: setup
	$(call GIT_CLONE,https://github.com/Pe13/mixxx.git,ios,mixxx)

ifneq ($(wildcard $(BUILD_WORK)/mixxx/.build_complete),)
mixxx-build:
	@echo "Using previously built mixxx."
else
mixxx: mixxx-configure mixxx-build mixxx-package
	@echo
	@echo
	@echo "--------------------------------"
	@echo
	@echo "Mixxx.tipa is located at: $(BUILD_WORK)/mixxx/Mixxx.tipa"
	$(call AFTER_BUILD)
endif

mixxx-configure: mixxx-setup chromaprint ffmpeg flac fftw googletest hidapi libdjinterop libebur128 libid3tag libkeyfinder libmad libmodplug libogg libopus libprotobuf libsndfile libtheora libvorbis lilv microsoft-gsl mpg123 opusfile portaudio portmidi qt rubberband soundtouch taglib wavpack
ifneq ($(UNAME),Linux)
	if [ ! -d $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++ ]; then \
		mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1; \
		cp -arf /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS17.2.sdk/usr/include/c++/v1/stdlib.h \
		$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1; \
		fi
endif
	rm -rf $(BUILD_WORK)/mixxx/build
	cmake -S $(BUILD_WORK)/mixxx -B $(BUILD_WORK)/mixxx/build \
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

mixxx-build: mixxx-configure
	cmake --build $(BUILD_WORK)/mixxx/build --target mixxx


mixxx-package: mixxx-build
	# Cleanup previous build artifacts if any
	rm -rf $(BUILD_WORK)/mixxx/Mixxx.tipa $(BUILD_WORK)/mixxx/Payload

	# Add entitlements to the executable
	$(LDID) -S$(BUILD_WORK)/mixxx/packaging/ios/Mixxx.entitlements \
		$(BUILD_WORK)/mixxx/build/Mixxx.app/Mixxx

	# Tipa time
	mkdir $(BUILD_WORK)/mixxx/Payload
	cp -a $(BUILD_WORK)/mixxx/build/Mixxx.app \
		$(BUILD_WORK)/mixxx/Payload
	cp -a $(BUILD_WORK)/mixxx/packaging/ios/Assets.xcassets/AppIcon.appiconset/1024x1024.png \
		$(BUILD_WORK)/mixxx/Payload/Mixxx.app/Icon.png
	cd $(BUILD_WORK)/mixxx/ && \
		zip -r Mixxx.tipa Payload

.PHONY: mixxx mixxx-package mixxx-configure mixxx-build mixxx-install
