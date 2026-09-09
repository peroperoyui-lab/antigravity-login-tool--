# Antigravity Proxy Launcher

一个给 Google Antigravity 使用的**进程级代理启动器**：让 Antigravity 及其子进程继承本地 HTTP/SOCKS 代理，同时**无需开启 TUN，也不修改系统全局代理配置**。

适用于这类情况：浏览器通过系统代理可以正常联网，但 Antigravity 或其后台进程仍然无法稳定访问网络。

[English README](README.md)

## 工作原理

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
