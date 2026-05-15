ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS         += libprotobuf
LIBPROTOBUF_VERSION := 3.31.1
FOR_DOWNLOAD_VERSION = $(shell echo $(LIBPROTOBUF_VERSION) | cut -d. -f2-)
DEB_LIBPROTOBUF_V   ?= $(LIBPROTOBUF_VERSION)

libprotobuf-setup: setup
	$(call DOWNLOAD_FILES,$(BUILD_SOURCE),https://github.com/protocolbuffers/protobuf/releases/download/v$(FOR_DOWNLOAD_VERSION)/protobuf-$(FOR_DOWNLOAD_VERSION).tar.gz)
	$(call EXTRACT_TAR,protobuf-$(FOR_DOWNLOAD_VERSION).tar.gz,protobuf-$(FOR_DOWNLOAD_VERSION),libprotobuf)

ifneq ($(wildcard $(BUILD_WORK)/libprotobuf/.build_complete),)
libprotobuf:
	@echo "Using previously built libprotobuf."
else
libprotobuf: libprotobuf-setup abseil
	# Build host protoc
	env -u CC -u CXX -u CFLAGS -u CXXFLAGS -u LDFLAGS -u PKG_CONFIG_PATH cmake -S $(BUILD_WORK)/libprotobuf -B $(BUILD_WORK)/libprotobuf/build-host \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_CXX_STANDARD=17 \
		-Dprotobuf_BUILD_TESTS=OFF \
		-Dprotobuf_BUILD_SHARED_LIBS=OFF \
		-Dprotobuf_ABSL_PROVIDER=module
	env -u CC -u CXX -u CFLAGS -u CXXFLAGS -u LDFLAGS -u PKG_CONFIG_PATH $(MAKE) -C $(BUILD_WORK)/libprotobuf/build-host protoc
	# Build target libprotobuf
	cmake -S $(BUILD_WORK)/libprotobuf -B $(BUILD_WORK)/libprotobuf/build \
		$(DEFAULT_CMAKE_FLAGS) \
		-DCMAKE_CXX_STANDARD=17 \
		-Dprotobuf_BUILD_TESTS=OFF \
		-Dprotobuf_BUILD_SHARED_LIBS=OFF \
		-Dprotobuf_LOCAL_DEPENDENCIES_ONLY=ON
	+$(MAKE) -C $(BUILD_WORK)/libprotobuf/build
	+$(MAKE) -C $(BUILD_WORK)/libprotobuf/build install \
		DESTDIR="$(BUILD_STAGE)/libprotobuf"
	$(call AFTER_BUILD,copy)
endif

libprotobuf-package: libprotobuf-stage
	# libprotobuf.mk Package Structure
	rm -rf $(BUILD_DIST)/libutf8-{range,validity}31.1 $(BUILD_DIST)/libprotobuf{{,-lite}31.1,-dev} $(BUILD_DIST)/libprotoc{31.1,-dev} $(BUILD_DIST)/protobuf-compiler
	mkdir -p $(BUILD_DIST)/libutf8-range31.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libutf8-validity31.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libprotobuf31.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libprotobuf-lite31.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libprotobuf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/google/protobuf,lib} \
		$(BUILD_DIST)/libprotoc31.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib \
		$(BUILD_DIST)/libprotoc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{include/google/protobuf,lib} \
		$(BUILD_DIST)/protobuf-compiler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libprotobuf.mk Prep libutf8-range31.1
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libutf8_range.31.1.0.dylib $(BUILD_DIST)/libutf8-range31.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libutf8-validity31.1
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libutf8_validity.31.1.0.dylib $(BUILD_DIST)/libutf8-validity31.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libprotobuf31.1
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotobuf.31.1.0.dylib $(BUILD_DIST)/libprotobuf31.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libprotobuf-lite31.1
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotobuf-lite.31.1.0.dylib $(BUILD_DIST)/libprotobuf-lite31.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libprotobuf-dev
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{cmake,pkgconfig,libprotobuf.dylib} $(BUILD_DIST)/libprotobuf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf/!(compiler) $(BUILD_DIST)/libprotobuf-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf

	# libprotobuf.mk Prep libprotoc31.1
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotoc.31.1.0.dylib $(BUILD_DIST)/libprotoc31.1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# libprotobuf.mk Prep libprotoc-dev
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/libprotoc.dylib $(BUILD_DIST)/libprotoc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf/compiler $(BUILD_DIST)/libprotoc-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include/google/protobuf

	# libprotobuf.mk Prep protobuf-compiler
	cp -a $(BUILD_STAGE)/libprotobuf/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/bin $(BUILD_DIST)/protobuf-compiler/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# libprotobuf.mk Sign
	$(call SIGN,libutf8-range31.1,general.xml)
	$(call SIGN,libutf8-validity31.1,general.xml)
	$(call SIGN,libprotobuf31.1,general.xml)
	$(call SIGN,libprotobuf-lite31.1,general.xml)
	$(call SIGN,libprotoc31.1,general.xml)
	$(call SIGN,protobuf-compiler,general.xml)

	# libprotobuf.mk Make .debs
	$(call PACK,libutf8-range31.1,DEB_LIBPROTOBUF_V)
	$(call PACK,libutf8-validity31.1,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotobuf31.1,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotobuf-lite31.1,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotobuf-dev,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotoc31.1,DEB_LIBPROTOBUF_V)
	$(call PACK,libprotoc-dev,DEB_LIBPROTOBUF_V)
	$(call PACK,protobuf-compiler,DEB_LIBPROTOBUF_V)

	# libprotobuf.mk Build cleanup
	rm -rf $(BUILD_DIST)/libutf8-{range,validity}31.1 $(BUILD_DIST)/libprotobuf{{,-lite}31.1,-dev} $(BUILD_DIST)/libprotoc{31.1,-dev} $(BUILD_DIST)/protobuf-compiler

.PHONY: libprotobuf libprotobuf-package
