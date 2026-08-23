#!/usr/bin/env bash
set -euo pipefail

WAN_IF=enp1s0
DEST_IP=34.160.111.145
JOOL_PORT_RANGE=32768-65535
INSTANCE=nat64

SOURCE_V4="$(ip -4 -o addr show "$WAN_IF" | awk '{print $4}' | cut -d/ -f1 | head -1)"
PUBLIC_V6="$(ip -6 -o addr show dev "$WAN_IF" scope global | awk '{print $4}' | cut -d/ -f1 | head -1)"
V6_PREFIX="$(ip -6 route show dev "$WAN_IF" | awk '$1 ~ /\/64$/ {print $1; exit}')"
PREFIX64="${V6_PREFIX%::/64}"

IFS=. read -r O1 O2 O3 O4 <<<"$DEST_IP"
printf -v HEX1 '%02x%02x' "$O1" "$O2"
printf -v HEX2 '%02x%02x' "$O3" "$O4"

POOL6="${PREFIX64}::/96"
CLIENT_V6="${PREFIX64}::${HEX1}:${HEX2}"  # embeds DEST_IP - never hand out, Jool-facing only

# runs before jool loads, so pool6 is never reachable unshielded
cat > /etc/nftables-jool.conf <<EOF
#!/usr/sbin/nft -f

table ip6 jool_shim
delete table ip6 jool_shim

table ip6 jool_shim {
	# jool hooks at NF_IP6_PRI_NAT_DST+25 = -75 (src/mod/common/xlator.c,
	# NICMx/Jool), so both chains below must run before that
	chain guard {
		type filter hook prerouting priority -400; policy accept;
		iifname $WAN_IF ip6 daddr $POOL6 drop
	}

	# plain field rewrites, not nat: nat is conntrack-based, and jool's
	# dst_output()-injected replies bypass conntrack, so snat never fired on them
	chain fwd_rewrite {
		type filter hook prerouting priority -150; policy accept;
		iifname $WAN_IF ip6 daddr $PUBLIC_V6 tcp dport 443 ip6 daddr set $CLIENT_V6
		iifname $WAN_IF ip6 daddr $PUBLIC_V6 udp dport 443 ip6 daddr set $CLIENT_V6
	}

	chain rev_rewrite {
		type filter hook postrouting priority srcnat; policy accept;
		oifname $WAN_IF ip6 saddr $CLIENT_V6 ip6 saddr set $PUBLIC_V6
	}
}
EOF
nft -f /etc/nftables-jool.conf

modprobe jool

if ! jool instance display 2>/dev/null | grep -q "^$INSTANCE\b"; then
	jool instance add "$INSTANCE" --netfilter --pool6 "$POOL6"
fi

jool -i "$INSTANCE" pool4 flush
jool -i "$INSTANCE" pool4 add --tcp "$SOURCE_V4" "$JOOL_PORT_RANGE"
jool -i "$INSTANCE" pool4 add --udp "$SOURCE_V4" "$JOOL_PORT_RANGE"

echo "hand this address to clients: $PUBLIC_V6"
