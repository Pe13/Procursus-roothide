ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += serd
SERD_VERSION := 0.32.4
DEB_SERD_V   ?= $(SERD_VERSION)

serd-setup: setup
	$(call GITHUB_ARCHIVE,drobilla,serd,$(SERD_VERSION),refs/tags/v$(SERD_VERSION))
	$(call EXTRACT_TAR,serd-$(SERD_VERSION).tar.gz,serd-$(SERD_VERSION),serd)
	mkdir -p $(BUILD_WORK)/serd/build
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
	pkg-config = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/serd/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/serd/.build_complete),)
serd:
	@echo "Using previously built serd."
else
serd: serd-setup
	cd $(BUILD_WORK)/serd/build && meson \
		--cross-file cross.txt \
		..
	cd $(BUILD_WORK)/serd/build && meson configure \
		-Dtests=disabled
	+ninja -C $(BUILD_WORK)/serd/build
	+DESTDIR="$(BUILD_STAGE)/serd" ninja -C $(BUILD_WORK)/serd/build install
	$(call AFTER_BUILD,copy)
endif

serd-package: serd-stage
	# serd.mk Package Structure
	rm -rf $(BUILD_DIST)/serd

	# serd.mk Prep serd
	cp -a $(BUILD_STAGE)/serd $(BUILD_DIST)

	# serd.mk Sign
	$(call SIGN,serd,general.xml)

	# serd.mk Make .debs
	$(call PACK,serd,DEB_SERD_V)

	# serd.mk Build cleanup
	rm -rf $(BUILD_DIST)/serd

.PHONY: serd serd-package
