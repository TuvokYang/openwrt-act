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

# Fix collectd version-gen.sh: git describe leaks parent openwrt repo version
# causing 'r54' undeclared error in lcc_features.h (LCC_VERSION_PATCH=0-r54)
# Remove git describe logic and hardcode version 5.12.0
if [ -d feeds/packages/utils/collectd/patches ]; then
    cat > feeds/packages/utils/collectd/patches/950-fix-version-gen.patch << 'EOF'
--- a/version-gen.sh
+++ b/version-gen.sh
@@ -1,13 +1,2 @@
 #!/bin/sh
-
-DEFAULT_VERSION="5.12.0.git"
-
-if [ -d .git ]; then
-	VERSION="`git describe --dirty=+ --abbrev=7 2> /dev/null | sed -e '/^collectd-/!d' -e 's///' -e 'y/-/./'`"
-fi
-
-if test -z "$VERSION"; then
-	VERSION="$DEFAULT_VERSION"
-fi
-
-printf "%s" "$VERSION"
+printf "5.12.0"
EOF
fi
