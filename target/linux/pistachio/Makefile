#
# Copyright (C) 2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

ARCH:=mipsel
BOARD:=pistachio
BOARDNAME:=IMG MIPS Pistachio
FEATURES:=targz nand squashfs ubifs audio ramdisk fpu usb usbgadget

KERNEL_PATCHVER:=4.4

CPU_TYPE:=mips32r2

include $(INCLUDE_DIR)/target.mk

DEFAULT_PACKAGES+=kmod-leds-gpio kmod-ledtrig-heartbeat kmod-i2c-core i2c-tools \
                  kmod-sound-pistachio-soc alsa-lib alsa-utils alsa-utils-tests \
                  kmod-uccp420wlan fping iw hostapd wpa-cli wpa-supplicant \
                  kmod-tpm-i2c-infineon kmod-random-tpm tpm-tools \
                  kmod-spi-dev \
                  uhttpd uboot-envtools tcpdump board-test \
                  luci kmod-mac802154 wpan-tools \
                  curl libopenssl ca-certificates \
                  bluez-daemon

define Target/Description
	Build firmware images for Pistachio board.
endef

$(eval $(call BuildTarget))
