ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += zix
ZIX_VERSION := 0.6.2
DEB_ZIX_V   ?= $(ZIX_VERSION)

zix-setup: setup
	$(call GITHUB_ARCHIVE,drobilla,zix,$(ZIX_VERSION),refs/tags/v$(ZIX_VERSION))
	$(call EXTRACT_TAR,zix-$(ZIX_VERSION).tar.gz,zix-$(ZIX_VERSION),zix)
	mkdir -p $(BUILD_WORK)/zix/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/zix/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/zix/.build_complete),)
zix:
	@echo "Using previously built zix."
else
zix: zix-setup
	cd $(BUILD_WORK)/zix/build && meson \
		--cross-file cross.txt \
		..
	cd $(BUILD_WORK)/zix/build && meson configure \
		-Dtests=disabled \
		-Dtests_cpp=disabled \
		-Dbenchmarks=disabled
	+ninja -C $(BUILD_WORK)/zix/build
	+DESTDIR="$(BUILD_STAGE)/zix" ninja -C $(BUILD_WORK)/zix/build install
	$(call AFTER_BUILD,copy)
endif

zix-package: zix-stage
	# zix.mk Package Structure
	rm -rf $(BUILD_DIST)/zix

	# zix.mk Prep zix
	cp -a $(BUILD_STAGE)/zix $(BUILD_DIST)

	# zix.mk Sign
	$(call SIGN,zix,general.xml)

	# zix.mk Make .debs
	$(call PACK,zix,DEB_ZIX_V)

	# zix.mk Build cleanup
	rm -rf $(BUILD_DIST)/zix

.PHONY: zix zix-package
