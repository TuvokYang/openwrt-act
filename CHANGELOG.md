# Changelog

## v25.12.4

- 从 OpenWRT 24.10 迁移到 25.12.4
- 更新 feeds 引用格式为 `;openwrt-25.12`
- 使用 `openwrt-25.12` 分支编译
- 更新 .config 中版本号相关配置
- 修复 Rust Makefile 中 `download-ci-llvm=false` 配置
- 更新 xray 相关包版本
- 更新 mentohust 包版本

## v24.10.2

- OpenWRT 24.10.2 稳定版本
- 支持 Cudy TR3000 256MB v1 设备
- 集成 mentohust 校园网认证
- 集成 xray 代理
- 自定义 feeds 源管理