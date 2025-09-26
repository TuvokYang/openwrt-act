[![OpenWrt Builder](https://github.com/TuvokYang/openwrt-act/actions/workflows/openwrt-builder.yml/badge.svg?)](https://github.com/TuvokYang/openwrt-act/actions/workflows/openwrt-builder.yml)

Building OpenWrt for Cudy TR3000 256MB v1 with GitHub Actions from [Actions-OpenWrt](https://github.com/P3TERX/Actions-OpenWrt)

## Usage

- Generate `.config` files using [OpenWrt](https://github.com/openwrt/openwrt) source code. ( You can change it through environment variables in the workflow file. )
- Push `.config` file to the GitHub repository.
- When the build is complete, click the `Artifacts` button in the upper right corner of the Actions page to download the binaries.
