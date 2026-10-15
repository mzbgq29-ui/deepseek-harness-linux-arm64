#!/bin/sh
set -eu
app_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -z "${WAYLAND_DISPLAY:-}" ]; then
  printf '%s\n' '请在 Wayland 桌面会话中启动 DeepSeek Harness（未检测到 WAYLAND_DISPLAY）。' >&2
  exit 1
fi
unset ELECTRON_RUN_AS_NODE LC_ALL
export LANG=zh_CN.UTF-8
export LC_MESSAGES=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
exec "$app_dir/deepseek-harness" --class=deepseek-harness --ozone-platform=wayland --enable-wayland-ime --wayland-text-input-version=3 --lang=zh-CN "$@"
