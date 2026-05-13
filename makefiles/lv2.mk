ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += lv2
LV2_VERSION := 1.18.10
DEB_LV2_V   ?= $(LV2_VERSION)

lv2-setup: setup
	$(call GITHUB_ARCHIVE,lv2,lv2,$(LV2_VERSION),refs/tags/v$(LV2_VERSION))
	$(call EXTRACT_TAR,lv2-$(LV2_VERSION).tar.gz,lv2-$(LV2_VERSION),lv2)
	mkdir -p $(BUILD_WORK)/lv2/build
	echo -e "[host_machine]\n \
	system = 'darwin'\n \
	cpu_family = '$(shell echo $(GNU_HOST_TRIPLE) | cut -d- -f1)'\n \
	cpu = '$(MEMO_ARCH)'\n \
	endian = 'little'\n \
	[properties]\n \
	root = '$(BUILD_BASE)'\n \
	[built-in options]\n \
	prefix ='$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)'\n \
	sysconfdir='$(MEMO_PREFIX)/etc'\n \
	localstatedir='$(MEMO_PREFIX)/var'\n \
	default_library='static'\n \
	[binaries]\n \
	c = '$(CC)'\n \
	cpp = '$(CXX)'\n \
	pkg-config = '$(BUILD_TOOLS)/static-cross-pkg-config'\n" > $(BUILD_WORK)/lv2/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/lv2/.build_complete),)
lv2:
	@echo "Using previously built lv2."
else
lv2: lv2-setup libsamplerate libsndfile
	cd $(BUILD_WORK)/lv2/build && meson setup \
		--cross-file cross.txt \
		-Dtests=disabled \
		..
	+ninja -C $(BUILD_WORK)/lv2/build
	+DESTDIR="$(BUILD_STAGE)/lv2" ninja -C $(BUILD_WORK)/lv2/build install
	$(call AFTER_BUILD,copy)
endif

lv2-package: lv2-stage
	# lv2.mk Package Structure
	rm -rf $(BUILD_DIST)/lv2

	# lv2.mk Prep lv2
	cp -a $(BUILD_STAGE)/lv2 $(BUILD_DIST)

	# lv2.mk Sign
	$(call SIGN,lv2,general.xml)

	# lv2.mk Make .debs
	$(call PACK,lv2,DEB_LV2_V)

	# lv2.mk Build cleanup
	rm -rf $(BUILD_DIST)/lv2

.PHONY: lv2 lv2-package
