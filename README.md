# Antigravity Proxy Launcher

Launch Google Antigravity with a **process-local proxy** so Antigravity and its child processes can use a local HTTP/SOCKS proxy **without enabling TUN mode or changing global proxy settings**.

This is useful on machines where browsers work through the OS proxy, but Antigravity or one of its backend processes still cannot reach the network reliably.

[中文说明](README.zh-CN.md)

## What it does

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
