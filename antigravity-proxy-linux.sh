#!/usr/bin/env bash

set -u

# Antigravity Proxy Launcher for Linux
# Process-local proxy injection; no global network settings are changed.

KNOWN_PORTS=(10808 10809 7890 7897 7891)
PROXY_HOST="127.0.0.1"

log()  { printf '%s\n' "$*"; }
fail() { log "[ERROR] $*" >&2; exit 1; }
port_open() { (echo >/dev/tcp/${PROXY_HOST}/$1) >/dev/null 2>&1; }

find_antigravity() {
  if [[ -n "${AG_APP:-}" && -x "$AG_APP" ]]; then printf '%s\n' "$AG_APP"; return 0; fi
  if command -v antigravity >/dev/null 2>&1; then command -v antigravity; return 0; fi
  local p
  for p in /opt/Antigravity/antigravity /opt/antigravity/antigravity "$HOME/.local/bin/antigravity"; do
    [[ -x "$p" ]] && { printf '%s\n' "$p"; return 0; }
  done
  return 1
}

AG_EXE="$(find_antigravity)" || fail "Antigravity executable not found. Set AG_APP=/path/to/antigravity."

if pgrep -x antigravity >/dev/null 2>&1 || pgrep -x Antigravity >/dev/null 2>&1; then
  fail "Antigravity is already running. Quit it completely and run this launcher again."
fi

HTTP_URL="${AG_HTTP_PROXY:-${AG_PROXY_URL:-${HTTPS_PROXY:-${https_proxy:-${HTTP_PROXY:-${http_proxy:-}}}}}}}"
SOCKS_URL="${AG_SOCKS_PROXY:-${ALL_PROXY:-${all_proxy:-}}}"
SOURCE="environment/manual override"

if [[ -n "${AG_PROXY_PORT:-}" ]]; then
  port_open "$AG_PROXY_PORT" || fail "AG_PROXY_PORT=${AG_PROXY_PORT}, but ${PROXY_HOST}:${AG_PROXY_PORT} is not listening."
  HTTP_URL="http://${PROXY_HOST}:${AG_PROXY_PORT}"
  SOCKS_URL="socks5://${PROXY_HOST}:${AG_PROXY_PORT}"
  SOURCE="AG_PROXY_PORT"
fi

if [[ -z "$HTTP_URL" && -z "$SOCKS_URL" ]]; then
  for p in "${KNOWN_PORTS[@]}"; do
    if port_open "$p"; then
      HTTP_URL="http://${PROXY_HOST}:${p}"
      SOCKS_URL="socks5://${PROXY_HOST}:${p}"
      SOURCE="common local proxy port ${p}"
      break
    fi
  done
fi

[[ -n "$HTTP_URL" || -n "$SOCKS_URL" ]] || fail "No local proxy detected. Start your proxy client or set AG_HTTP_PROXY / AG_PROXY_PORT."

if [[ -n "$HTTP_URL" ]]; then
  export HTTP_PROXY="$HTTP_URL" HTTPS_PROXY="$HTTP_URL"
  export http_proxy="$HTTP_URL" https_proxy="$HTTP_URL"
fi
if [[ -n "$SOCKS_URL" ]]; then
  export ALL_PROXY="$SOCKS_URL" all_proxy="$SOCKS_URL"
fi
export NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,::1}"
export no_proxy="$NO_PROXY"

log "[OK] Antigravity: $AG_EXE"
log "[OK] Proxy source: $SOURCE"
[[ -n "$HTTP_URL" ]] && log "[OK] HTTP/HTTPS: $HTTP_URL"
[[ -n "$SOCKS_URL" ]] && log "[OK] SOCKS/ALL:  $SOCKS_URL"

exec "$AG_EXE"
