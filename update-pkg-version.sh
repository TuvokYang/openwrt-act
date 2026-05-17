#!/bin/bash
# update-pkg-version.sh - 更新 OpenWrt package 版本并自动获取 PKG_HASH
#
# 用法: ./update-pkg-version.sh <Makefile路径> <新版本号>
#
# 示例: ./update-pkg-version.sh feeds/packages/yaml/Makefile 0.2.6

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    cat <<EOF
用法: $0 <Makefile路径> <新版本号>

示例:
  $0 feeds/packages/yaml/Makefile 0.2.6
  $0 feeds/packages/xray-core/Makefile 25.12.9

说明:
  该脚本会:
  1. 从 Makefile 中提取 PKG_NAME, PKG_VERSION, PKG_SOURCE, PKG_SOURCE_URL
  2. 将版本号替换为新版本，展开变量构造真实下载 URL
  3. 下载源码包到 /tmp
  4. 计算 SHA256 哈希值
  5. 更新 Makefile 中的 PKG_VERSION 和 PKG_HASH
EOF
    exit 1
}

# 参数检查
if [ $# -ne 2 ]; then
    usage
fi

MAKEFILE="$1"
NEW_VERSION="$2"

# 检查 Makefile 是否存在
if [ ! -f "$MAKEFILE" ]; then
    echo -e "${RED}错误: Makefile 不存在: $MAKEFILE${NC}"
    exit 1
fi

echo -e "${YELLOW}==> 解析 Makefile: $MAKEFILE${NC}"

# 提取 Makefile 变量
# 使用 grep + sed 提取 := 赋值
extract_var() {
    local varname="$1"
    local value
    value=$(grep -m1 "^${varname}:=" "$MAKEFILE" | sed -E 's/^[^:]+:=[[:space:]]*//; s/[[:space:]]*$//')
    # 去掉行末可能存在的续行符 \（简单处理单行情况）
    value="${value%\\}"
    echo "$value" | sed 's/[[:space:]]*$//'
}

PKG_NAME=$(extract_var "PKG_NAME")
OLD_VERSION=$(extract_var "PKG_VERSION")
PKG_SOURCE=$(extract_var "PKG_SOURCE")
PKG_SOURCE_URL=$(extract_var "PKG_SOURCE_URL")
PKG_SOURCE_PROTO=$(extract_var "PKG_SOURCE_PROTO" 2>/dev/null || true)

if [ -z "$PKG_NAME" ]; then
    echo -e "${RED}错误: 未找到 PKG_NAME${NC}"
    exit 1
fi
if [ -z "$OLD_VERSION" ]; then
    echo -e "${RED}错误: 未找到 PKG_VERSION${NC}"
    exit 1
fi
if [ -z "$PKG_SOURCE" ]; then
    echo -e "${RED}错误: 未找到 PKG_SOURCE${NC}"
    exit 1
fi
if [ -z "$PKG_SOURCE_URL" ]; then
    echo -e "${RED}错误: 未找到 PKG_SOURCE_URL${NC}"
    exit 1
fi

# 检查是否为 git 协议（不支持）
if [ "$PKG_SOURCE_PROTO" = "git" ]; then
    echo -e "${RED}错误: 不支持 git 协议的包（PKG_SOURCE_PROTO:=git）${NC}"
    echo "这类包使用 PKG_SOURCE_VERSION 而非 PKG_VERSION，不适合用此脚本。"
    exit 1
fi

echo "  PKG_NAME      = $PKG_NAME"
echo "  PKG_VERSION   = $OLD_VERSION -> ${GREEN}$NEW_VERSION${NC}"
echo "  PKG_SOURCE    = $PKG_SOURCE"
echo "  PKG_SOURCE_URL= $PKG_SOURCE_URL"

# 展开变量：将 $(PKG_NAME) 和 $(PKG_VERSION) 替换为实际值
expand_vars() {
    local str="$1"
    local ver="$2"
    local name="${3:-}"
    str="${str//\$(PKG_VERSION)/$ver}"
    str="${str//\$(PKG_NAME)/$name}"
    # 也处理 ${} 格式
    str="${str//\$\{PKG_VERSION\}/$ver}"
    str="${str//\$\{PKG_NAME\}/$name}"
    echo "$str"
}

SOURCE_FILE=$(expand_vars "$PKG_SOURCE" "$NEW_VERSION" "$PKG_NAME")
SOURCE_URL_EXPANDED=$(expand_vars "$PKG_SOURCE_URL" "$NEW_VERSION" "$PKG_NAME")

# 构造下载 URL
# 规则:
# 1. 如果 URL 以 .tar.gz / .tar.xz / .tar.bz2 / .tar.zst / .zip / .tgz 等结尾（可能带 ? 后缀），直接用 URL
# 2. 如果 URL 以 / 结尾，拼接 SOURCE_FILE
# 3. 否则尝试拼接，看哪个能成功下载

if echo "$SOURCE_URL_EXPANDED" | grep -qE 'https?://.*\.(tar\.(gz|xz|bz2|zst)|zip|tgz|tbz2)(\?.*)?$'; then
    # URL 本身就是完整的下载地址
    DOWNLOAD_URL="$SOURCE_URL_EXPANDED"
elif echo "$SOURCE_URL_EXPANDED" | grep -qE '/$'; then
    # URL 以 / 结尾，直接拼接
    DOWNLOAD_URL="${SOURCE_URL_EXPANDED}${SOURCE_FILE}"
elif echo "$SOURCE_URL_EXPANDED" | grep -q '\?$'; then
    # URL 以 ? 结尾（如 codeload），直接使用
    DOWNLOAD_URL="$SOURCE_URL_EXPANDED"
else
    # 默认拼接
    DOWNLOAD_URL="${SOURCE_URL_EXPANDED}/${SOURCE_FILE}"
fi

# 处理 @宏
# @GNU/xxx -> https://ftpmirror.gnu.org/gnu/xxx
# @KERNEL/xxx -> https://www.kernel.org/pub/xxx
# @SF/xxx -> https://downloads.sourceforge.net/xxx
# @GITHUB/xxx -> https://raw.githubusercontent.com/xxx
# @OPENWRT -> https://downloads.openwrt.org/sources
# @GNOME/xxx -> https://download.gnome.org/sources/xxx
# @DEBIAN/xxx -> https://deb.debian.org/xxx

expand_macro() {
    local url="$1"
    case "$url" in
        @GNU/*)
            echo "https://ftpmirror.gnu.org/gnu/${url#@GNU/}"
            ;;
        @KERNEL/*)
            echo "https://www.kernel.org/pub/${url#@KERNEL/}"
            ;;
        @SF/*)
            echo "https://downloads.sourceforge.net/${url#@SF/}"
            ;;
        @GITHUB/*)
            echo "https://raw.githubusercontent.com/${url#@GITHUB/}"
            ;;
        @GNOME/*)
            echo "https://download.gnome.org/sources/${url#@GNOME/}"
            ;;
        @DEBIAN/*)
            echo "https://deb.debian.org/${url#@DEBIAN/}"
            ;;
        @OPENWRT)
            echo "https://downloads.openwrt.org/sources"
            ;;
        *)
            echo "$url"
            ;;
    esac
}

DOWNLOAD_URL=$(expand_macro "$DOWNLOAD_URL")

echo -e "${YELLOW}==> 下载 URL: $DOWNLOAD_URL${NC}"
echo -e "${YELLOW}==> 本地文件: /tmp/$SOURCE_FILE${NC}"

# 下载文件
echo -e "${YELLOW}==> 开始下载...${NC}"

if ! wget -q --show-progress -O "/tmp/$SOURCE_FILE" "$DOWNLOAD_URL" 2>&1; then
    echo -e "${RED}错误: 下载失败${NC}"
    echo "URL: $DOWNLOAD_URL"
    # 清理可能的部分下载
    rm -f "/tmp/$SOURCE_FILE"
    exit 1
fi

if [ ! -f "/tmp/$SOURCE_FILE" ]; then
    echo -e "${RED}错误: 下载后文件不存在: /tmp/$SOURCE_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}下载成功${NC}"

# 计算 SHA256 哈希
echo -e "${YELLOW}==> 计算 SHA256...${NC}"
NEW_HASH=$(sha256sum "/tmp/$SOURCE_FILE" | awk '{print $1}')

if [ ${#NEW_HASH} -ne 64 ]; then
    echo -e "${RED}错误: SHA256 哈希长度不正确: ${#NEW_HASH} (期望 64)${NC}"
    rm -f "/tmp/$SOURCE_FILE"
    exit 1
fi

echo -e "${GREEN}PKG_HASH = $NEW_HASH${NC}"

# 更新 Makefile
echo -e "${YELLOW}==> 更新 Makefile...${NC}"

# 备份原文件
cp "$MAKEFILE" "${MAKEFILE}.bak"

# 替换 PKG_VERSION
if grep -q "^PKG_VERSION:=" "$MAKEFILE"; then
    sed -i "s/^PKG_VERSION:=.*$/PKG_VERSION:=${NEW_VERSION}/" "$MAKEFILE"
    echo "  PKG_VERSION: $OLD_VERSION -> $NEW_VERSION"
fi

# 替换 PKG_HASH
if grep -q "^PKG_HASH:=" "$MAKEFILE"; then
    sed -i "s/^PKG_HASH:=.*$/PKG_HASH:=${NEW_HASH}/" "$MAKEFILE"
    echo "  PKG_HASH: 已更新"
else
    # PKG_HASH 不存在，插入到 PKG_SOURCE_URL 后面
    echo -e "${YELLOW}  PKG_HASH 不存在，尝试插入...${NC}"
    # 在 PKG_SOURCE_URL 行后插入 PKG_HASH
    sed -i "/^PKG_SOURCE_URL:=/a PKG_HASH:=${NEW_HASH}" "$MAKEFILE"
fi

# 清理临时文件
rm -f "/tmp/$SOURCE_FILE"

# 输出结果
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Makefile 更新完成!${NC}"
echo -e "${GREEN}========================================${NC}"
echo "  Makefile: $MAKEFILE"
echo "  旧版本:  $OLD_VERSION"
echo "  新版本:  $NEW_VERSION"
echo "  PKG_HASH: $NEW_HASH"
echo ""
echo -e "${YELLOW}  备份文件: ${MAKEFILE}.bak${NC}"
echo ""
echo "  建议运行以下命令验证:"
echo "    make -C \$(dirname $MAKEFILE) download check FIXUP=1"