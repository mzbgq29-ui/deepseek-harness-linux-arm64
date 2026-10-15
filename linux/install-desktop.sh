#!/bin/sh
set -eu
[ "$(uname -s)" = Linux ] && [ "$(uname -m)" = aarch64 ] || { echo '需要 Linux ARM64 系统。' >&2; exit 1; }
archive_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
expected_sha256='cd65cb1f01db29c1e2a71d0171aed80f45d35929fe41a87e994968fddf8351f5'
exec python3 - "$archive_dir/deepseek-harness-0.2.1-alpha.3-linux-arm64.tar.zst" "$expected_sha256" <<'PY'
import hashlib, os, pathlib, re, shlex, shutil, subprocess, sys, tempfile, time

archive = pathlib.Path(sys.argv[1])
expected = sys.argv[2]
if not archive.is_file():
    sys.exit('找不到安装包：' + str(archive))
with archive.open('rb') as stream:
    digest = hashlib.file_digest(stream, 'sha256').hexdigest()
if digest != expected:
    sys.exit('安装包 SHA-256 校验失败；未修改现有安装。')

home = pathlib.Path.home()
data = pathlib.Path(os.environ.get('XDG_DATA_HOME', home / '.local/share'))
config = pathlib.Path(os.environ.get('XDG_CONFIG_HOME', home / '.config'))
root = data / 'deepseek-harness-linux-arm64'
version = root / ('0.2.1-alpha.3-linux-arm64-r5-' + digest[:12])
root.mkdir(parents=True, exist_ok=True)

# Publish complete files by rename, preserving the existing file's permissions.
def atomic_write(path, text, mode=0o644):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists(): mode = path.stat().st_mode & 0o777
    fd, temporary = tempfile.mkstemp(prefix='.' + path.name + '.', dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as stream:
            stream.write(text)
            stream.flush()
            os.fsync(stream.fileno())
        os.chmod(temporary, mode)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary): os.unlink(temporary)

marker = version / '.archive-sha256'
if version.exists():
    if not marker.is_file() or marker.read_text().strip() != digest:
        sys.exit('目标安装目录不完整；现有安装保持不变：' + str(version))
else:
    with tempfile.TemporaryDirectory(prefix='.install.', dir=root) as temporary:
        subprocess.run(['tar', '--zstd', '-xf', str(archive), '-C', temporary], check=True)
        staged = pathlib.Path(temporary) / 'deepseek-harness-linux-arm64'
        for name in ['deepseek-harness', 'launch.sh']:
            if not os.access(staged / name, os.X_OK):
                sys.exit('安装包缺少可执行文件：' + name)
        (staged / '.archive-sha256').write_text(digest + '\n')
        staged.rename(version)

# Validate a candidate with the new rules before touching the live niri files.
niri_config = config / 'niri/config.kdl'
niri_rule = config / 'niri/deepseek-harness.kdl'
if niri_config.is_file():
    original = niri_config.read_text()
    rules = (version / 'niri-deepseek.kdl').read_text()
    include = 'include "deepseek-harness.kdl"'
    pattern = r'(?m)^[ \t]*include[ \t]+"(?:\./)?deepseek-harness\.kdl"[ \t]*;?[ \t]*(?://[^\n]*)?$'
    active = re.search(pattern, original) is not None
    updated = original if active else original.rstrip() + '\n\n// DeepSeek Harness desktop rules\n' + include + '\n'
    validator = shutil.which('niri') or shutil.which('niri-anland')
    if validator is None:
        sys.exit('找不到 niri 配置校验程序；未修改 niri 配置或当前应用入口。')
    with tempfile.NamedTemporaryFile('w', suffix='.kdl', prefix='.deepseek-rules-', dir=niri_rule.parent) as staged_rule:
        staged_rule.write(rules); staged_rule.flush()
        candidate = re.sub(pattern, lambda _: 'include "' + staged_rule.name + '"', updated)
        with tempfile.NamedTemporaryFile('w', suffix='.kdl', prefix='.deepseek-config-', dir=niri_config.parent) as staged_config:
            staged_config.write(candidate); staged_config.flush()
            checked = subprocess.run([validator, 'validate', '-c', staged_config.name], capture_output=True, text=True)
            if checked.returncode:
                sys.exit('niri 配置校验失败；原配置与当前应用入口保持不变。\n' + checked.stderr)
    stamp = time.strftime('%Y%m%d-%H%M%S') + '-' + str(time.time_ns())[-6:]
    if updated != original:
        shutil.copy2(niri_config, str(niri_config) + '.bak-deepseek-' + stamp)
    if niri_rule.exists() and niri_rule.read_text() != rules:
        shutil.copy2(niri_rule, str(niri_rule) + '.bak-' + stamp)
    if not niri_rule.exists() or niri_rule.read_text() != rules:
        atomic_write(niri_rule, rules)
    if updated != original:
        atomic_write(niri_config, updated)

# Content-addressed installs allow fixes to the same upstream version.
current = root / 'current'
link = root / ('.current.' + str(os.getpid()))
try:
    link.symlink_to(version)
    os.replace(link, current)
finally:
    if link.is_symlink(): link.unlink()

launcher = home / '.local/bin/deepseek-harness'
atomic_write(launcher, '#!/bin/sh\nunset ELECTRON_RUN_AS_NODE\nexec ' + shlex.quote(str(current / 'launch.sh')) + ' "$@"\n', 0o755)
# Desktop Entry Exec quoting is separate from shell quoting.
exec_path = str(launcher).replace('\\', '\\\\').replace('"', '\\"').replace('$', '\\$').replace('`', '\\`').replace('%', '%%')
desktop = data / 'applications/deepseek-harness.desktop'
atomic_write(desktop, '\n'.join([
    '[Desktop Entry]', 'Type=Application', 'Name=DeepSeek Harness', 'Name[zh_CN]=DeepSeek Harness',
    'Comment=DeepSeek agent desktop — local Linux ARM64 build',
    'Exec="' + exec_path + '" %U', 'Icon=' + str(current / 'resources/icon.png'),
    'Terminal=false', 'Categories=Development;', 'StartupNotify=true',
    'StartupWMClass=deepseek-harness', 'MimeType=x-scheme-handler/dsh;', '',
]))
old_desktop = desktop.with_name('deepseek-harness-local.desktop')
if old_desktop.exists(): old_desktop.unlink()
if shutil.which('update-desktop-database'):
    subprocess.run(['update-desktop-database', str(desktop.parent)], check=True)
print('已安装：' + str(version))
print('从应用菜单启动 DeepSeek Harness，或运行 deepseek-harness。')
PY
