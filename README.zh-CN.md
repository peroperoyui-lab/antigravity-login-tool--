# Antigravity Proxy Launcher

> **请先看这里 / Read this first**
>
> **中文：**本项目通过给 Google Antigravity 及其子进程注入**进程级 HTTP/SOCKS 代理**来解决“浏览器能通过代理联网，但 Antigravity 或后台进程仍然不走系统代理”的问题。**不需要开启 TUN。**
>
> **EN:** This project launches Google Antigravity with a **process-local HTTP/SOCKS proxy**. It is intended for the common case where your proxy client is working and browsers can reach the Internet, but Antigravity or one of its backend processes still ignores the normal OS proxy. **TUN mode is not required.**
>
> **中文：**脚本已经尽量做成通用版，但不同代理客户端、端口、安装路径和系统版本仍可能存在差异。如果脚本无法启动 Antigravity，或者启动后仍无法联网，**不要关闭 TLS 校验、Gatekeeper、SIP、Defender 等安全机制**。请先正常打开你的代理工具，再运行下方安全诊断命令，把**本仓库脚本 + 命令行输出 + 具体报错**一起交给 AI，让 AI 沿用本项目的“仅向 Antigravity 进程树注入代理环境变量”的逻辑，为你的机器重写一份。
>
> **EN:** The launcher is designed to be generic, but proxy clients, ports, install paths and OS versions vary. If it cannot launch Antigravity or Antigravity still has no network access, **do not disable TLS verification, Gatekeeper, SIP, Defender, or other security controls**. Start your normal proxy client, collect the safe diagnostic output below, and give the launcher files + diagnostic output + exact error to an AI assistant. Ask it to rewrite the launcher while preserving the same process-local proxy-injection design.

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
5. Before sharing the output, remove any subscription URL, password, token, cookie, API key, proxy credential or other secret if one appears.
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

### macOS 诊断 / Diagnostics

**中文：**打开 **Terminal/终端**（Command + 空格 → 输入 `Terminal` → 回车），确认代理客户端已经启动，然后粘贴下面整段。该命令只读取信息，并刻意不打印完整进程命令行，以免把后台临时 token 一起输出。

**EN:** Open **Terminal** (Command + Space → type `Terminal` → Enter), make sure your proxy client is already running, then paste the entire block below. It is read-only and intentionally avoids printing full process command lines, which may contain temporary tokens.

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

## 工作原理

一个给 Google Antigravity 使用的**进程级代理启动器**：让 Antigravity 及其子进程继承本地 HTTP/SOCKS 代理，同时**无需开启 TUN，也不修改系统全局代理配置**。

适用于这类情况：浏览器通过系统代理可以正常联网，但 Antigravity 或其后台进程仍然无法稳定访问网络。

启动器会：

1. 自动寻找 Antigravity；
2. 检查 Antigravity 是否已经运行——旧进程无法事后继承新的环境变量，因此必须先彻底退出；
3. 按以下顺序选择代理：
   - 用户显式指定的 `AG_HTTP_PROXY` / `AG_SOCKS_PROXY` / `AG_PROXY_PORT`；
   - 当前 shell 已有的代理环境变量；
   - Windows/macOS 当前用户的系统代理；
   - 常见 localhost 代理端口作为兜底；
4. 只在 Antigravity 进程树内注入 `HTTP_PROXY`、`HTTPS_PROXY`、`ALL_PROXY` 及其小写版本；
5. 启动 Antigravity，其后台/子进程自动继承这些变量。

它不会：

- 开启 TUN；
- 修改全局系统代理；
- 安装虚拟网卡或 Network Extension；
- 关闭 TLS 证书校验；
- 关闭 Gatekeeper、SIP、Windows Defender 等安全机制；
- 要求管理员/root 权限。

## 支持平台

| 系统 | 启动文件 | 说明 |
|---|---|---|
| Windows 10/11 | `antigravity-proxy-windows.cmd` | 配合同目录 PowerShell 脚本完成检测与启动 |
| macOS | `antigravity-proxy-macos.command` | 自动读取 macOS 系统代理并探测常见本地端口 |
| Linux | `antigravity-proxy-linux.sh` | 使用现有环境变量、手动覆盖或常见本地端口 |

脚本不绑定具体代理客户端。只要客户端提供本地 HTTP、SOCKS5 或 mixed 代理端点，就可以用于 v2rayN、Clash/Mihomo 系客户端、SakuraCat、sing-box/Xray 前端等。

## 快速使用

### Windows

1. 启动代理客户端，不需要 TUN；
2. 完全退出 Antigravity；
3. 将以下两个文件放在同一目录：
   - `antigravity-proxy-windows.cmd`
   - `antigravity-proxy-windows.ps1`
4. 双击 `antigravity-proxy-windows.cmd`。

`.cmd` 只为当前 PowerShell 子进程使用 `ExecutionPolicy Bypass`，不会修改系统或当前用户的 PowerShell 执行策略。

### macOS

使用 Git clone：

```bash
git clone https://github.com/peroperoyui-lab/antigravity-login-tool--.git
cd antigravity-login-tool--
./antigravity-proxy-macos.command
```

如果直接通过浏览器下载脚本，macOS 可能为其添加 quarantine 标记。先检查脚本内容，然后可以 Finder **右键 → 打开**，或者只移除这个文件自身的隔离标记：

```bash
chmod +x antigravity-proxy-macos.command
xattr -d com.apple.quarantine antigravity-proxy-macos.command
./antigravity-proxy-macos.command
```

不要全局关闭 Gatekeeper。

### Linux

```bash
chmod +x antigravity-proxy-linux.sh
./antigravity-proxy-linux.sh
```

## 自动识别代理

兜底探测的常见端口包括：

- `10808`：常见 v2rayN / mixed 端口；
- `10809`：旧版 v2rayN 配置中常见 HTTP 端口；
- `7890`：Clash/Mihomo 常见 mixed 端口；
- `7897`：部分 Clash/Mihomo 系配置使用；
- `7891`：常见 SOCKS 端口。

Windows/macOS 上会优先读取当前用户系统代理，因此正常情况下无需修改脚本。

## 手动指定

如果你的客户端用了特殊端口，建议显式指定。

### 单一 mixed 端口

macOS/Linux：

```bash
AG_PROXY_PORT=12345 ./antigravity-proxy-macos.command
```

Windows CMD：

```bat
set AG_PROXY_PORT=12345
antigravity-proxy-windows.cmd
```

### 分别指定 HTTP 与 SOCKS

macOS/Linux：

```bash
AG_HTTP_PROXY=http://127.0.0.1:12345 \
AG_SOCKS_PROXY=socks5://127.0.0.1:12346 \
./antigravity-proxy-macos.command
```

Windows CMD：

```bat
set AG_HTTP_PROXY=http://127.0.0.1:12345
set AG_SOCKS_PROXY=socks5://127.0.0.1:12346
antigravity-proxy-windows.cmd
```

### Antigravity 不在默认位置

通过 `AG_APP` 指定。macOS 可以给 `.app` 路径或实际可执行文件路径：

```bash
AG_APP=/custom/path/Antigravity.app ./antigravity-proxy-macos.command
```

Windows：

```bat
set AG_APP=D:\Apps\Antigravity\Antigravity.exe
antigravity-proxy-windows.cmd
```

## 为什么必须先退出 Antigravity？

环境变量是在创建子进程时继承的，无法事后注入到已经运行的 Antigravity。因此检测到旧实例时，启动器会主动停止并提示先退出，而不是挂到一个没有代理环境的旧进程上。

## 安全说明

所有内容都是可直接审查的纯文本脚本。脚本明确避免关闭 TLS 校验、全局关闭 Gatekeeper 等高风险“修复方式”。

如果代理 URL 中包含用户名/密码，部分系统上同一用户权限下的其他进程可能看到环境变量，因此建议优先使用不带凭据的 localhost 本地代理。

## 常见问题

**提示找不到代理**  
先启动代理客户端；或者手动设置 `AG_PROXY_PORT` / `AG_HTTP_PROXY`。

**提示 Antigravity 已经运行**  
彻底退出 Antigravity，再通过本启动器打开。

**只有 SOCKS 端口仍然无法联网**  
Antigravity 的部分组件/网络库可能只读取 `HTTP_PROXY` / `HTTPS_PROXY`。建议在代理客户端开启 HTTP 或 mixed 本地端口，再通过 `AG_HTTP_PROXY` 指向它。

**macOS 提示“身份不明的开发者”**  
这里发布的是源码脚本，不是经过 Apple notarization 的 `.app`。检查源码后使用 Finder 右键打开，或者只删除该脚本的 quarantine 标记；不要关闭整个 Gatekeeper。

## License

MIT
