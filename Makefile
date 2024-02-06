export THEOS_PACKAGE_SCHEME=rootless
export TARGET = iphone:clang:13.7:13.0

PACKAGE_VERSION=$(THEOS_PACKAGE_BASE_VERSION)

export GO_EASY_ON_ME = 1

ARCHS = arm64 arm64e
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ColorHomeBar

$(TWEAK_NAME)_FILES = Tweak.x $(wildcard ColorCube/Framework/ColorCube/ColorCube/Source/*.m)
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = MediaPlayer
$(TWEAK_NAME)_CFLAGS = -fobjc-arc -IColorCube/Framework/ColorCube/ColorCube/Source

include $(THEOS_MAKE_PATH)/tweak.mk

before-package::
	@cp ColorCube/LICENSE $(THEOS_STAGING_DIR)/DEBIAN/ColorCube_LICENSE