[![Creator logo](https://raw.githubusercontent.com/CreatorKit/creator-docs/master/images/creatorlogo.png)](https://community.imgtec.com/platforms/creator-ci40/)

[![Stories in Backlog](https://badge.waffle.io/CreatorDev/openwrt.png?label=s:%20Backlog&title=Backlog)](http://waffle.io/CreatorDev/openwrt)
[![Build Status](http://jenkins.creatordev.io/buildStatus/icon?job=CreatorDev/openwrt/ci40)](http://jenkins.creatordev.io/job/CreatorDev/openwrt/ci40)

# Using OpenWrt on [Creator Ci40](https://community.imgtec.com/platforms/creator-ci40/) platform
OpenWrt is a highly extensible GNU/Linux distribution for embedded devices. Instead of trying to create a single, static firmware, OpenWrt provides
a fully writable filesystem with optional package management. This frees you from the restrictions of the application selection and configuration
provided by the vendor and allows you to use packages to customize an embedded device to suit any application. For developers, OpenWrt provides a
framework to build an application without having to create a complete firmware image and distribution around it. For users, this means the freedom
of full customisation, allowing the use of an embedded device in ways the vendor never envisioned.

This readme contains the basics of configuring and building a firmware image for Ci40 but you will find much more **documentation on our
[Creator Documentation website](https://docs.creatordev.io/ci40/guides/openwrt-platform/) and lots of generic OpenWrt documention on
[OpenWrt project wiki](http://wiki.openwrt.org/doc/start)**.

### Useful glossary
Creator - a MIPS based developer program from Imagination Technologies  
Creator Ci40 (marduk) - the latest development board in the Creator program  
cXT200 (pistachio) - the name of the Imagination Technologies SoC that Ci40 uses at it's core  

## Quick start
### Get it (and it's dependencies)
1. Install dependencies

    ```
    $ sudo apt install git libncurses5-dev libncursesw5-dev zlib1g-dev libssl-dev gawk subversion 
    device-tree-compiler bsdmainutils bc rsync
    ```
2. Clone the code

    ```
    $ git clone https://github.com/CreatorDev/openwrt.git
    $ cd openwrt
    ```
    The release distribution is structured as documented in the upstream project, note the ci40 board support is under `target/linux/pistachio`.
3. Install feed packages

    ```
    $ ./scripts/feeds update -a
    $ ./scripts/feeds install -a
    ```
    *Ignore any "WARNING: No feed for package..." from the install feeds step.*

### Configure it
*Note that mass production Ci40 boards use the Cascoda __ca8210__ chip, so assume the use of this profile unless you have been personally informed otherwise.*

1. Copy base config

    ```
    $ cat target/linux/pistachio/marduk-default.config > .config
    ```
2. Generate the default config

    ```
    $ make defconfig
    ```
3. Optionally make changes to the configuration
    1. Run configuration tool

        ```
        $ make menuconfig
        ```
    2. Make your changes
    3. Save and exit

### Build it
1. Build OpenWrt with make:

    ```
    $ make
    ```

If there is any issue during the build run the build in verbose mode to see what's going on.:

```
$ make V=s
```

Once the build is completed you will find your firmware images in bin/pistachio. Example output for v0.10.5 tag:
* openwrt-v0.10.5-pistachio-marduk-kernel.itb
* openwrt-v0.10.5-pistachio-marduk-initramfs-kernel.itb
* openwrt-v0.10.5-pistachio-marduk-rootfs.tar.gz
* openwrt-v0.10.5-pistachio-marduk-squashfs-factory.ubi
* openwrt-v0.10.5-pistachio-marduk-squashfs-sysupgrade.tar

For more details please refer to our [detailed build guide](https://docs.creatordev.io/ci40/guides/openwrt-platform/#building-openwrt)
and the [OpenWrt build system wiki]("http://wiki.openwrt.org/doc/howto/build").

### Flash it
See our [upgrade guide](https://docs.creatordev.io/ci40/guides/openwrt-platform/#upgrading-your-ci40-software)

### Use it
See our [quick start guide](https://docs.creatordev.io/ci40/guides/quick-start-guide/)

