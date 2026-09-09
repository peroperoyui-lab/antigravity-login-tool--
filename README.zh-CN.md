# Antigravity Proxy Launcher

> **请先看这里 / Read this first**
>
> **中文：本工具主要面向想使用 Antigravity，但不希望开启代理客户端的 TUN 模式、让虚拟网卡接管本机全部流量的用户。**它让 Antigravity 及其子进程单独继承本地 HTTP/SOCKS 代理，而不是让整台机器进入 TUN。
>
> **EN: This tool is primarily for users who want to use Antigravity without enabling their proxy client's TUN mode and letting a virtual network interface intercept all traffic on the machine.** It gives Antigravity and its child processes their own local HTTP/SOCKS proxy environment instead of putting the whole machine behind TUN.
>
> **中文：这个工具最初就是为了解决两类实际症状而诞生的：① Antigravity 出现与常见报错截图相同或类似的网络连接、模型不可达/无法连接服务类错误；② OAuth 已经成功登录，但返回 Antigravity 后后续登录、初始化或授权页面白屏，流程无法继续。**尤其当根因是 Antigravity 或其后台组件没有正确读取/继承系统代理时，本工具正是针对这一层处理。
>
> **EN: This project was created while solving two recurring Antigravity symptoms: (1) network, model-unreachable, or service-connection errors like the commonly reported screenshot/error state; and (2) OAuth completes successfully, but after returning to Antigravity the next login, initialization, or authorization view becomes a blank white page and cannot continue.** It is particularly relevant when the underlying cause is that Antigravity or one of its backend components does not correctly honor/inherit the normal OS proxy.
>
> **中文：**脚本已经尽量做成通用版，但代理客户端、端口、安装路径和系统版本仍可能不同。如果脚本无法启动 Antigravity，或启动后仍无法联网，**不要关闭 TLS 校验、Gatekeeper、SIP、Defender 等安全机制**。先正常打开你的代理工具，再运行下方对应系统的安全诊断命令，把**本仓库脚本 + 已脱敏命令行输出 + 具体报错/截图 + 当前代理客户端名称**一起交给 AI，让 AI 沿用本项目“仅向 Antigravity 进程树注入代理环境变量”的逻辑，为你的机器重写一份。
>
> **EN:** The launcher is designed to be generic, but proxy clients, ports, install paths, and OS versions vary. If it cannot launch Antigravity or Antigravity still has no network access, **do not disable TLS verification, Gatekeeper, SIP, Defender, or other security controls**. Start your normal proxy client, run the safe diagnostic command for your OS below, and give the **launcher + sanitized output + exact error/screenshot + proxy-client name** to an AI assistant. Ask it to preserve this project's process-local proxy-injection design while adapting the launcher to your machine.

[English README / 英文说明](README.md)

---

## 通用脚本无效时 / If the generic launcher does not work

### 诊断前先做什么 / Before collecting diagnostics

**中文**

1. 先打开你准备实际使用的代理客户端，例如 v2rayN、Clash/Mihomo 系客户端、SakuraCat、sing-box/Xray 前端等。
2. 优先使用客户端普通的本地代理/系统代理模式，**本项目不要求开启 TUN**。
3. 完全退出 Antigravity。
4. 按下方对应系统运行诊断命令。
5. 分享结果前，如发现订阅链接、密码、token、cookie、API Key、代理认证信息等敏感内容，请先删除或打码。
6. 把以下内容一起交给 AI：本仓库对应系统的启动脚本、完整且已脱敏的诊断输出、实际报错文字或截图、当前打开的代理客户端名称。

**EN**

1. Start the proxy client you actually want to use (v2rayN, Clash/Mihomo-based client, SakuraCat, sing-box/Xray frontend, etc.).
2. Use its normal local/system-proxy mode if possible. **TUN is not required for this project.**
3. Quit Antigravity completely.
4. Run the diagnostic command for your OS below.
5. Before sharing the output, remove any subscription URL, password, token, cookie, API key, proxy credential, or other secret if one appears.
6. Give an AI assistant the relevant launcher file(s), complete sanitized diagnostic output, exact error/screenshot, and the name of the proxy client currently open.

### Windows 10 / Windows 11 诊断 / Diagnostics

**中文：**按 **Win + R**，输入 `powershell` 并回车，然后把下面整段复制进去运行。该命令只读取信息，不修改代理、不安装软件、不结束进程，也不需要管理员权限。

**EN:** Press **Win + R**, type `powershell`, press Enter, then paste the entire block below. It is read-only: it does not change proxy settings, install software, kill processes, or require Administrator privileges.

```powershell
$ErrorActionPreference = 'SilentlyContinue'

Write-Host '================ ANTIGRAVITY PROXY DIAG BEGIN ================'

Write-Host "`n### 1. Windows / CPU"
Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, BuildNumber, OSArchitecture

Write-Host "`n### 2. Current proxy environment variables"
Get-ChildItem Env: |
    Where-Object { $_.Name -match '^(HTTP|HTTPS|ALL|NO)_PROXY$' } |
    Sort-Object Name |
    ForEach-Object {
        $v = $_.Value -replace '(?i)(https?|socks5?)://[^/@\s]+@', '$1://***@'
        [PSCustomObject]@{ Name = $_.Name; Value = $v }
    } | Format-Table -AutoSize

Write-Host "`n### 3. Current-user Windows Internet proxy"
$inet = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
[PSCustomObject]@{
    ProxyEnable      = $inet.ProxyEnable
    ProxyServer      = $inet.ProxyServer
    HasAutoConfigURL = [bool]$inet.AutoConfigURL
} | Format-List

Write-Host "`n### 4. WinHTTP proxy"
netsh winhttp show proxy

Write-Host "`n### 5. Local TCP listening ports"
Get-NetTCPConnection -State Listen |
    Where-Object { $_.LocalAddress -in @('127.0.0.1','::1','0.0.0.0','::') } |
    Sort-Object LocalPort |
    Select-Object LocalAddress, LocalPort, OwningProcess |
    Format-Table -AutoSize

Write-Host "`n### 6. Antigravity / proxy-related processes (no command-line arguments)"
Get-Process |
    Where-Object { $_.ProcessName -match 'Antigravity|agy|language_server|v2ray|xray|sing|clash|mihomo|sakura' } |
    Select-Object ProcessName, Id, Path |
    Format-Table -AutoSize

Write-Host "`n### 7. Common Antigravity locations"
$candidates = @(
    "$env:LOCALAPPDATA\Programs\antigravity\Antigravity.exe",
    "$env:LOCALAPPDATA\Programs\Antigravity\Antigravity.exe",
    "$env:PROGRAMFILES\Antigravity\Antigravity.exe",
    "${env:PROGRAMFILES(X86)}\Antigravity\Antigravity.exe"
)
$candidates | Where-Object { $_ -and (Test-Path $_) }

Write-Host "`n### 8. Relevant localhost listeners with process names"
Get-NetTCPConnection -State Listen |
    Where-Object { $_.LocalAddress -in @('127.0.0.1','::1','0.0.0.0','::') } |
    ForEach-Object {
        $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
        [PSCustomObject]@{
            Address = $_.LocalAddress
            Port    = $_.LocalPort
            Process = $p.ProcessName
        }
    } |
    Where-Object { $_.Process -match 'v2ray|xray|sing|clash|mihomo|sakura|Antigravity|agy|language' } |
    Sort-Object Port |
    Format-Table -AutoSize

Write-Host "`n================ ANTIGRAVITY PROXY DIAG END =================="
```

### macOS 诊断 / Diagnostics

**中文：**打开 **Terminal/终端**（Command + 空格 → 输入 `Terminal` → 回车），确认代理客户端已经启动，然后粘贴下面整段。该命令只读取信息，并刻意不打印完整进程命令行，以免把后台临时 token 一起输出。

**EN:** Open **Terminal** (Command + Space → type `Terminal` → Enter), make sure your proxy client is already running, then paste the entire block below. It is read-only and intentionally avoids printing full process command lines, which may contain temporary tokens.

```bash
printf '%s\n' '================ ANTIGRAVITY PROXY DIAG BEGIN ================'

printf '\n### 1. macOS / CPU\n'
sw_vers
printf 'Architecture: %s\n' "$(uname -m)"

printf '\n### 2. Current proxy environment variables\n'
env | grep -iE '^(http|https|all|no)_proxy=' | sed -E 's#(https?|socks5?)://[^/@[:space:]]+@#\1://***@#Ig' || echo 'No proxy environment variables found.'

printf '\n### 3. macOS system proxy\n'
scutil --proxy | sed -E 's#(ProxyAutoConfigURLString : ).*#\1<redacted>#'

printf '\n### 4. Network services\n'
networksetup -listallnetworkservices

printf '\n### 5. Antigravity / proxy-related processes (no full arguments)\n'
ps -axo pid=,user=,comm= | grep -iE 'Antigravity|agy|language_server|v2ray|xray|sing|clash|mihomo|sakura' | grep -v grep || echo 'No matching process found.'

printf '\n### 6. Local TCP listening ports\n'
lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null

printf '\n### 7. Likely proxy-related TCP listeners\n'
lsof -nP -iTCP -sTCP:LISTEN 2>/dev/null | grep -iE 'v2ray|xray|sing|clash|mihomo|sakura|127\.0\.0\.1|localhost' || echo 'No obvious proxy listener matched.'

printf '\n### 8. Find Antigravity.app\n'
find /Applications "$HOME/Applications" -maxdepth 2 -iname 'Antigravity.app' -print 2>/dev/null
mdfind 'kMDItemFSName == "Antigravity.app"' 2>/dev/null | head -20

printf '\n### 9. macOS VPN connections\n'
scutil --nc list 2>/dev/null

printf '\n### 10. Relevant system extensions\n'
systemextensionsctl list 2>/dev/null | grep -iE 'v2ray|xray|sing|clash|mihomo|sakura' || echo 'No matching system extension found.'

printf '\n%s\n' '================ ANTIGRAVITY PROXY DIAG END =================='
```

### Linux 诊断 / Diagnostics

**中文：**打开终端，确认代理客户端已经启动，然后粘贴下面整段。命令尽量兼容常见 Linux 发行版，不需要 root。Linux 没有统一的“系统代理”接口，因此会同时检查代理环境变量、可用时的 GNOME 代理设置、本地监听端口、相关进程和常见 Antigravity 路径，并刻意不打印完整进程命令行。

**EN:** Open a terminal, make sure your proxy client is already running, and paste the entire block below. It is designed to work across common Linux distributions without root privileges. Linux has no single universal system-proxy API, so it checks proxy environment variables, GNOME proxy settings when available, local listeners, relevant processes, and common Antigravity locations. It intentionally avoids printing full process command lines.

```bash
printf '%s\n' '================ ANTIGRAVITY PROXY DIAG BEGIN ================'

printf '\n### 1. Linux / CPU / desktop session\n'
[ -r /etc/os-release ] && cat /etc/os-release
printf 'Kernel: %s\n' "$(uname -srmo 2>/dev/null || uname -a)"
printf 'Architecture: %s\n' "$(uname -m)"
printf 'Desktop: %s\n' "${XDG_CURRENT_DESKTOP:-unknown}"
printf 'Session type: %s\n' "${XDG_SESSION_TYPE:-unknown}"

printf '\n### 2. Current proxy environment variables\n'
PROXY_ENV="$(env | grep -iE '^(http|https|all|no)_proxy=' 2>/dev/null || true)"
if [ -n "$PROXY_ENV" ]; then
    printf '%s\n' "$PROXY_ENV" | sed -E 's#(https?|socks5?)://[^/@[:space:]]+@#\1://***@#Ig'
else
    echo 'No proxy environment variables found.'
fi

printf '\n### 3. GNOME proxy settings (if available)\n'
if command -v gsettings >/dev/null 2>&1; then
    printf 'mode: '; gsettings get org.gnome.system.proxy mode 2>/dev/null || true
    printf 'http host: '; gsettings get org.gnome.system.proxy.http host 2>/dev/null || true
    printf 'http port: '; gsettings get org.gnome.system.proxy.http port 2>/dev/null || true
    printf 'https host: '; gsettings get org.gnome.system.proxy.https host 2>/dev/null || true
    printf 'https port: '; gsettings get org.gnome.system.proxy.https port 2>/dev/null || true
    printf 'socks host: '; gsettings get org.gnome.system.proxy.socks host 2>/dev/null || true
    printf 'socks port: '; gsettings get org.gnome.system.proxy.socks port 2>/dev/null || true
else
    echo 'gsettings not available.'
fi

printf '\n### 4. Antigravity / proxy-related processes (no full arguments)\n'
ps -eo pid=,user=,comm= 2>/dev/null | grep -iE 'antigrav|agy|language|v2ray|xray|sing|clash|mihomo|sakura' | grep -v grep || echo 'No matching process found.'

printf '\n### 5. Local TCP listening ports\n'
if command -v ss >/dev/null 2>&1; then
    ss -ltnp 2>/dev/null || ss -ltn 2>/dev/null
elif command -v netstat >/dev/null 2>&1; then
    netstat -ltnp 2>/dev/null || netstat -ltn 2>/dev/null
else
    echo 'Neither ss nor netstat is available.'
fi

printf '\n### 6. Likely proxy-related listeners\n'
if command -v ss >/dev/null 2>&1; then
    ss -ltnp 2>/dev/null | grep -iE 'v2ray|xray|sing|clash|mihomo|sakura|127\.0\.0\.1|\[::1\]' || echo 'No obvious proxy listener matched.'
elif command -v netstat >/dev/null 2>&1; then
    netstat -ltnp 2>/dev/null | grep -iE 'v2ray|xray|sing|clash|mihomo|sakura|127\.0\.0\.1|::1' || echo 'No obvious proxy listener matched.'
fi

printf '\n### 7. Antigravity executable / common locations\n'
command -v antigravity 2>/dev/null || true
for p in \
    /opt/Antigravity/Antigravity \
    /opt/antigravity/antigravity \
    /usr/local/bin/antigravity \
    "$HOME/.local/bin/antigravity" \
    "$HOME/Applications/Antigravity" \
    "$HOME/Applications/antigravity"
do
    [ -e "$p" ] && printf '%s\n' "$p"
done

find "$HOME/.local/share/applications" /usr/share/applications \
    -maxdepth 1 -iname '*antigravity*.desktop' -print 2>/dev/null

if command -v flatpak >/dev/null 2>&1; then
    flatpak list 2>/dev/null | grep -i antigravity || true
fi
if command -v snap >/dev/null 2>&1; then
    snap list 2>/dev/null | grep -i antigravity || true
fi

printf '\n### 8. Executable paths for matching running processes\n'
for pid in $(ps -eo pid=,comm= 2>/dev/null | awk 'tolower($2) ~ /(antigrav|agy|language|v2ray|xray|sing|clash|mihomo|sakura)/ {print $1}'); do
    exe="$(readlink -f "/proc/$pid/exe" 2>/dev/null || true)"
    [ -n "$exe" ] && printf 'PID %s -> %s\n' "$pid" "$exe"
done

printf '\n%s\n' '================ ANTIGRAVITY PROXY DIAG END =================='
```

### 给 AI 的提示词 / Prompt for AI

可以直接把下面这段一起发给 AI / You can use this prompt directly:

```text
I am trying to run Google Antigravity through my normal local proxy without enabling TUN mode.
The generic Antigravity Proxy Launcher did not work on this machine.

Attached/provided are:
1. the launcher script(s) I tried;
2. the complete sanitized diagnostic output;
3. the exact error or observed failure;
4. the proxy client that is currently open.

Please analyze the actual proxy listener, Antigravity install path, OS proxy configuration, and running processes from the diagnostic output. Rewrite the launcher specifically for this machine while preserving the project's design:
- only inject HTTP_PROXY / HTTPS_PROXY / ALL_PROXY (and lowercase variants when appropriate) into Antigravity and its child processes;
- do not enable TUN;
- do not change global system proxy settings unless I explicitly ask;
- do not disable TLS certificate verification, Gatekeeper, SIP, Defender, or other security controls;
- check that the local proxy endpoint is listening before launch;
- prevent attaching to an already-running unproxied Antigravity instance;
- avoid printing or storing secrets.

请根据我提供的启动脚本、已脱敏诊断输出、实际报错和当前代理客户端，为这台机器重写一份 Antigravity 代理启动器。
请沿用本项目的核心逻辑：只给 Antigravity 及其子进程注入 HTTP_PROXY / HTTPS_PROXY / ALL_PROXY（必要时包含小写变量），不启用 TUN，不擅自修改系统全局代理，不关闭 TLS 校验、Gatekeeper、SIP、Defender 等安全机制；启动前检查本地代理端点是否监听，并阻止连接到已经启动但未继承代理环境的旧 Antigravity 进程，同时避免输出或保存任何凭据和 token。
```

### macOS：脚本权限与“身份不明的开发者” / Permission and unidentified-developer errors

**中文：**这里发布的是纯文本 shell 脚本，不是经过 Apple notarization 的 `.app`。检查脚本内容后，先尝试 **Finder → 右键 `.command` 文件 → 打开 → 再点“打开”**。如果仍被拦截，在脚本所在目录打开 Terminal，执行：

**EN:** These are plain-text shell scripts, not a notarized macOS application. After reviewing the script, first try **Finder → right-click the `.command` file → Open → Open**. If macOS still blocks it, open Terminal and run the following commands from the directory containing the script:

```bash
chmod +x antigravity-proxy-macos.command
xattr -d com.apple.quarantine antigravity-proxy-macos.command
./antigravity-proxy-macos.command
```

如果脚本在“下载”目录 / If the file is in Downloads:

```bash
chmod +x ~/Downloads/antigravity-proxy-macos.command
xattr -d com.apple.quarantine ~/Downloads/antigravity-proxy-macos.command
~/Downloads/antigravity-proxy-macos.command
```

**中文：**`chmod +x` 是给脚本添加执行权限；`xattr -d com.apple.quarantine` 只删除**这个脚本自身**的浏览器下载隔离标记。不要执行 `sudo spctl --master-disable`，不要全局关闭 Gatekeeper，也不要关闭 SIP。

**EN:** `chmod +x` grants execute permission. `xattr -d com.apple.quarantine` removes the browser-download quarantine flag **from this script only**. Do not use `sudo spctl --master-disable`, do not disable Gatekeeper globally, and do not disable SIP.

---

## 工作原理 / What it does

**中文：**通过**进程级代理**启动 Google Antigravity，让 Antigravity 及其子进程使用本地 HTTP/SOCKS 代理，同时**无需开启 TUN，也不修改系统全局代理配置**。

**EN:** Launch Google Antigravity with a **process-local proxy** so Antigravity and its child processes can use a local HTTP/SOCKS proxy **without enabling TUN mode or changing global proxy settings**.

启动器会 / The launcher:

1. 自动寻找 Antigravity / Finds Antigravity automatically;
2. 阻止连接到已经运行、无法事后继承代理环境的旧进程 / Refuses to attach to an already-running unproxied instance;
3. 按顺序使用手动覆盖、已有代理环境变量、Windows/macOS 系统代理、常见 localhost 端口 / Chooses manual overrides, existing proxy env vars, Windows/macOS user proxy, then common localhost ports;
4. 只向 Antigravity 进程树注入 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY` 及小写变量 / Injects those variables only into the Antigravity process tree;
5. 启动 Antigravity，让后台子进程继承 / Starts Antigravity so backend processes inherit the proxy.

它不会 / It does not：

- 开启 TUN / enable TUN;
- 修改全局系统代理 / change global system proxy settings;
- 安装虚拟网卡或 Network Extension / install a virtual adapter or Network Extension;
- 关闭 TLS 证书校验 / disable TLS certificate verification;
- 关闭 Gatekeeper、SIP、Windows Defender 等安全机制 / disable Gatekeeper, SIP, Windows Defender, etc.;
- 要求管理员/root 权限 / require Administrator/root privileges.

## 支持平台 / Supported systems

| 系统 / OS | 启动文件 / Launcher | 说明 / Notes |
|---|---|---|
| Windows 10/11 | `antigravity-proxy-windows.cmd` | 配合同目录 PowerShell 脚本 / Uses bundled PowerShell helper |
| macOS | `antigravity-proxy-macos.command` | 读取系统代理并探测本地端口 / Reads macOS proxy + probes local ports |
| Linux | `antigravity-proxy-linux.sh` | 使用环境变量、手动覆盖或常见端口 / Uses env/manual overrides/common ports |

脚本不绑定具体代理客户端。只要客户端暴露本地 HTTP、SOCKS5 或 mixed 代理端点，就可用于 v2rayN、Clash/Mihomo 系客户端、SakuraCat、sing-box/Xray 前端等。

The launcher is proxy-client agnostic. It can work with v2rayN, Clash/Mihomo-based clients, SakuraCat, sing-box/Xray frontends, and other clients exposing a local HTTP/SOCKS5/mixed proxy endpoint.

## 快速使用 / Quick start

### Windows

1. 启动代理客户端，不需要 TUN / Start your proxy client; TUN is not required;
2. 完全退出 Antigravity / Quit Antigravity completely;
3. 将 `antigravity-proxy-windows.cmd` 与 `antigravity-proxy-windows.ps1` 放在同一目录 / Put both files in the same folder;
4. 双击 `antigravity-proxy-windows.cmd` / Double-click it.

### macOS

```bash
git clone https://github.com/peroperoyui-lab/antigravity-login-tool--.git
cd antigravity-login-tool--
./antigravity-proxy-macos.command
```

如果通过浏览器下载，请按上方 macOS 权限章节处理 / If downloaded through a browser, use the macOS permission steps above.

### Linux

```bash
chmod +x antigravity-proxy-linux.sh
./antigravity-proxy-linux.sh
```

## 自动识别代理 / Automatic proxy detection

兜底端口 / Fallback ports：`10808`, `10809`, `7890`, `7897`, `7891`。

Windows/macOS 会优先读取当前用户系统代理；也可通过 `AG_PROXY_PORT`、`AG_HTTP_PROXY`、`AG_SOCKS_PROXY` 手动指定。

Windows/macOS prefer the current user proxy when available; manual overrides are available through `AG_PROXY_PORT`, `AG_HTTP_PROXY`, and `AG_SOCKS_PROXY`.

## 手动指定 / Manual override

### 单一 mixed 端口 / One mixed port

macOS/Linux:

```bash
AG_PROXY_PORT=12345 ./antigravity-proxy-macos.command
```

Windows CMD:

```bat
set AG_PROXY_PORT=12345
antigravity-proxy-windows.cmd
```

### 分别指定 HTTP 与 SOCKS / Explicit HTTP and SOCKS endpoints

macOS/Linux:

```bash
AG_HTTP_PROXY=http://127.0.0.1:12345 \
AG_SOCKS_PROXY=socks5://127.0.0.1:12346 \
./antigravity-proxy-macos.command
```

Windows CMD:

```bat
set AG_HTTP_PROXY=http://127.0.0.1:12345
set AG_SOCKS_PROXY=socks5://127.0.0.1:12346
antigravity-proxy-windows.cmd
```

## 为什么必须先退出 Antigravity？ / Why quit Antigravity first?

**中文：**环境变量是在创建子进程时继承的，无法事后注入已经运行的 Antigravity，因此必须先彻底退出旧实例。

**EN:** Environment variables are inherited when a child process is created; they cannot be retroactively injected into an already-running Antigravity instance.

## 安全说明 / Security model

**中文：**所有启动器都是可直接审查的纯文本脚本，并明确避免关闭 TLS 校验或操作系统安全机制。从非可信镜像下载时请先检查源码。代理 URL 如果包含用户名/密码，部分系统上同一用户的其他进程可能看到相关环境变量，因此尽量使用不内嵌凭据的 localhost 本地代理。

**EN:** All launchers are plain-text scripts. They intentionally avoid disabling TLS verification or OS security features. Review scripts downloaded from untrusted mirrors. Proxy credentials in environment variables may be visible to other processes running as the same user, so prefer a localhost proxy without embedded credentials when possible.

## 常见问题 / Troubleshooting

**提示找不到代理 / No proxy detected**  
先启动代理客户端，或手动设置 `AG_PROXY_PORT` / `AG_HTTP_PROXY`。 / Start the proxy client first, or set `AG_PROXY_PORT` / `AG_HTTP_PROXY` manually.

**提示 Antigravity 已经运行 / Antigravity is already running**  
彻底退出后再通过本工具启动。 / Quit it completely, then relaunch through this tool.

**只有 SOCKS 端口仍无法联网 / SOCKS-only proxy still does not work**  
部分组件可能只读取 `HTTP_PROXY` / `HTTPS_PROXY`，建议启用 HTTP 或 mixed 本地端口。 / Some components may specifically honor `HTTP_PROXY` / `HTTPS_PROXY`; configure an HTTP or mixed endpoint.

**macOS 提示“身份不明的开发者” / macOS says the developer is unidentified**  
检查源码后 Finder 右键打开，或仅移除该脚本自身的 quarantine 标记，不要全局关闭 Gatekeeper。 / Use Finder Right click → Open after reviewing the script, or remove quarantine from that script only; do not disable Gatekeeper globally.

## License

MIT
