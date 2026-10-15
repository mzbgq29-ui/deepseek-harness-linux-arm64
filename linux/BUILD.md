# Linux ARM64 构建与打包记录

这是本机适配构建流程记录，目前尚未提供一键 Linux 打包脚本或 CI；不要将上游 `package:mac` / `package:win` 视为 Linux 入口。

1. 使用仓库锁文件安装依赖，完成 `pnpm run build`。构建工具要求 Node ^22.19 或 >=24。
2. 使用 Electron 44.7.0 Linux ARM64 分发包，保留 Electron 与 Chromium 许可。可执行文件名为 `deepseek-harness`，使 Electron 正确识别已打包应用。
3. 使用 `pnpm --filter @deepseek-ai/dsh-desktop-host deploy --legacy --prod` 和 `pnpm --filter @deepseek-ai/dsh-desktop deploy --legacy --prod` 部署生产依赖；复制编译后的桌面 `lib`、`renderer` 和 Host/CLI 依赖闭包。
4. 按上游 `scripts/primary-runtime/lock.json` 准备 Linux ARM64 主运行时，保留校验和、依赖及许可。Linux Host 选择 `resources/runtime/primary-runtime/dependencies/node/bin/node`，与本版 Node 24.21.0 配套。
5. 构建 `native/system` 的 ARM64 glibc/musl 锁模块和 Landlock 启动器。修复 pnpm 部署中指回工作区的链接，并补齐实际需要的 workspace peer 依赖。所有符号链接必须在发行目录内解析。
6. 将生产依赖中 `.bin` 启动脚本的构建目录绝对路径替换为相对 `${basedir}` 路径。生成 `desktop-runtime.json` 文件清单与 SHA-256；重新运行原生 PTY、SQLite、文件锁、图片解码、连接及沙箱功能检查。
7. 使用本目录 `launch.sh`、`niri-deepseek.kdl` 和安装器。以 `deepseek-harness-linux-arm64` 为归档顶层目录，用 tar + zstd 打包；更新 `SHA256SUMS.txt` 与安装脚本中的 `expected_sha256`。
8. 在干净的用户数据目录测试欢迎页、主界面、离线恢复及中文编辑，再测试首次安装、重复安装、损坏归档拒绝和无效 niri 规则回滚。

发行资产中的完整目录包含上游源码许可、Electron 许可、Chromium 许可及保留的依赖许可。GitHub Release 中的压缩包为完成上述本机验证的产物。
