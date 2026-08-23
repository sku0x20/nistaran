#!/usr/bin/env bash
set -euo pipefail

WAN_IF=enp1s0
POOL6=64:ff9b::/96
JOOL_PORT_RANGE=60000-65535
INSTANCE=nat64

WAN_IP="$(ip -4 -o addr show "$WAN_IF" | awk '{print $4}' | cut -d/ -f1 | head -1)"

modprobe jool

if ! jool instance display 2>/dev/null | grep -q "^$INSTANCE\b"; then
	jool instance add "$INSTANCE" --netfilter --pool6 "$POOL6"
fi

jool -i "$INSTANCE" pool4 flush
jool -i "$INSTANCE" pool4 add "$WAN_IP" --tcp --port-range "$JOOL_PORT_RANGE"
jool -i "$INSTANCE" pool4 add "$WAN_IP" --udp --port-range "$JOOL_PORT_RANGE"
