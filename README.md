# Antigravity Proxy Launcher

> **English / 中文 — Read this first / 请先看这里**
>
> **EN:** This project launches Google Antigravity with a **process-local HTTP/SOCKS proxy**. It is intended for the common case where your proxy client is working and browsers can reach the Internet, but Antigravity or one of its backend processes still ignores the normal OS proxy. **TUN mode is not required.**
>
> **中文：**本项目通过给 Google Antigravity 及其子进程注入**进程级 HTTP/SOCKS 代理**来解决“浏览器能通过代理联网，但 Antigravity 或后台进程仍然不走系统代理”的问题。**不需要开启 TUN。**
>
> **EN:** The launcher is designed to be generic, but proxy clients, ports, install paths and OS versions vary. If the supplied script cannot launch Antigravity or Antigravity still has no network access, **do not disable TLS verification, Gatekeeper, SIP, Defender, or other security controls**. Instead, start your normal proxy client, collect the safe diagnostic output below, and give the launcher files + diagnostic output + exact error to an AI assistant. Ask it to rewrite the launcher while preserving the same process-local proxy-injection design.
>
> **中文：**脚本已经尽量做成通用版，但不同代理客户端、端口、安装路径和系统版本仍可能存在差异。如果脚本无法启动 Antigravity，或者启动后仍无法联网，**不要关闭 TLS 校验、Gatekeeper、SIP、Defender 等安全机制**。请先正常打开你的代理工具，再运行下方安全诊断命令，把**本仓库脚本 + 命令行输出 + 具体报错**一起交给 AI，让 AI 沿用本项目的“仅向 Antigravity 进程树注入代理环境变量”的逻辑，为你的机器重写一份。

[中文说明 / Chinese README](README.zh-CN.md)

---

## If the generic launcher does not work / 如果通用脚本无效

### Before collecting diagnostics / 诊断前先做什么

**EN**

1. Start the proxy client you actually want to use (v2rayN, Clash/Mihomo-based client, SakuraCat, sing-box/Xray frontend, etc.).
2. Use its normal local/system-proxy mode if possible. **TUN is not required for this project.**
3. Quit Antigravity completely.
4. Run the diagnostic command for your OS below.
5. Before sharing the output, remove any subscription URL, password, token, cookie, API key, proxy credential or other secret if one appears.
6. Give an AI assistant:
   - the relevant launcher file(s) from this repository;
   - the complete sanitized diagnostic output;
   - the exact error message or screenshot;
   - the name of the proxy client you currently have open.

**中文**

1. 先打开你准备实际使用的代理客户端，例如 v2rayN、Clash/Mihomo 系客户端、SakuraCat、sing-box/Xray 前端等。
2. 优先使用客户端普通的本地代理/系统代理模式，**本项目不要求开启 TUN**。
3. 完全退出 Antigravity。
4. 按下方对应系统运行诊断命令。
5. 分享结果前，如发现订阅链接、密码、token、cookie、API Key、代理认证信息等敏感内容，请先删除或打码。
6. 把以下内容一起交给 AI：
   - 本仓库对应系统的启动脚本；
   - 完整且已脱敏的诊断输出；
   - 实际报错文字或截图；
   - 当前打开的代理客户端名称。

### Windows 10 / Windows 11 diagnostics / Windows 10、11 诊断

**EN:** Press **Win + R**, type `powershell`, press Enter, then paste the entire block below. It is read-only: it does not change proxy settings, install software, kill processes, or require Administrator privileges.

**中文：**按 **Win + R**，输入 `powershell` 并回车，然后把下面整段复制进去运行。该命令只读取信息，不修改代理、不安装软件、不结束进程，也不需要管理员权限。

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
    Format-Table -AutoSize

Write-Host "`n### 3. Current-user Windows Internet proxy"
$inet = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
[PSCustomObject]@{
    ProxyEnable   = $inet.ProxyEnable
    ProxyServer   = $inet.ProxyServer
    AutoConfigURL = $inet.AutoConfigURL
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

### macOS diagnostics / macOS 诊断

**EN:** Open **Terminal** (Command + Space → type `Terminal` → Enter), make sure your proxy client is already running, then paste the entire block below. It is read-only and intentionally avoids printing full process command lines, which may contain temporary tokens.

**中文：**打开 **Terminal/终端**（Command + 空格 → 输入 `Terminal` → 回车），确认代理客户端已经启动，然后粘贴下面整段。该命令只读取信息，并刻意不打印完整进程命令行，以免把后台临时 token 一起输出。

```bash
printf '%s\n' '================ ANTIGRAVITY PROXY DIAG BEGIN ================'

printf '\n### 1. macOS / CPU\n'
sw_vers
printf 'Architecture: %s\n' "$(uname -m)"

printf '\n### 2. Current proxy environment variables\n'
env | grep -iE '^(http|https|all|no)_proxy=' || echo 'No proxy environment variables found.'

printf '\n### 3. macOS system proxy\n'
scutil --proxy

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

### What to ask the AI to do / 给 AI 的提示词

You can use this prompt directly / 可以直接把下面这段一起发给 AI：

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

### macOS: permission / unidentified developer errors / macOS：脚本权限与“身份不明的开发者”

**EN:** These are plain-text shell scripts, not a notarized macOS application. After reviewing the script, first try **Finder → right-click the `.command` file → Open → Open**. If macOS still blocks it, open Terminal and run the following commands from the directory containing the script:

**中文：**这里发布的是纯文本 shell 脚本，不是经过 Apple notarization 的 `.app`。检查脚本内容后，先尝试 **Finder → 右键 `.command` 文件 → 打开 → 再点“打开”**。如果仍被拦截，在脚本所在目录打开 Terminal，执行：

```bash
chmod +x antigravity-proxy-macos.command
xattr -d com.apple.quarantine antigravity-proxy-macos.command
./antigravity-proxy-macos.command
```

If the file is in Downloads / 如果脚本在“下载”目录：

```bash
chmod +x ~/Downloads/antigravity-proxy-macos.command
xattr -d com.apple.quarantine ~/Downloads/antigravity-proxy-macos.command
~/Downloads/antigravity-proxy-macos.command
```

**EN:** `chmod +x` grants execute permission. `xattr -d com.apple.quarantine` removes the browser-download quarantine flag **from this script only**. Do not use `sudo spctl --master-disable`, do not disable Gatekeeper globally, and do not disable SIP.

**中文：**`chmod +x` 是给脚本添加执行权限；`xattr -d com.apple.quarantine` 只删除**这个脚本自身**的浏览器下载隔离标记。不要执行 `sudo spctl --master-disable`，不要全局关闭 Gatekeeper，也不要关闭 SIP。

---

## What it does

Launch Google Antigravity with a **process-local proxy** so Antigravity and its child processes can use a local HTTP/SOCKS proxy **without enabling TUN mode or changing global proxy settings**.

This is useful on machines where browsers work through the OS proxy, but Antigravity or one of its backend processes still cannot reach the network reliably.

The launcher:

1. Finds the Antigravity executable/app automatically.
2. Refuses to attach to an already-running Antigravity process, because an existing process cannot inherit new environment variables.
3. Chooses a proxy using the following priority:
   - explicit launcher overrides (`AG_HTTP_PROXY`, `AG_SOCKS_PROXY`, `AG_PROXY_PORT`);
   - existing proxy environment variables;
   - the current OS user proxy (Windows/macOS);
   - common localhost proxy ports as a fallback.
4. Injects `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY` and lowercase variants into **only the Antigravity process tree**.
5. Starts Antigravity. Child processes inherit the same proxy environment.

It does **not**:

- enable TUN;
- modify system-wide proxy settings;
- install a network extension or virtual adapter;
- disable TLS certificate verification;
- disable Gatekeeper, SIP, Windows Defender, or other security controls;
- require administrator/root privileges.

## Supported systems

| OS | Launcher | Notes |
|---|---|---|
| Windows 10/11 | `antigravity-proxy-windows.cmd` | Uses bundled PowerShell script for detection and launch |
| macOS | `antigravity-proxy-macos.command` | Checks macOS system proxy and common local ports |
| Linux | `antigravity-proxy-linux.sh` | Uses existing env vars, manual overrides, or common local ports |

The launcher is proxy-client agnostic. It can work with v2rayN, Clash/Mihomo-based clients, SakuraCat, sing-box/Xray frontends, and other clients that expose a local HTTP, SOCKS5, or mixed proxy endpoint.

## Quick start

### Windows

1. Start your proxy client. TUN is not required.
2. Quit Antigravity completely.
3. Download both files into the same directory:
   - `antigravity-proxy-windows.cmd`
   - `antigravity-proxy-windows.ps1`
4. Double-click `antigravity-proxy-windows.cmd`.

The `.cmd` wrapper runs the local PowerShell script with a process-scoped execution-policy bypass. It does not change the machine/user PowerShell execution policy.

### macOS

If you clone the repository with Git:

```bash
git clone https://github.com/peroperoyui-lab/antigravity-login-tool--.git
cd antigravity-login-tool--
./antigravity-proxy-macos.command
```

If you download the raw script through a browser, macOS may add a quarantine flag. Inspect the script first, then either use Finder **Right click → Open**, or explicitly remove the quarantine flag from this file only:

```bash
chmod +x antigravity-proxy-macos.command
xattr -d com.apple.quarantine antigravity-proxy-macos.command
./antigravity-proxy-macos.command
```

Do **not** disable Gatekeeper globally.

### Linux

```bash
chmod +x antigravity-proxy-linux.sh
./antigravity-proxy-linux.sh
```

## Automatic proxy detection

Default fallback ports:

- `10808` — common v2rayN/mixed proxy port
- `10809` — common HTTP proxy port in older v2rayN setups
- `7890` — common Clash/Mihomo mixed proxy port
- `7897` — used by some Clash/Mihomo-based setups
- `7891` — common SOCKS proxy port

OS proxy settings are preferred over this fallback list, so users normally do not need to edit the scripts.

## Manual override

For unusual ports or custom clients, explicit overrides are recommended.

### One mixed port

macOS/Linux:

```bash
AG_PROXY_PORT=12345 ./antigravity-proxy-macos.command
```

Windows Command Prompt:

```bat
set AG_PROXY_PORT=12345
antigravity-proxy-windows.cmd
```

### Explicit HTTP and SOCKS endpoints

macOS/Linux:

```bash
AG_HTTP_PROXY=http://127.0.0.1:12345 \
AG_SOCKS_PROXY=socks5://127.0.0.1:12346 \
./antigravity-proxy-macos.command
```

Windows Command Prompt:

```bat
set AG_HTTP_PROXY=http://127.0.0.1:12345
set AG_SOCKS_PROXY=socks5://127.0.0.1:12346
antigravity-proxy-windows.cmd
```

### Custom Antigravity location

Set `AG_APP` to the executable path (or, on macOS, the `.app` bundle path):

```bash
AG_APP=/custom/path/Antigravity.app ./antigravity-proxy-macos.command
```

On Windows:

```bat
set AG_APP=D:\Apps\Antigravity\Antigravity.exe
antigravity-proxy-windows.cmd
```

## Why quit Antigravity first?

Environment variables are inherited when a child process is created. They cannot be retroactively injected into an already-running Antigravity process. If Antigravity is already open, the launcher therefore exits and asks you to quit it first.

## Security model

All launchers are plain-text scripts. Review them before running if you downloaded them from an untrusted mirror.

The scripts intentionally avoid dangerous workarounds such as disabling TLS verification or disabling OS security features. Proxy credentials placed in environment variables can be visible to processes running under the same user account on some operating systems, so prefer localhost proxies without embedded credentials when possible.

## Troubleshooting

**No proxy detected**  
Start the proxy client first, or set `AG_PROXY_PORT` / `AG_HTTP_PROXY` manually.

**Antigravity is already running**  
Quit Antigravity completely and launch it again through this tool.

**SOCKS-only proxy still does not work**  
Some Antigravity components/libraries may specifically honor `HTTP_PROXY` / `HTTPS_PROXY`. Configure an HTTP or mixed local proxy endpoint in your proxy client, then point `AG_HTTP_PROXY` to it.

**macOS says the developer is unidentified**  
This repository distributes source scripts, not a notarized `.app`. Use Finder Right click → Open after reviewing the script, or remove quarantine from that script only. Do not disable Gatekeeper globally.

## License

MIT
