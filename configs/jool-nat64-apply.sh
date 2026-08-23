#!/usr/bin/env bash
set -euo pipefail

WAN_IF=enp1s0
DEST_IP=104.16.124.96
JOOL_PORT_RANGE=60000-65535
INSTANCE=nat64

SOURCE_V4="$(ip -4 -o addr show "$WAN_IF" | awk '{print $4}' | cut -d/ -f1 | head -1)"
PUBLIC_V6="$(ip -6 -o addr show "$WAN_IF" scope global | awk '{print $4}' | cut -d/ -f1 | head -1)"

modprobe jool

if ! jool instance display 2>/dev/null | grep -q "^$INSTANCE\b"; then
	jool instance add "$INSTANCE" --netfilter
fi

# EAM instead of pool6 embedding: only PUBLIC_V6 ever translates, to DEST_IP
# only. No pool6 means anything else is untranslatable — no open relay to
# arbitrary destinations, unlike a generic NAT64 gateway.
jool -i "$INSTANCE" eamt flush
jool -i "$INSTANCE" eamt add "${PUBLIC_V6}/128" "${DEST_IP}/32"

jool -i "$INSTANCE" pool4 flush
jool -i "$INSTANCE" pool4 add "$SOURCE_V4" --tcp --port-range "$JOOL_PORT_RANGE"
jool -i "$INSTANCE" pool4 add "$SOURCE_V4" --udp --port-range "$JOOL_PORT_RANGE"

echo "hand this address to clients: $PUBLIC_V6"
