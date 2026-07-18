ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += mixxx
MIXXX_VERSION := 2.6.0
DEB_MIXXX_V   ?= $(MIXXX_VERSION)

MIXXX_DEPS = chromaprint ffmpeg flac fftw googletest hidapi libdjinterop libebur128 libid3tag libkeyfinder libmad libmodplug libogg libopus libprotobuf libsndfile libtheora libvorbis lilv microsoft-gsl mpg123 opusfile portaudio portmidi qt rubberband soundtouch taglib wavpack

mixxx-devel-setup: setup
	$(call GIT_CLONE,https://github.com/Pe13/mixxx.git,ios,mixxx-devel)

mixxx-devel-configure: mixxx-devel-setup $(MIXXX_DEPS)
ifneq ($(UNAME),Linux)
	# WARNING: this action should be undone if you need to build a package that is not Mixxx
	if [ ! -d $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++ ]; then \
		mkdir -p $(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1; \
		cp -arf /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS17.2.sdk/usr/include/c++/v1/stdlib.h \
			$(BUILD_BASE)$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/c++/v1; \
		fi
endif
	rm -rf $(BUILD_WORK)/mixxx-devel/cmake-build-relwithdebinfo
	cmake -S $(BUILD_WORK)/mixxx-devel -B $(BUILD_WORK)/mixxx-devel/cmake-build-relwithdebinfo \
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


mixxx-devel-build: mixxx-devel-setup
	cmake --build $(BUILD_WORK)/mixxx-devel/cmake-build-relwithdebinfo --target mixxx --config RelWithDebInfo

	$(call AFTER_BUILD)


mixxx-devel-package:
	# Cleanup previous build artifacts if any
	rm -rf $(BUILD_WORK)/mixxx-devel/Mixxx.tipa $(BUILD_WORK)/mixxx-devel/Payload

	# Generate dSYM
	dsymutil $(BUILD_WORK)/mixxx-devel/cmake-build-relwithdebinfo/Mixxx.app/Mixxx \
		-o $(BUILD_WORK)/mixxx-devel/Mixxx.dSYM

	# Add entitlements to the executable
	$(LDID) -S$(BUILD_WORK)/mixxx-devel/packaging/ios/Mixxx-devel.entitlements \
		$(BUILD_WORK)/mixxx-devel/cmake-build-relwithdebinfo/Mixxx.app/Mixxx

	# Tipa time
	mkdir $(BUILD_WORK)/mixxx-devel/Payload
	cp -a $(BUILD_WORK)/mixxx-devel/cmake-build-relwithdebinfo/Mixxx.app \
		$(BUILD_WORK)/mixxx-devel/Payload
	cp -a $(BUILD_WORK)/mixxx-devel/packaging/ios/Assets.xcassets/AppIcon.appiconset/1024x1024.png \
		$(BUILD_WORK)/mixxx-devel/Payload/Mixxx.app/Icon.png
	cd $(BUILD_WORK)/mixxx-devel/ && \
		zip -r Mixxx.tipa Payload

mixxx-install: mixxx-package
ifeq ($(DEVICE_IP),)
	@echo "DEVICE_IP is not set. Please set it to the IP address of your iOS device in the make invokation."
	@exit 1
else
	# You need to run "nohup python3 -m http.server 8000 --directory /var/mobile" once on your iOS device before running this command.
	scp $(BUILD_WORK)/mixxx-devel/Mixxx.tipa mobile@$(DEVICE_IP):/var/mobile/Mixxx.tipa
	ssh mobile@$(DEVICE_IP) 'uiopen "apple-magnifier://install?url=http://127.0.0.1:8000/Mixxx.tipa"'
endif

.PHONY: mixxx mixxx-package mixxx-configure mixxx-build mixxx-install
