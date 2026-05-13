ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += sord
SORD_VERSION := 0.16.18
DEB_SORD_V   ?= $(SORD_VERSION)

sord-setup: setup
	$(call GITHUB_ARCHIVE,drobilla,sord,$(SORD_VERSION),refs/tags/v$(SORD_VERSION))
	$(call EXTRACT_TAR,sord-$(SORD_VERSION).tar.gz,sord-$(SORD_VERSION),sord)
	mkdir -p $(BUILD_WORK)/sord/build
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
	pkgconfig = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/sord/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/sord/.build_complete),)
sord:
	@echo "Using previously built sord."
else
sord: sord-setup zix serd pcre2
	cd $(BUILD_WORK)/sord/build && meson setup \
		--cross-file cross.txt \
		-Dtests=disabled \
		..
	+ninja -C $(BUILD_WORK)/sord/build
	+DESTDIR="$(BUILD_STAGE)/sord" ninja -C $(BUILD_WORK)/sord/build install
	$(call AFTER_BUILD,copy)
endif

sord-package: sord-stage
	# sord.mk Package Structure
	rm -rf $(BUILD_DIST)/sord

	# sord.mk Prep sord
	cp -a $(BUILD_STAGE)/sord $(BUILD_DIST)

	# sord.mk Sign
	$(call SIGN,sord,general.xml)

	# sord.mk Make .debs
	$(call PACK,sord,DEB_SORD_V)

	# sord.mk Build cleanup
	rm -rf $(BUILD_DIST)/sord

.PHONY: sord sord-package
