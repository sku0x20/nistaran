#!/usr/bin/env bash
set -euo pipefail

WAN_IF=enp1s0
DEST_IP=104.16.124.96
JOOL_PORT_RANGE=32768-65535
INSTANCE=nat64

SOURCE_V4="$(ip -4 -o addr show "$WAN_IF" | awk '{print $4}' | cut -d/ -f1 | head -1)"
V6_PREFIX="$(ip -6 route show dev "$WAN_IF" | awk '$1 ~ /\/64$/ {print $1; exit}')"
PREFIX64="${V6_PREFIX%::/64}"

IFS=. read -r O1 O2 O3 O4 <<<"$DEST_IP"
printf -v HEX1 '%02x%02x' "$O1" "$O2"
printf -v HEX2 '%02x%02x' "$O3" "$O4"

POOL6="${PREFIX64}::/96"
CLIENT_V6="${PREFIX64}::${HEX1}:${HEX2}"

modprobe jool

if ! jool instance display 2>/dev/null | grep -q "^$INSTANCE\b"; then
	jool instance add "$INSTANCE" --netfilter --pool6 "$POOL6"
fi

jool -i "$INSTANCE" pool4 flush
jool -i "$INSTANCE" pool4 add "$SOURCE_V4" --tcp --port-range "$JOOL_PORT_RANGE"
jool -i "$INSTANCE" pool4 add "$SOURCE_V4" --udp --port-range "$JOOL_PORT_RANGE"

# eamt isn't in this jool build's CLI (NAT64-only, no SIIT merge), so pool6
# embedding is generic across the whole /96 - close that with a filter
# instead: drop anything in POOL6 except CLIENT_V6, before Jool's own hook.
nft add table ip6 jool_guard
nft -- add chain ip6 jool_guard prerouting { type filter hook prerouting priority -300 \; }
nft flush chain ip6 jool_guard prerouting
nft add rule ip6 jool_guard prerouting ip6 daddr "$CLIENT_V6" accept
nft add rule ip6 jool_guard prerouting ip6 daddr "$POOL6" drop

echo "hand this address to clients: $CLIENT_V6"
