# Antigravity Proxy Launcher
如果本机有可用agent，直接把仓库发给agent即可。其实大概率是没法拿来直接用的，主要是给你的ai提供一个解决这个问题的思路，让你能最快的根据你的本机情况，让你用的ai给你做一个你能直接用的脚本。你根据你的设备系统，从上面的脚本里挑对应的下载下来，然后找到下方的简介，用系统的命令行工具运行下方的提示词，然后把脚本和命令行的输出一起扔给ai，它给你写一个新的脚本，就是你专用的了。注意本机需要已经安装antigravity，并且代理软件还是打开的，具体注意事项和流程见下方详细说明。以后想用antigravity，就直接用脚本启动就行，antigravity的快捷方式可以更换地址给脚本文件的地址，因为保留图标显得比较好看。（只有这句话不是GPT写的哈哈）

If an agent is available on the local machine, simply send the repository directly to the agent.In all likelihood, you won't be able to use the scripts directly; their main purpose is to provide your AI with a strategy for solving the problem. This allows you to quickly generate a ready-to-use script tailored to your specific local setup. Simply select and download the appropriate script for your operating system from the list above, locate the brief description below it, run the provided prompt using your system's command-line tool, and then feed both the script and the command-line output to the AI; it will then generate a new, custom script specifically for you. Please note that you must have `antigravity` installed locally and your proxy software running; refer to the detailed instructions below for specific requirements and the workflow.In the future, if you want to use Antigravity, simply launch it via the script. You can update the target path of the Antigravity shortcut to point to the script file instead, as keeping the icon makes it look better. (this is the only sentence here not written by GPT, haha).

## 先怎么用 / Quick start

先确保 **Antigravity 已经安装**，并且你的代理软件已经正常打开。**不用开 TUN。**第一次先直接试对应系统的通用脚本；如果能正常打开并联网，以后都从这个脚本启动 Antigravity 即可。如果不行，再看后面的“通用脚本无效时”诊断部分。

Make sure **Antigravity is installed** and your proxy client is already running. **TUN is not required.** Try the generic launcher for your OS first. If Antigravity opens and works normally, just use that launcher from now on. If it does not work, continue to the diagnostic section below.

### Windows 10 / 11

下载下面 **两个文件**，放在同一个文件夹里：

- [`antigravity-proxy-windows.cmd`](antigravity-proxy-windows.cmd)
- [`antigravity-proxy-windows.ps1`](antigravity-proxy-windows.ps1)

然后：

1. 打开你的代理软件；
2. 完全退出已经打开的 Antigravity；
3. **双击 `antigravity-proxy-windows.cmd`**；
4. 不需要手动运行 `.ps1`，`.cmd` 会自动调用它。

Download **both files** above into the same folder, start your proxy client, quit any running Antigravity instance, then **double-click `antigravity-proxy-windows.cmd`**. The `.cmd` file will call the PowerShell helper automatically.

### macOS

只需要下载：

- [`antigravity-proxy-macos.command`](antigravity-proxy-macos.command)

然后：

1. 打开你的代理软件；
2. 用 `Command + Q` 完全退出 Antigravity；
3. 双击 `antigravity-proxy-macos.command` 启动。

如果第一次提示**没有执行权限 / 身份不明的开发者**，先在 Finder 里右键脚本 → **打开**。如果仍然被拦，打开 Terminal，把下面两条命令中的脚本路径换成你下载文件的实际位置；最简单的方法是输入命令和一个空格后，把脚本文件直接拖进 Terminal：

```bash
chmod +x /path/to/antigravity-proxy-macos.command
xattr -d com.apple.quarantine /path/to/antigravity-proxy-macos.command
```

然后再双击脚本。不要为了这个脚本全局关闭 Gatekeeper。

Download only [`antigravity-proxy-macos.command`](antigravity-proxy-macos.command), start your proxy client, quit Antigravity with `Command + Q`, and run the `.command` file. If macOS blocks it, use Finder **Right click → Open**, or grant execute permission and remove the quarantine flag from this file only with the commands above.

### Linux

下载：

- [`antigravity-proxy-linux.sh`](antigravity-proxy-linux.sh)

打开终端，进入脚本所在目录，然后运行：

```bash
chmod +x antigravity-proxy-linux.sh
./antigravity-proxy-linux.sh
```

运行前同样先打开你的代理软件，并退出已有的 Antigravity 进程。

Download [`antigravity-proxy-linux.sh`](antigravity-proxy-linux.sh), open a terminal in that directory, run the two commands above, and make sure your proxy client is already running and Antigravity is closed first.

> **如果上面的通用脚本直接有效，到这里就够了。下面才是脚本无效、端口或安装路径不兼容时的排查方法。**  
> **If the generic launcher works, you can stop here. The sections below are for machines where automatic detection fails or needs customization.**

> **English / 中文 — Read this first / 请先看这里**
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

## Gemini web “Something went wrong” / blank page — Gems Creator workaround
## Gemini 网页“出了点问题”/ 白屏——Gems Creator 旁路重置法

> **Community workaround / 社区验证方法：**这和 Antigravity 的本地代理问题是两件不同的事。如果 **Gemini 网页本身**在 Google 账号登录后卡在 `Something went wrong / 出了点问题`、白屏或无法进入聊天界面，可以试下面这个“邪修”。Gemini Apps Community 里有多条 2026 年案例复现成功，但 **Google 没有把它作为百分之百保证有效的正式修复方案**。
>
> **EN:** This is separate from Antigravity’s local proxy issue. If the **Gemini website itself** becomes stuck on `Something went wrong`, a blank page, or an unusable post-login UI, the following workaround has been repeatedly reported as successful in the Gemini Apps Community. It is a **community workaround, not an officially guaranteed repair**.

大家说的“**去 Gemini 设一个人设就能救回来**”，更准确地说，是**绕过坏掉的 Gemini 首页，直接进入 Gems Creator，创建一个临时 Gem/人设，并让右侧 Preview 成功完成一次对话**。

What people often describe as “**set a persona in Gemini**” is more precisely: **bypass the broken Gemini landing page, open Gems Creator directly, create a temporary Gem/persona, and make the Preview chat successfully complete one request.**

### 操作步骤 / Steps

1. **保持登录那个出问题的 Google 账号。**  
   **Stay signed in to the affected Google account.**

2. 不要先打开普通 Gemini 首页，直接访问：  
   Instead of opening the normal Gemini homepage, go directly to:

   **https://gemini.google.com/gems/create**

3. 如果 Gems Creator 能正常加载，随便创建一个临时 Gem/“人设”。内容不重要，例如：  
   If Gems Creator loads, create any temporary Gem/persona. The content does not matter, for example:

   - Name / 名称：`Test`
   - Instructions / 人设说明：`You are a helpful assistant.` / `你是一个乐于助人的助手。`

4. 在页面**右侧 Preview / 预览聊天框**里发送一句：  
   In the **Preview chat on the right**, send:

   `Hi`

5. **一定要等 Gemini 真正回复一次。**这一步是关键。  
   **Wait until Gemini actually replies once.** This is the important part.

6. 然后重新打开：  
   Then return to:

   **https://gemini.google.com/**

   刷新页面，再尝试正常聊天界面。  
   Refresh and try the normal chat UI again.

7. 如果恢复了，刚才创建的临时 Gem 之后删掉即可。  
   If the main page works again, you can delete the temporary Gem afterwards.

### 还没恢复？ / Still broken?

如果 `/gems/create` 能打开，但 Gemini 首页仍然不行，可以尝试**在这个能正常工作的 Gems 页面里退出账号，再重新登录，然后重复上面的创建 Gem + Preview 发 `Hi` 流程**。有用户反馈这会进一步触发账号/session 重新初始化。

If `/gems/create` works but the main Gemini page still does not, try **signing out and back in from the working Gems route**, then repeat the temporary-Gem + Preview `Hi` sequence. Some users report that this forces a fresher account/session initialization.

如果连 `/gems/create` 都打不开，这个方法大概率不适用于你的故障。此时继续检查无痕模式、Cookie/缓存、浏览器扩展、Google 账号资料、Gemini Apps Activity，或者向 Google 反馈账号级故障。

If `/gems/create` itself also fails, this workaround probably does not apply. Continue with normal browser/account troubleshooting such as Incognito/Private mode, cookies/cache, extensions, Google account/profile checks, Gemini Apps Activity, or report the account-specific failure to Google.

### 为什么这种“邪修”可能有效？ / Why can this work?

Gemini Apps Community 的多条案例表明，有时出问题的是**特定 Google 账号在 Gemini 主页面上的 backend/session 状态**，而 Gems Creator 这条页面路径仍然能正常工作。通过 Gems Creator 创建一个 Gem 并让 Preview 成功请求一次，**似乎会通过另一条可工作的路径触发账号/session 的初始化或刷新**，之后主页面可能恢复。这个解释来自社区排障观察；Google 没有正式公开该 workaround 的后台根因。

Multiple Gemini Apps Community cases suggest that an **account-specific Gemini landing-page/backend session state** can become stuck while the Gems Creator route still works. Creating a Gem and successfully using its Preview **appears to trigger initialization or refresh through another working route**, after which the main Gemini page may recover. This explanation is based on observed community troubleshooting; Google has not published a formal backend root-cause explanation for the workaround.

**Detailed bilingual guide / 双语详细说明：** [GEMINI-WEB-WORKAROUND.md](GEMINI-WEB-WORKAROUND.md)

Community examples / 社区案例：
- https://support.google.com/gemini/thread/435427584/
- https://support.google.com/gemini/thread/440304023/
- https://support.google.com/gemini/thread/441307364/
- https://support.google.com/gemini/thread/436277317/

---

[中文说明 / Chinese README](README.zh-CN.md)

---

## If the generic launcher does not work / 如果通用脚本无效

### Before collecting diagnostics / 诊断前先做什么

**EN**

1. Start the proxy client you actually want to use (v2rayN, Clash/Mihomo-based client, SakuraCat, sing-box/Xray frontend, etc.).
2. Use its normal local/system-proxy mode if possible. **TUN is not required for this project.**
3. Quit Antigravity completely.
4. Run the diagnostic command for your OS below.
5. Before sharing the output, remove any subscription URL, password, token, cookie, API key, proxy credential, or other secret if one appears.
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
    ForEach-Object {
        $v = $_.Value -replace '(?i)(https?|socks5?)://[^/@\s]+@', '$1://***@'
        [PSCustomObject]@{ Name = $_.Name; Value = $v }
    } | Format-Table -AutoSize

Write-Host "`n### 3. Current-user Windows Internet proxy"
$inet = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
[PSCustomObject]@{
    ProxyEnable       = $inet.ProxyEnable
    ProxyServer       = $inet.ProxyServer
    HasAutoConfigURL  = [bool]$inet.AutoConfigURL
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

### Linux diagnostics / Linux 诊断

**EN:** Open a terminal, make sure your proxy client is already running, and paste the entire block below. It is designed to work across common Linux distributions without root privileges. Linux has no single universal “system proxy” API, so the diagnostic checks proxy environment variables, GNOME proxy settings when available, local listeners, relevant processes, and common Antigravity locations. It intentionally avoids printing full process command lines.

**中文：**打开终端，确认代理客户端已经启动，然后粘贴下面整段。命令尽量兼容常见 Linux 发行版，不需要 root。Linux 没有统一的“系统代理”接口，因此会同时检查代理环境变量、可用时的 GNOME 代理设置、本地监听端口、相关进程和常见 Antigravity 路径，并刻意不打印完整进程命令行。

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

## What it does / 工作原理

**EN:** Launch Google Antigravity with a **process-local proxy** so Antigravity and its child processes can use a local HTTP/SOCKS proxy **without enabling TUN mode or changing global proxy settings**.

**中文：**通过**进程级代理**启动 Google Antigravity，让 Antigravity 及其子进程使用本地 HTTP/SOCKS 代理，同时**无需开启 TUN，也不修改系统全局代理配置**。

The launcher / 启动器会：

1. Find Antigravity automatically / 自动寻找 Antigravity；
2. Refuse to attach to an already-running Antigravity process / 阻止连接到已经运行、无法事后继承代理环境的旧进程；
3. Choose a proxy in this order / 按以下顺序选择代理：
   - `AG_HTTP_PROXY` / `AG_SOCKS_PROXY` / `AG_PROXY_PORT`;
   - existing proxy environment variables / 当前 shell 已有代理环境变量；
   - current Windows/macOS user proxy / Windows/macOS 当前用户系统代理；
   - common localhost ports / 常见 localhost 端口兜底；
4. Inject `HTTP_PROXY`, `HTTPS_PROXY`, `ALL_PROXY` and lowercase variants only into the Antigravity process tree / 只向 Antigravity 进程树注入这些变量；
5. Start Antigravity so its backend/child processes inherit them / 启动 Antigravity，其后台子进程自动继承。

It does not / 它不会：

- enable TUN / 开启 TUN；
- change global system proxy settings / 修改全局系统代理；
- install a virtual adapter or Network Extension / 安装虚拟网卡或 Network Extension；
- disable TLS certificate verification / 关闭 TLS 证书校验；
- disable Gatekeeper, SIP, Windows Defender, etc. / 关闭 Gatekeeper、SIP、Windows Defender 等安全机制；
- require Administrator/root privileges / 要求管理员或 root 权限。

## Supported systems / 支持平台

| OS / 系统 | Launcher / 启动文件 | Notes / 说明 |
|---|---|---|
| Windows 10/11 | `antigravity-proxy-windows.cmd` | Uses the bundled PowerShell helper / 配合同目录 PowerShell 脚本 |
| macOS | `antigravity-proxy-macos.command` | Reads macOS proxy + probes local ports / 读取系统代理并探测本地端口 |
| Linux | `antigravity-proxy-linux.sh` | Uses env/manual overrides/common local ports / 使用环境变量、手动覆盖或常见端口 |

The launcher is proxy-client agnostic / 脚本不绑定具体代理客户端。It can work with v2rayN, Clash/Mihomo-based clients, SakuraCat, sing-box/Xray frontends, and other clients exposing a local HTTP/SOCKS5/mixed proxy endpoint / 只要客户端暴露本地 HTTP、SOCKS5 或 mixed 代理端点即可。

## Quick start / 快速使用

### Windows

1. Start your proxy client / 启动代理客户端，不需要 TUN；
2. Quit Antigravity completely / 完全退出 Antigravity；
3. Put these two files in the same folder / 将以下两个文件放在同一目录：
   - `antigravity-proxy-windows.cmd`
   - `antigravity-proxy-windows.ps1`
4. Double-click `antigravity-proxy-windows.cmd` / 双击该 `.cmd`。

### macOS

```bash
git clone https://github.com/peroperoyui-lab/antigravity-proxy-launcher.git
cd antigravity-proxy-launcher
./antigravity-proxy-macos.command
```

If downloaded through a browser, see the macOS permission section above / 如果通过浏览器下载，请按上方 macOS 权限章节处理。

### Linux

```bash
chmod +x antigravity-proxy-linux.sh
./antigravity-proxy-linux.sh
```

## Automatic proxy detection / 自动识别代理

Fallback ports / 兜底探测端口：

- `10808` — common v2rayN/mixed / 常见 v2rayN mixed 端口
- `10809` — common older v2rayN HTTP / 旧配置常见 HTTP 端口
- `7890` — common Clash/Mihomo mixed / Clash/Mihomo 常见 mixed 端口
- `7897` — used by some Clash/Mihomo setups / 部分 Clash/Mihomo 配置
- `7891` — common SOCKS / 常见 SOCKS 端口

## Manual override / 手动指定

### One mixed port / 单一 mixed 端口

macOS/Linux:

```bash
AG_PROXY_PORT=12345 ./antigravity-proxy-macos.command
```

Windows CMD:

```bat
set AG_PROXY_PORT=12345
antigravity-proxy-windows.cmd
```

### Explicit HTTP and SOCKS endpoints / 分别指定 HTTP 与 SOCKS

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

### Custom Antigravity location / 自定义 Antigravity 路径

macOS:

```bash
AG_APP=/custom/path/Antigravity.app ./antigravity-proxy-macos.command
```

Linux:

```bash
AG_APP=/custom/path/antigravity ./antigravity-proxy-linux.sh
```

Windows:

```bat
set AG_APP=D:\Apps\Antigravity\Antigravity.exe
antigravity-proxy-windows.cmd
```

## Why quit Antigravity first? / 为什么必须先退出 Antigravity？

**EN:** Environment variables are inherited when a child process is created; they cannot be retroactively injected into an already-running Antigravity instance.

**中文：**环境变量是在创建子进程时继承的，无法事后注入已经运行的 Antigravity，因此必须先彻底退出旧实例。

## Security model / 安全说明

**EN:** All launchers are plain-text scripts. They intentionally avoid disabling TLS verification or OS security features. Review scripts downloaded from untrusted mirrors. Proxy credentials placed in environment variables may be visible to other processes running as the same user, so prefer a localhost proxy without embedded credentials when possible.

**中文：**所有启动器都是可直接审查的纯文本脚本，并明确避免关闭 TLS 校验或操作系统安全机制。从非可信镜像下载时请先检查源码。代理 URL 如果包含用户名/密码，部分系统上同一用户的其他进程可能看到相关环境变量，因此尽量使用不内嵌凭据的 localhost 本地代理。

## Troubleshooting / 常见问题

**No proxy detected / 提示找不到代理**  
Start the proxy client first, or set `AG_PROXY_PORT` / `AG_HTTP_PROXY` manually. / 先启动代理客户端，或手动设置 `AG_PROXY_PORT` / `AG_HTTP_PROXY`。

**Antigravity is already running / 提示 Antigravity 已经运行**  
Quit it completely, then relaunch through this tool. / 彻底退出后再通过本工具启动。

**SOCKS-only proxy still does not work / 只有 SOCKS 端口仍无法联网**  
Some Antigravity components may specifically honor `HTTP_PROXY` / `HTTPS_PROXY`; configure an HTTP or mixed local endpoint and point `AG_HTTP_PROXY` to it. / 部分组件可能只读取 `HTTP_PROXY` / `HTTPS_PROXY`，建议启用 HTTP 或 mixed 本地端口。

**macOS says the developer is unidentified / macOS 提示“身份不明的开发者”**  
Use Finder Right click → Open after reviewing the script, or remove quarantine from that script only. Do not disable Gatekeeper globally. / 检查源码后 Finder 右键打开，或仅移除该脚本自身的 quarantine 标记，不要全局关闭 Gatekeeper。

## License

MIT
