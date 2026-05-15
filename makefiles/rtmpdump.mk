ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS       += rtmpdump
RTMPDUMP_VERSION  := 2.6
RTMPDUMP_SHORT_V1 := 20151223
RTMPDUMP_SHORT_V2 := gitfa8646d.1
DEB_RTMPDUMP_V    ?= $(RTMPDUMP_VERSION)+$(RTMPDUMP_SHORT_V1).$(RTMPDUMP_SHORT_V2)-1

rtmpdump-setup: setup
	$(call GIT_CLONE,https://git.ffmpeg.org/rtmpdump.git,v$(RTMPDUMP_VERSION),rtmpdump)

ifneq ($(wildcard $(BUILD_WORK)/rtmpdump/.build_complete),)
rtmpdump:
	@echo "Using previously built rtmpdump."
else
rtmpdump: rtmpdump-setup nettle libgmp10 openssl
	mkdir -p $(BUILD_STAGE)/rtmpdump/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	+$(MAKE) -C $(BUILD_WORK)/rtmpdump/librtmp install \
		CC="$(CC)" \
		LD="$(LD)" \
		AR="$(AR)" \
		RANLIB="$(RANLIB)" \
		CRYPTO=OPENSSL \
		XCFLAGS="$(CFLAGS)" \
		XLDFLAGS="$(LDFLAGS)" \
		SYS=darwin \
		prefix="/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)" \
		DESTDIR="$(BUILD_STAGE)/rtmpdump" \
		mandir="/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/share/man" \
		SHARED=
	$(call AFTER_BUILD,copy)
endif

rtmpdump-package: rtmpdump-stage
	# rtmpdump.mk Package Structure
	rm -rf $(BUILD_DIST)/rtmpdump \
		$(BUILD_DIST)/librtmp{1,-dev}
	mkdir -p $(BUILD_DIST)/rtmpdump/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX) \
		$(BUILD_DIST)/librtmp{1,-dev}/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# rtmpdump.mk Prep rtmpdump
	cp -a $(BUILD_STAGE)/rtmpdump/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/{share,bin,sbin} $(BUILD_DIST)/rtmpdump/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# rtmpdump.mk Prep librtmp1
	cp -a $(BUILD_STAGE)/rtmpdump/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/librtmp.1.dylib $(BUILD_DIST)/librtmp1/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib

	# rtmpdump.mk Prep librtmp-dev
	cp -a $(BUILD_STAGE)/rtmpdump/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib/{librtmp.{dylib,a},pkgconfig} $(BUILD_DIST)/librtmp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/lib
	cp -a $(BUILD_STAGE)/rtmpdump/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)/include $(BUILD_DIST)/librtmp-dev/$(MEMO_PREFIX)$(MEMO_SUB_PREFIX)

	# rtmpdump.mk Sign
	$(call SIGN,rtmpdump,general.xml)
	$(call SIGN,librtmp1,general.xml)

	# rtmpdump.mk Make .debs
	$(call PACK,rtmpdump,DEB_RTMPDUMP_V)
	$(call PACK,librtmp1,DEB_RTMPDUMP_V)
	$(call PACK,librtmp-dev,DEB_RTMPDUMP_V)

	# rtmpdump.mk Build cleanup
	rm -rf $(BUILD_DIST)/rtmpdump \
		$(BUILD_DIST)/librtmp{1,-dev}

.PHONY: rtmpdump rtmpdump-package
