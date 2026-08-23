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
CLIENT_V6="${PREFIX64}::${HEX1}:${HEX2}"  # Jool-facing only, embeds DEST_IP - never hand out
VANITY_V6="${PREFIX64}::1"                # hand this to clients instead, embeds nothing

# Runs before jool loads: only VANITY_V6 survives, gets dnat'd to the real
# pool6 address Jool expects. Keeps DEST_IP from being derivable off the
# address we publish, and keeps the rest of pool6 unreachable from outside.
cat > /etc/nftables-jool.conf <<EOF
#!/usr/sbin/nft -f

table ip6 jool_shim
delete table ip6 jool_shim

table ip6 jool_shim {
	chain guard {
		type filter hook prerouting priority -400; policy accept;
		iifname $WAN_IF ip6 daddr $POOL6 ip6 daddr != $VANITY_V6 drop
	}

	chain dnat {
		type nat hook prerouting priority -350; policy accept;
		iifname $WAN_IF ip6 daddr $VANITY_V6 dnat to $CLIENT_V6
	}

	chain snat {
		type nat hook postrouting priority srcnat; policy accept;
		oifname $WAN_IF ip6 saddr $CLIENT_V6 snat to $VANITY_V6
	}
}
EOF
nft -f /etc/nftables-jool.conf

modprobe jool

if ! jool instance display 2>/dev/null | grep -q "^$INSTANCE\b"; then
	jool instance add "$INSTANCE" --netfilter --pool6 "$POOL6"
fi

jool -i "$INSTANCE" pool4 flush
jool -i "$INSTANCE" pool4 add "$SOURCE_V4" --tcp --port-range "$JOOL_PORT_RANGE"
jool -i "$INSTANCE" pool4 add "$SOURCE_V4" --udp --port-range "$JOOL_PORT_RANGE"

echo "hand this address to clients: $VANITY_V6"
