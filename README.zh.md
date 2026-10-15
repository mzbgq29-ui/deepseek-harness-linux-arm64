# DeepSeek Harness — Linux ARM64 中文桌面适配版

[English](README.md) | 中文

基于 [DeepSeek 官方源码](https://github.com/deepseek-ai/deepseek-harness) 的非官方 Linux 桌面构建，与 DeepSeek 官方无隶属关系。保留上游 MIT 许可及第三方许可。

本版基于上游版本 `0.2.1-alpha.3`，发布版本 `0.2.1-alpha.3-linux-arm64-r5`。

## 功能

- 默认简体中文，补齐 Linux 原生编辑、右键和退出菜单文字。
- 原生 Wayland，启用 text-input-v3 输入法协议。
- niri 主窗口默认约 2/3 屏宽平铺；欢迎页 600×600 浮动，最小 480×480。
- 修复 Electron Node 空 WebSocket 心跳导致反复重连。
- Linux 后端使用随包标准 Node 24.21.0，修复 sharp 读取截图时段错误退出。
- 用户目录安装，无需 sudo；安装包哈希校验、按内容切换版本、写入 niri 配置前先校验。

<a id="run"></a>

## 安装

适用于 **Linux ARM64 / aarch64、glibc、Wayland**。已在 Arch Linux ARM + niri 环境验证；其他发行版兼容性尚未验证。不适用于 x86_64、musl 或 X11。

从本仓库 Releases 下载以下文件，放在同一目录：

- `deepseek-harness-0.2.1-alpha.3-linux-arm64.tar.zst`
- `install-desktop.sh`
- `SHA256SUMS.txt`

需要 Python 3、支持 zstd 的 tar 及 zstd。若使用 niri，需要 `niri` 或 `niri-anland` 命令可用。

```sh
sha256sum -c SHA256SUMS.txt
sh install-desktop.sh
```

安装后从应用菜单启动 DeepSeek Harness，或运行 `~/.local/bin/deepseek-harness`。使用自己的 DeepSeek 账号或 API Key；本发行包不包含账号、凭据或会话数据。

程序安装在 `~/.local/share/deepseek-harness-linux-arm64/`，用户数据默认在 `~/.dsh/`，桌面设置在 `~/.config/DeepSeek Harness/`。使用自定义 XDG 目录时，安装路径随之调整。

## 更新

下载新 Release 的安装包及配套安装脚本，重复安装，再退出并重新启动应用。没有配置官方自动更新渠道。安装器保留原版本目录，更新不删除账号和会话数据。

<a id="run-from-source"></a>

## 源码与构建

本仓库保留完整上游源码及本地适配修改。依赖与源码构建：

```sh
pnpm install --frozen-lockfile
DSH_GATE_CONCURRENCY=2 pnpm run build
```

Linux 打包说明见 [linux/BUILD.md](linux/BUILD.md)。上游打包脚本仍只正式支持 macOS/Windows；上述构建命令不会自动产出本版 Linux 安装包。

## 验证与限制

详见 [验证记录](linux/VALIDATION.zh-CN.txt)。本次验证包含完整构建、针对性回归、真实 ARM64 运行时、截图解码、连接恢复、依赖完整性、安装器和 niri 配置检查。Fcitx 候选窗口未人工验证；付费模型请求和外部插件兼容性未做完整测试。

当前测试内核不支持 Landlock，已验证可用的 Bubblewrap 保持启用。其他系统需自行满足所选沙箱后端的要求。

上游文档见 [UPSTREAM-README.md](UPSTREAM-README.md)。
