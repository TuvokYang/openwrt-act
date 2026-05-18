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

# Fix collectd version-gen.sh: prevent git describe from picking up parent openwrt repo
# Without this, LCC_VERSION_PATCH gets set to "0-r54" causing compile error
# Patch version-gen.sh before configure to hardcode the version
if [ -f feeds/packages/utils/collectd/Makefile ]; then
    cat >> feeds/packages/utils/collectd/Makefile << 'COLLECTD_FIX'

define Build/Configure
	sed -i 's|git describe --abbrev=4 HEAD 2>/dev/null|echo 5.12.0|g' $(PKG_BUILD_DIR)/version-gen.sh
	$(call Build/Configure/Default)
endef
COLLECTD_FIX
fi
