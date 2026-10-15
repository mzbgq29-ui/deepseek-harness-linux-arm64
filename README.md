# DeepSeek Harness — Linux ARM64 Chinese desktop adaptation

English | [中文](README.zh.md)

An unofficial Linux desktop build based on [DeepSeek's official source](https://github.com/deepseek-ai/deepseek-harness), with no affiliation to DeepSeek. The upstream MIT license and third-party licenses are preserved.

Based on upstream version `0.2.1-alpha.3`, release `0.2.1-alpha.3-linux-arm64-r5`.

## Features

- Simplified Chinese by default, including Linux native edit, context, and quit menus.
- Native Wayland with the text-input-v3 input method protocol.
- niri main window tiles at approximately 2/3 screen width; the welcome window floats at 600×600 with a 480×480 minimum.
- Fixes repeated reconnections caused by empty WebSocket heartbeats under Electron Node.
- Linux backend uses bundled standard Node 24.21.0 to fix sharp crashes when reading screenshots.
- User-local installation without sudo; archive hash verification, content-based version switching, and niri validation before writing configuration.

<a id="run"></a>

## Installation

Requires **Linux ARM64 / aarch64, glibc, and Wayland**. Verified on Arch Linux ARM + niri; compatibility with other distributions is unverified. Does not support x86_64, musl, or X11.

Download these files from this repository's Releases into the same directory:

- `deepseek-harness-0.2.1-alpha.3-linux-arm64.tar.zst`
- `install-desktop.sh`
- `SHA256SUMS.txt`

Requires Python 3, tar with zstd support, and zstd. niri integration requires an available `niri` or `niri-anland` command.

```sh
sha256sum -c SHA256SUMS.txt
sh install-desktop.sh
```

Launch DeepSeek Harness from your application menu or run `~/.local/bin/deepseek-harness`. Supply your own DeepSeek account or API key; the distribution contains no accounts, credentials, or session data.

The application installs under `~/.local/share/deepseek-harness-linux-arm64/`, user data defaults to `~/.dsh/`, and desktop settings reside in `~/.config/DeepSeek Harness/`. Custom XDG directories change the installation paths accordingly.

## Updating

Download the new Release archive and matching installer, reinstall, then quit and restart the application. No official automatic update channel is configured. The installer retains previous version directories and preserves accounts and sessions.

<a id="run-from-source"></a>

## Source and build

This repository preserves the complete upstream source and local adaptations. Install dependencies and build from source:

```sh
pnpm install --frozen-lockfile
DSH_GATE_CONCURRENCY=2 pnpm run build
```

See [linux/BUILD.md](linux/BUILD.md) for Linux packaging. Upstream packaging scripts still officially support only macOS/Windows; the commands above do not produce this Linux archive automatically.

## Validation and limitations

See the [validation record](linux/VALIDATION.zh-CN.txt). Validation covers a complete build, focused regressions, real ARM64 runtime, screenshot decoding, connection recovery, dependency integrity, the installer, and niri configuration. Fcitx candidate windows have not been manually verified; paid model requests and external plugin compatibility have not been fully tested.

The tested kernel lacks Landlock support; the verified Bubblewrap backend remains enabled. Other systems must meet the requirements of their selected sandbox backend.

See [UPSTREAM-README.md](UPSTREAM-README.md) for upstream documentation.
