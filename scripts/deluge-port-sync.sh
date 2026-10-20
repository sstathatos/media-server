#!/bin/sh
# Keeps Deluge's listening port in sync with the port PIA forwards to Gluetun.
#
# PIA hands out a new forwarded port on every reconnect, so a fixed port in
# Deluge goes stale and incoming peer connections stop arriving. This runs in
# the VPN container's network namespace, so both Gluetun's control server and
# Deluge's web UI are reachable on localhost.
set -u

GLUETUN_URL="http://127.0.0.1:8000/v1/portforward"
DELUGE_URL="http://127.0.0.1:8112/json"
COOKIE=/tmp/deluge-cookie
PASSWORD="${DELUGE_PASSWORD:-deluge}"
INTERVAL="${INTERVAL:-60}"
last=""

log() { echo "$(date '+%Y-%m-%dT%H:%M:%S') $*"; }

# Prints the response body; fails on a transport error or a JSON-RPC error,
# which deluge-web returns with HTTP 200 and so curl alone would not catch.
rpc() {
  resp=$(curl -fsS --max-time 15 -b "$COOKIE" -c "$COOKIE" \
           -H 'Content-Type: application/json' -d "$1" "$DELUGE_URL" 2>/dev/null) || return 1
  echo "$resp"
  case "$resp" in *'"error": null'*) return 0 ;; *) return 1 ;; esac
}

# deluge-web only proxies core.* calls once the UI is attached to the daemon.
deluge_connect() {
  rpc "{\"method\":\"auth.login\",\"params\":[\"$PASSWORD\"],\"id\":1}" >/dev/null ||
    { log "auth failed - check DELUGE_PASSWORD"; return 1; }
  rpc '{"method":"web.connected","params":[],"id":2}' | grep -q '"result": true' && return 0
  host=$(rpc '{"method":"web.get_hosts","params":[],"id":3}' |
         sed -n 's/.*\[\[\"\([0-9a-f]*\)\".*/\1/p')
  [ -n "$host" ] || { log "no deluge daemon host found"; return 1; }
  rpc "{\"method\":\"web.connect\",\"params\":[\"$host\"],\"id\":4}" >/dev/null ||
    { log "could not attach to deluge daemon"; return 1; }
}

while :; do
  port=$(curl -fsSL --max-time 10 "$GLUETUN_URL" 2>/dev/null |
         sed -n 's/.*"port":[[:space:]]*\([0-9]*\).*/\1/p')

  if [ -n "${port:-}" ] && [ "$port" != "0" ] && [ "$port" != "$last" ] && deluge_connect; then
    if rpc "{\"method\":\"core.set_config\",\"params\":[{\"random_port\":false,\"listen_ports\":[$port,$port]}],\"id\":5}" >/dev/null &&
       rpc '{"method":"core.get_config_value","params":["listen_ports"],"id":6}' | grep -q "\[$port, $port\]"; then
      log "deluge listen port -> $port"
      last="$port"
    else
      log "failed to set listen port $port"
    fi
  fi

  sleep "$INTERVAL"
done
