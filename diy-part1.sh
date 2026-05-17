#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# Add a feed source
# sed -i 's|^src-git luci .*|src-git luci https://github.com/TuvokYang/luci.git;openwrt-24.10|' feeds.conf.default

sed -i '/^src-link custom*/d' feeds.conf.default

# Convert feed references from ^commit_hash to ;openwrt-XX.YY format if OPENWRT_VERSION is set
if [ -n "$OPENWRT_VERSION" ]; then
  sed -i "/^src-git/s|\^[0-9a-f]\{40\}|;openwrt-${OPENWRT_VERSION}|g" feeds.conf.default
fi

mkdir -p custom
pushd custom
    git clone https://github.com/TuvokYang/mentohust.git
    git clone https://github.com/TuvokYang/luci-app-mentohust.git
    git clone https://github.com/yichya/luci-app-xray.git
popd
echo "src-link custom $(pwd)/custom" >> feeds.conf.default
cat feeds.conf.default
