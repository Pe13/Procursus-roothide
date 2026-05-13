ifneq ($(PROCURSUS),1)
$(error Use the main Makefile)
endif

SUBPROJECTS   += portmidi
PORTMIDI_VERSION := 2.0.4
PORTMIDI_COMMIT := 928520f7b79f371854387cb480b4e3b5bf5dac95
DEB_PORTMIDI_V   ?= $(PORTMIDI_VERSION)

portmidi-setup: setup
	$(call GITHUB_ARCHIVE,PortMidi,portmidi,$(PORTMIDI_COMMIT),$(PORTMIDI_COMMIT))
	$(call EXTRACT_TAR,portmidi-$(PORTMIDI_COMMIT).tar.gz,portmidi-$(PORTMIDI_COMMIT),portmidi)
	$(call DO_PATCH,portmidi,portmidi,-p1)
	mkdir -p $(BUILD_WORK)/portmidi/build

ifneq ($(wildcard $(BUILD_WORK)/portmidi/.build_complete),)
portmidi:
	@echo "Using previously built portmidi."
else
portmidi: portmidi-setup
	cd $(BUILD_WORK)/portmidi/build && cmake . \
		$(DEFAULT_CMAKE_FLAGS) \
		..
	+$(MAKE) -C $(BUILD_WORK)/portmidi/build
	+$(MAKE) -C $(BUILD_WORK)/portmidi/build install \
		DESTDIR="$(BUILD_STAGE)/portmidi"
	$(call AFTER_BUILD,copy)
endif

portmidi-package: portmidi-stage
	# portmidi.mk Package Structure
	rm -rf $(BUILD_DIST)/portmidi

	# portmidi.mk Prep portmidi
	cp -a $(BUILD_STAGE)/portmidi $(BUILD_DIST)

	# portmidi.mk Sign
	$(call SIGN,portmidi,general.xml)

	# portmidi.mk Make .debs
	$(call PACK,portmidi,DEB_PORTMIDI_V)

	# portmidi.mk Build cleanup
	rm -rf $(BUILD_DIST)/portmidi

.PHONY: portmidi portmidi-package
