#!/usr/bin/env bash
set -euo pipefail

WAN_IF=enp1s0
DEST_IP=104.16.124.96
JOOL_PORT_RANGE=60000-65535
INSTANCE=nat64

WAN_IP="$(ip -4 -o addr show "$WAN_IF" | awk '{print $4}' | cut -d/ -f1 | head -1)"

# The /64 Vultr routes to this instance (not just its single auto-assigned address) —
# any address inside it reaches this box, so we mint one ourselves below.
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
jool -i "$INSTANCE" pool4 add "$WAN_IP" --tcp --port-range "$JOOL_PORT_RANGE"
jool -i "$INSTANCE" pool4 add "$WAN_IP" --udp --port-range "$JOOL_PORT_RANGE"

echo "hand this address to clients: $CLIENT_V6"
