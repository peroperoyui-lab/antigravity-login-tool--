#!/bin/bash

set -u

# Antigravity Proxy Launcher for macOS
# Injects proxy variables only into Antigravity and its child processes.
# It does not modify global macOS proxy settings and does not require TUN.

KNOWN_PORTS=(10808 10809 7890 7897 7891)
PROXY_HOST="127.0.0.1"

log()  { printf '%s\n' "$*"; }
fail() { log "[ERROR] $*"; read -r -p "Press Enter to close..." _; exit 1; }

port_open() {
  /usr/bin/nc -z "$PROXY_HOST" "$1" >/dev/null 2>&1
}

http_proxy_works() {
  /usr/bin/curl -fsS --proxy "http://${PROXY_HOST}:$1" \
    --connect-timeout 2 --max-time 4 -o /dev/null \
    "https://www.gstatic.com/generate_204" >/dev/null 2>&1
}

find_antigravity() {
  if [[ -n "${AG_APP:-}" ]]; then
    if [[ -x "$AG_APP" ]]; then printf '%s\n' "$AG_APP"; return 0; fi
    if [[ -x "$AG_APP/Contents/MacOS/Antigravity" ]]; then
      printf '%s\n' "$AG_APP/Contents/MacOS/Antigravity"; return 0
    fi
    return 1
  fi

  local app
  for app in \
    "/Applications/Antigravity.app" \
    "$HOME/Applications/Antigravity.app" \
    "/Volumes/Antigravity/Antigravity.app"
  do
    if [[ -x "$app/Contents/MacOS/Antigravity" ]]; then
      printf '%s\n' "$app/Contents/MacOS/Antigravity"
      return 0
    fi
  done

  if command -v mdfind >/dev/null 2>&1; then
    app="$(mdfind 'kMDItemFSName == "Antigravity.app"' 2>/dev/null | head -n 1)"
    if [[ -n "$app" && -x "$app/Contents/MacOS/Antigravity" ]]; then
      printf '%s\n' "$app/Contents/MacOS/Antigravity"
      return 0
    fi
  fi
  return 1
}

read_scutil_value() {
  local key="$1"
  printf '%s\n' "$SCUTIL_PROXY" | /usr/bin/awk -v k="$key" '$1 == k && $2 == ":" {print $3; exit}'
}

AG_EXE="$(find_antigravity)" || fail "Antigravity was not found. Install it in /Applications, ~/Applications, or set AG_APP."

if /usr/bin/pgrep -x "Antigravity" >/dev/null 2>&1; then
  fail "Antigravity is already running. Quit it completely with Command-Q and run this launcher again."
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
  SCUTIL_PROXY="$(/usr/sbin/scutil --proxy 2>/dev/null || true)"

  HTTP_ENABLE="$(read_scutil_value HTTPEnable)"
  HTTP_HOST="$(read_scutil_value HTTPProxy)"
  HTTP_PORT="$(read_scutil_value HTTPPort)"
  HTTPS_ENABLE="$(read_scutil_value HTTPSEnable)"
  HTTPS_HOST="$(read_scutil_value HTTPSProxy)"
  HTTPS_PORT="$(read_scutil_value HTTPSPort)"
  SOCKS_ENABLE="$(read_scutil_value SOCKSEnable)"
  SOCKS_HOST="$(read_scutil_value SOCKSProxy)"
  SOCKS_PORT="$(read_scutil_value SOCKSPort)"

  if [[ "$HTTPS_ENABLE" == "1" && ( "$HTTPS_HOST" == "127.0.0.1" || "$HTTPS_HOST" == "localhost" ) && -n "$HTTPS_PORT" ]] && port_open "$HTTPS_PORT"; then
    HTTP_URL="http://${HTTPS_HOST}:${HTTPS_PORT}"
    SOURCE="macOS system HTTPS proxy"
  elif [[ "$HTTP_ENABLE" == "1" && ( "$HTTP_HOST" == "127.0.0.1" || "$HTTP_HOST" == "localhost" ) && -n "$HTTP_PORT" ]] && port_open "$HTTP_PORT"; then
    HTTP_URL="http://${HTTP_HOST}:${HTTP_PORT}"
    SOURCE="macOS system HTTP proxy"
  fi

  if [[ "$SOCKS_ENABLE" == "1" && ( "$SOCKS_HOST" == "127.0.0.1" || "$SOCKS_HOST" == "localhost" ) && -n "$SOCKS_PORT" ]] && port_open "$SOCKS_PORT"; then
    SOCKS_URL="socks5://${SOCKS_HOST}:${SOCKS_PORT}"
    [[ "$SOURCE" == "environment/manual override" ]] && SOURCE="macOS system SOCKS proxy"
  fi
fi

if [[ -z "$HTTP_URL" && -z "$SOCKS_URL" ]]; then
  OPEN_PORTS=()
  for p in "${KNOWN_PORTS[@]}"; do
    port_open "$p" && OPEN_PORTS+=("$p")
  done

  (( ${#OPEN_PORTS[@]} > 0 )) || fail "No local proxy detected. Start your proxy client or set AG_HTTP_PROXY / AG_PROXY_PORT."

  SELECTED=""
  for p in "${OPEN_PORTS[@]}"; do
    if http_proxy_works "$p"; then SELECTED="$p"; break; fi
  done
  [[ -n "$SELECTED" ]] || SELECTED="${OPEN_PORTS[0]}"

  HTTP_URL="http://${PROXY_HOST}:${SELECTED}"
  SOCKS_URL="socks5://${PROXY_HOST}:${SELECTED}"
  SOURCE="common local proxy port ${SELECTED}"
fi

if [[ -n "$HTTP_URL" ]]; then
  export HTTP_PROXY="$HTTP_URL" HTTPS_PROXY="$HTTP_URL"
  export http_proxy="$HTTP_URL" https_proxy="$HTTP_URL"
fi

if [[ -n "$SOCKS_URL" ]]; then
  export ALL_PROXY="$SOCKS_URL" all_proxy="$SOCKS_URL"
fi

export NO_PROXY="${NO_PROXY:-localhost,127.0.0.1,::1}"
export no_proxy="$NO_PROXY"

log "============================================================"
log " Antigravity Proxy Launcher"
log "============================================================"
log "[OK] Antigravity: $AG_EXE"
log "[OK] Proxy source: $SOURCE"
[[ -n "$HTTP_URL" ]] && log "[OK] HTTP/HTTPS: $HTTP_URL"
[[ -n "$SOCKS_URL" ]] && log "[OK] SOCKS/ALL:  $SOCKS_URL"
log "[OK] Global macOS proxy settings will not be changed."
log ""

"$AG_EXE" >/tmp/antigravity-proxy-launcher.log 2>&1 &
PID=$!
sleep 1

if /bin/kill -0 "$PID" >/dev/null 2>&1; then
  log "[OK] Antigravity started with PID $PID."
  log "[OK] Child processes inherit the same proxy environment."
  exit 0
fi

fail "Antigravity exited immediately. See /tmp/antigravity-proxy-launcher.log"
