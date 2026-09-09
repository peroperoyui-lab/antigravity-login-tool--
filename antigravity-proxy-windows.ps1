$ErrorActionPreference = 'Stop'

# Antigravity Proxy Launcher for Windows
# Injects proxy variables only into Antigravity and its child processes.
# It does not modify global Windows proxy settings and does not require TUN.

$KnownPorts = @(
    @{ Port = 10808; Kind = 'mixed' },
    @{ Port = 10809; Kind = 'http'  },
    @{ Port = 7890;  Kind = 'mixed' },
    @{ Port = 7897;  Kind = 'mixed' },
    @{ Port = 7891;  Kind = 'socks' }
)
$ProxyHost = '127.0.0.1'

function Fail([string]$Message, [int]$Code = 1) {
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Write-Host
    [void](Read-Host 'Press Enter to close')
    exit $Code
}

function Test-TcpPort([string]$HostName, [int]$Port) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect($HostName, $Port, $null, $null)
        if (-not $async.AsyncWaitHandle.WaitOne(600)) { return $false }
        $client.EndConnect($async)
        return $true
    }
    catch { return $false }
    finally { $client.Close() }
}

function Normalize-HttpProxy([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    if ($Value -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') { return $Value }
    return "http://$Value"
}

function Normalize-SocksProxy([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) { return $null }
    if ($Value -match '^[a-zA-Z][a-zA-Z0-9+.-]*://') { return $Value }
    return "socks5://$Value"
}

function Find-Antigravity {
    if ($env:AG_APP) {
        $manual = [Environment]::ExpandEnvironmentVariables($env:AG_APP)
        if (Test-Path -LiteralPath $manual -PathType Leaf) { return (Resolve-Path -LiteralPath $manual).Path }
        if (Test-Path -LiteralPath (Join-Path $manual 'Antigravity.exe') -PathType Leaf) {
            return (Resolve-Path -LiteralPath (Join-Path $manual 'Antigravity.exe')).Path
        }
        return $null
    }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Antigravity\Antigravity.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\antigravity\Antigravity.exe'),
        (Join-Path $env:ProgramFiles 'Antigravity\Antigravity.exe')
    )

    if (${env:ProgramFiles(x86)}) {
        $candidates += (Join-Path ${env:ProgramFiles(x86)} 'Antigravity\Antigravity.exe')
    }

    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    $programsDir = Join-Path $env:LOCALAPPDATA 'Programs'
    if (Test-Path -LiteralPath $programsDir) {
        $match = Get-ChildItem -LiteralPath $programsDir -Filter 'Antigravity.exe' -File -Recurse -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($match) { return $match.FullName }
    }
    return $null
}

function Get-WinInetProxy {
    try {
        $key = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
        if ($key.ProxyEnable -ne 1 -or [string]::IsNullOrWhiteSpace([string]$key.ProxyServer)) {
            return @{ Http = $null; Socks = $null }
        }

        $raw = [string]$key.ProxyServer
        if ($raw -notmatch '=') {
            return @{ Http = (Normalize-HttpProxy $raw); Socks = $null }
        }

        $parts = @{}
        foreach ($item in ($raw -split ';')) {
            if ($item -match '^\s*([^=]+)=(.+)$') {
                $parts[$matches[1].Trim().ToLowerInvariant()] = $matches[2].Trim()
            }
        }

        $httpValue = $null
        if ($parts.ContainsKey('https')) { $httpValue = $parts['https'] }
        elseif ($parts.ContainsKey('http')) { $httpValue = $parts['http'] }

        $socksValue = $null
        if ($parts.ContainsKey('socks')) { $socksValue = $parts['socks'] }

        return @{
            Http  = (Normalize-HttpProxy $httpValue)
            Socks = (Normalize-SocksProxy $socksValue)
        }
    }
    catch {
        return @{ Http = $null; Socks = $null }
    }
}

$AntigravityExe = Find-Antigravity
if (-not $AntigravityExe) {
    Fail 'Antigravity.exe was not found. Install it in a common location or set AG_APP to the executable path.' 1
}

if (Get-Process -Name 'Antigravity' -ErrorAction SilentlyContinue) {
    Fail 'Antigravity is already running. Quit it completely and run this launcher again.' 2
}

$HttpProxy = $null
$SocksProxy = $null
$Source = $null

if ($env:AG_PROXY_PORT) {
    $port = 0
    if (-not [int]::TryParse($env:AG_PROXY_PORT, [ref]$port) -or $port -lt 1 -or $port -gt 65535) {
        Fail "AG_PROXY_PORT='$($env:AG_PROXY_PORT)' is not a valid TCP port." 3
    }
    if (-not (Test-TcpPort $ProxyHost $port)) {
        Fail "AG_PROXY_PORT=$port, but ${ProxyHost}:$port is not listening." 3
    }
    $HttpProxy = "http://${ProxyHost}:$port"
    $SocksProxy = "socks5://${ProxyHost}:$port"
    $Source = 'AG_PROXY_PORT'
}
else {
    $HttpProxy = Normalize-HttpProxy $(if ($env:AG_HTTP_PROXY) { $env:AG_HTTP_PROXY } elseif ($env:AG_PROXY_URL) { $env:AG_PROXY_URL } elseif ($env:HTTPS_PROXY) { $env:HTTPS_PROXY } elseif ($env:https_proxy) { $env:https_proxy } elseif ($env:HTTP_PROXY) { $env:HTTP_PROXY } else { $env:http_proxy })
    $SocksProxy = Normalize-SocksProxy $(if ($env:AG_SOCKS_PROXY) { $env:AG_SOCKS_PROXY } elseif ($env:ALL_PROXY) { $env:ALL_PROXY } else { $env:all_proxy })
    if ($HttpProxy -or $SocksProxy) { $Source = 'environment/manual override' }
}

if (-not $HttpProxy -and -not $SocksProxy) {
    $systemProxy = Get-WinInetProxy
    if ($systemProxy.Http -or $systemProxy.Socks) {
        $HttpProxy = $systemProxy.Http
        $SocksProxy = $systemProxy.Socks
        $Source = 'Windows user system proxy'
    }
}

if (-not $HttpProxy -and -not $SocksProxy) {
    foreach ($candidate in $KnownPorts) {
        if (Test-TcpPort $ProxyHost $candidate.Port) {
            switch ($candidate.Kind) {
                'http' {
                    $HttpProxy = "http://${ProxyHost}:$($candidate.Port)"
                }
                'socks' {
                    $SocksProxy = "socks5://${ProxyHost}:$($candidate.Port)"
                }
                default {
                    $HttpProxy = "http://${ProxyHost}:$($candidate.Port)"
                    $SocksProxy = "socks5://${ProxyHost}:$($candidate.Port)"
                }
            }
            $Source = "common local proxy port $($candidate.Port)"
            break
        }
    }
}

if (-not $HttpProxy -and -not $SocksProxy) {
    Fail 'No local proxy was detected. Start your proxy client or set AG_HTTP_PROXY / AG_PROXY_PORT.' 4
}

if ($HttpProxy) {
    $env:HTTP_PROXY = $HttpProxy
    $env:HTTPS_PROXY = $HttpProxy
    $env:http_proxy = $HttpProxy
    $env:https_proxy = $HttpProxy
}
if ($SocksProxy) {
    $env:ALL_PROXY = $SocksProxy
    $env:all_proxy = $SocksProxy
}
if (-not $env:NO_PROXY) { $env:NO_PROXY = 'localhost,127.0.0.1,::1' }
$env:no_proxy = $env:NO_PROXY

Write-Host '============================================================'
Write-Host ' Antigravity Proxy Launcher'
Write-Host '============================================================'
Write-Host "[OK] Antigravity: $AntigravityExe"
Write-Host "[OK] Proxy source: $Source"
if ($HttpProxy)  { Write-Host "[OK] HTTP/HTTPS: $HttpProxy" }
if ($SocksProxy) { Write-Host "[OK] SOCKS/ALL:  $SocksProxy" }
Write-Host '[OK] Global Windows proxy settings will not be changed.'
Write-Host

try {
    $process = Start-Process -FilePath $AntigravityExe -WorkingDirectory (Split-Path -Parent $AntigravityExe) -PassThru
    Start-Sleep -Milliseconds 800
    if ($process.HasExited) {
        Fail "Antigravity exited immediately with code $($process.ExitCode)." 5
    }
    Write-Host "[OK] Antigravity started with PID $($process.Id)."
    Write-Host '[OK] Child processes inherit the same proxy environment.'
}
catch {
    Fail "Failed to launch Antigravity: $($_.Exception.Message)" 5
}
