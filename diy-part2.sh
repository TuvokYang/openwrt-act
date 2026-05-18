#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Modify default IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

# Modify default theme
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# Modify hostname
# sed -i 's/OpenWrt/Cudy TR3000/g' package/base-files/files/bin/config_generate

#set llvm.download-ci-llvm=false for rust
sed -i 's#download-ci-llvm=.* #download-ci-llvm=false #g' feeds/packages/lang/rust/Makefile

# Disable collectd: version-gen.sh git describe leaks parent openwrt repo version
# causing 'r54' undeclared error in lcc_features.h (LCC_VERSION_PATCH=0-r54)
# Local builds work because no parent git repo, but CI has /workdir/openwrt/.git
sed -i 's/^CONFIG_PACKAGE_collectd=y$/# CONFIG_PACKAGE_collectd is not set/' .config
sed -i 's/^\(CONFIG_PACKAGE_collectd-mod-.*\)=y$/# \1 is not set/' .config
