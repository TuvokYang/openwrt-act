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

# Uncomment a feed source
#sed -i 's/^#\(.*helloworld\)/\1/' feeds.conf.default

# Add a feed source
sed -i 's|^src-git luci .*|src-git luci https://github.com/TuvokYang/luci.git|' feeds.conf.default

sed -i '/^src-git mentohust .*/d'  feeds.conf.default
echo >> feeds.conf.default
echo 'src-git mentohust https://github.com/TuvokYang/mentohust.git' >> feeds.conf.default
echo 'src-git luci-app-mentohust https://github.com/TuvokYang/luci-app-mentohust.git' >> feeds.conf.default
