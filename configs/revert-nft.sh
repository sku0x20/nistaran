#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
	echo "must run as root" >&2
	exit 1
fi

systemctl disable --now nftables 2>/dev/null || true

nft delete table ip nat 2>/dev/null || true

rm -f /etc/nftables.conf
rm -f /etc/sysctl.d/99-nat.conf

sysctl -w net.ipv4.ip_forward=0
sysctl -w net.ipv4.ip_local_port_range="32768 60999"
