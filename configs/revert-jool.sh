#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
	echo "must run as root" >&2
	exit 1
fi

systemctl disable --now jool-nat64.service 2>/dev/null || true
rm -f /etc/systemd/system/jool-nat64.service
systemctl daemon-reload

rm -f /usr/local/sbin/apply-jool.sh

jool instance remove nat64 2>/dev/null || true
modprobe -r jool 2>/dev/null || true
rm -f /etc/modules-load.d/jool.conf

nft delete table ip6 jool_shim 2>/dev/null || true
rm -f /etc/nftables-jool.conf

rm -f /etc/sysctl.d/99-jool-nat64.conf
sysctl -w net.ipv6.conf.all.forwarding=0
