ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += lilv
LILV_VERSION := 0.24.26
DEB_LILV_V   ?= $(LILV_VERSION)

lilv-setup: setup
	$(call GITHUB_ARCHIVE,lv2,lilv,$(LILV_VERSION),refs/tags/v$(LILV_VERSION))
	$(call EXTRACT_TAR,lilv-$(LILV_VERSION).tar.gz,lilv-$(LILV_VERSION),lilv)
	mkdir -p $(BUILD_WORK)/lilv/build

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
	pkg-config = '$(BUILD_TOOLS)/static-cross-pkg-config'\n \
	cmake = '/opt/procursus/bin/cmake'\n" > $(BUILD_WORK)/lilv/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/lilv/.build_complete),)
lilv:
	@echo "Using previously built lilv."
else
lilv: lilv-setup zix serd sord lv2 sratom
	cd $(BUILD_WORK)/lilv/build && meson \
		--cross-file cross.txt \
		..
	cd $(BUILD_WORK)/lilv/build && meson configure \
		-Dtests=disabled
	+ninja -C $(BUILD_WORK)/lilv/build
	+DESTDIR="$(BUILD_STAGE)/lilv" ninja -C $(BUILD_WORK)/lilv/build install
	$(call AFTER_BUILD,copy)
endif

lilv-package: lilv-stage
	# lilv.mk Package Structure
	rm -rf $(BUILD_DIST)/lilv

	# lilv.mk Prep lilv
	cp -a $(BUILD_STAGE)/lilv $(BUILD_DIST)

	# lilv.mk Sign
	$(call SIGN,lilv,general.xml)

	# lilv.mk Make .debs
	$(call PACK,lilv,DEB_LILV_V)

	# lilv.mk Build cleanup
	rm -rf $(BUILD_DIST)/lilv

.PHONY: lilv lilv-package
