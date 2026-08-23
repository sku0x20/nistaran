#!/usr/bin/env bash
set -euo pipefail

WAN_IF=enp1s0
DEST_IP=104.16.124.96
JOOL_PORT_RANGE=32768-65535
INSTANCE=nat64
# Required by the kernel module even when using EAM, this is RFC 6052 well-known prefix, unreachable.
POOL6=64:ff9b::/96

SOURCE_V4="$(ip -4 -o addr show "$WAN_IF" | awk '{print $4}' | cut -d/ -f1 | head -1)"
PUBLIC_V6="$(ip -6 -o addr show "$WAN_IF" scope global | awk '{print $4}' | cut -d/ -f1 | head -1)"

modprobe jool

if ! jool instance display 2>/dev/null | grep -q "^$INSTANCE\b"; then
	jool instance add "$INSTANCE" --netfilter --pool6 "$POOL6"
fi

# EAM: fixed 1:1 mapping, takes priority over pool6 embedding for this address.
jool -i "$INSTANCE" eamt flush
jool -i "$INSTANCE" eamt add "${PUBLIC_V6}/128" "${DEST_IP}/32"

jool -i "$INSTANCE" pool4 flush
jool -i "$INSTANCE" pool4 add "$SOURCE_V4" --tcp --port-range "$JOOL_PORT_RANGE"
jool -i "$INSTANCE" pool4 add "$SOURCE_V4" --udp --port-range "$JOOL_PORT_RANGE"

echo "hand this address to clients: $PUBLIC_V6"
