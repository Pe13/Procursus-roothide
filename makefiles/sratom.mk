ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += sratom
SRATOM_VERSION := 0.6.18
DEB_SRATOM_V   ?= $(SRATOM_VERSION)

sratom-setup: setup
	$(call GITHUB_ARCHIVE,lv2,sratom,$(SRATOM_VERSION),refs/tags/v$(SRATOM_VERSION))
	$(call EXTRACT_TAR,sratom-$(SRATOM_VERSION).tar.gz,sratom-$(SRATOM_VERSION),sratom)
	mkdir -p $(BUILD_WORK)/sratom/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/sratom/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/sratom/.build_complete),)
sratom:
	@echo "Using previously built sratom."
else
sratom: sratom-setup serd sord lv2
	cd $(BUILD_WORK)/sratom/build && meson \
		--cross-file cross.txt \
		..
	cd $(BUILD_WORK)/sratom/build && meson configure \
		-Dtests=disabled
	+ninja -C $(BUILD_WORK)/sratom/build
	+DESTDIR="$(BUILD_STAGE)/sratom" ninja -C $(BUILD_WORK)/sratom/build install
	$(call AFTER_BUILD,copy)
endif

sratom-package: sratom-stage
	# sratom.mk Package Structure
	rm -rf $(BUILD_DIST)/sratom

	# sratom.mk Prep sratom
	cp -a $(BUILD_STAGE)/sratom $(BUILD_DIST)

	# sratom.mk Sign
	$(call SIGN,sratom,general.xml)

	# sratom.mk Make .debs
	$(call PACK,sratom,DEB_SRATOM_V)

	# sratom.mk Build cleanup
	rm -rf $(BUILD_DIST)/sratom

.PHONY: sratom sratom-package
