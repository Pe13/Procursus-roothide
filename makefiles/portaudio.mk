ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS          += portaudio
PORTAUDIO_VERSION    := 19.8.0
PORTAUDIO_COMMIT := 3364bca3c01a0aedf64ba5a5abeb8e7019717ffc
DEB_PORTAUDIO_V      ?= $(PORTAUDIO_VERSION)

portaudio-setup: setup
	$(call DOWNLOAD_FILE,$(BUILD_SOURCE)/portaudio-$(PORTAUDIO_VERSION).zip,https://github.com/Be-ing/portaudio/archive/$(PORTAUDIO_COMMIT).zip)
	$(call EXTRACT_ZIP,portaudio-$(PORTAUDIO_VERSION).zip,portaudio-$(PORTAUDIO_COMMIT),portaudio)
ifeq (,$(findstring darwin,$(MEMO_TARGET)))
	$(call DO_PATCH,portaudio-ios,portaudio,-p1)
endif
	sed -i 's|-framework AudioUnit ||g' $(BUILD_WORK)/portaudio/configure.in

ifneq ($(wildcard $(BUILD_WORK)/portaudio/.build_complete),)
portaudio:
	@echo "Using previously built portaudio."
else
portaudio: portaudio-setup
	cmake -S $(BUILD_WORK)/portaudio -B $(BUILD_WORK)/portaudio/build \
		$(DEFAULT_CMAKE_FLAGS) \
		-DIOS=ON \
		-DBUILD_SHARED_LIBS=OFF
	+$(MAKE) -C $(BUILD_WORK)/portaudio/build
	+$(MAKE) -C $(BUILD_WORK)/portaudio/build install \
		DESTDIR="$(BUILD_STAGE)/portaudio"
	$(call AFTER_BUILD,copy)
endif

portaudio-package: portaudio-stage
	# portaudio.mk Package Structure
	rm -rf $(BUILD_DIST)/libportaudio{2,cpp0,19-dev}
	mkdir -p $(BUILD_DIST)/libportaudio{2,cpp0,19-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# portaudio.mk Prep libportaudio2
	cp -a $(BUILD_STAGE)/portaudio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libportaudio.2.dylib $(BUILD_DIST)/libportaudio2/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# portaudio.mk Prep libportaudiocpp0
	cp -a $(BUILD_STAGE)/portaudio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libportaudiocpp.0.dylib $(BUILD_DIST)/libportaudiocpp0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/

	# portaudio.mk Prep libportaudio19-dev
	cp -a $(BUILD_STAGE)/portaudio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{libportaudio{cpp,}.{dylib,a},pkgconfig} $(BUILD_DIST)/libportaudio19-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/
	cp -a $(BUILD_STAGE)/portaudio/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/libportaudio19-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/

	# portaudio.mk Sign
	$(call SIGN,libportaudio2,general.xml)
	$(call SIGN,libportaudiocpp0,general.xml)

	# portaudio.mk Make .debs
	$(call PACK,libportaudio2,DEB_PORTAUDIO_V)
	$(call PACK,libportaudiocpp0,DEB_PORTAUDIO_V)
	$(call PACK,libportaudio19-dev,DEB_PORTAUDIO_V)

	# portaudio.mk Build cleanup
	rm -rf $(BUILD_DIST)/libportaudio{2,cpp0,19-dev}

.PHONY: portaudio portaudio-package
