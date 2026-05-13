ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += libpixman
LIBPIXMAN_VERSION := 0.46.4
DEB_LIBPIXMAN_V   ?= $(LIBPIXMAN_VERSION)

libpixman-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://cairographics.org/releases/pixman-$(LIBPIXMAN_VERSION).tar.gz)
	$(call EXTRACT_TAR,pixman-$(LIBPIXMAN_VERSION).tar.gz,pixman-$(LIBPIXMAN_VERSION),libpixman)
	mkdir -p $(BUILD_WORK)/libpixman/build
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
		pkg-config = '$(BUILD_TOOLS)/cross-pkg-config'\n" > $(BUILD_WORK)/libpixman/build/cross.txt

ifneq ($(wildcard $(BUILD_WORK)/libpixman/.build_complete),)
libpixman:
	@echo "Using previously built libpixman."
else
libpixman: libpixman-setup glib2.0
	cd $(BUILD_WORK)/libpixman/build && meson setup \
		--cross-file cross.txt \
		-Da64-neon=disabled \
		-Dgtk=disabled \
		-Dtests=disabled \
		..
	+ninja -C $(BUILD_WORK)/libpixman/build
	+DESTDIR="$(BUILD_STAGE)/libpixman" ninja -C $(BUILD_WORK)/libpixman/build install
	$(call AFTER_BUILD,copy)
endif

libpixman-package: libpixman-stage
	# libpixman.mk Package Structure
	rm -rf $(BUILD_DIST)/libpixman-1-0{-dev}
	mkdir -p $(BUILD_DIST)/libpixman-1-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libpixman-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{lib,include/pixman-1}

	# libpixman.mk Prep libpixman
	cp -a $(BUILD_STAGE)/libpixman/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libpixman-1.0*.dylib $(BUILD_DIST)/libpixman-1-0/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libpixman.mk Prep libpixman-dev
	cp -a $(BUILD_STAGE)/libpixman/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{pkgconfig,libpixman-1.{a,dylib}} $(BUILD_DIST)/libpixman-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libpixman/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pixman-1/* $(BUILD_DIST)/libpixman-1-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/pixman-1

	# libpixman.mk Sign
	$(call SIGN,libpixman-1-0,general.xml)

	# libpixman.mk Make .debs
	$(call PACK,libpixman-1-0,DEB_LIBPIXMAN_V)
	$(call PACK,libpixman-1-dev,DEB_LIBPIXMAN_V)

	# libpixman.mk Build cleanup
	rm -rf $(BUILD_DIST)/libpixman-1-0 \
		$(BUILD_DIST)/libpixman-1-dev

.PHONY: libpixman libpixman-package
