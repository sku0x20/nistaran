#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
	echo "must run as root" >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

apt-get update
apt-get install -y "linux-headers-$(uname -r)" jool-dkms jool-tools

echo jool > /etc/modules-load.d/jool.conf

# Jool's NAT64 NAPT allocator doesn't know about the kernel's local port
# allocator or nftables' masquerade state, so it needs its own disjoint band
# (32768-65535, set in jool-nat64-apply.sh) — shrink the kernel's ephemeral
# range to match so host connections and nftables' masquerade stay out of it.
cat > /etc/sysctl.d/99-jool-nat64.conf <<'EOF'
net.ipv6.conf.all.forwarding=1
net.ipv4.ip_local_port_range=1024 32767
# Exclude any ports already bound by other prod services in this box's
# 1024-32767 range, so the kernel/nftables never pick them for NAT. Fill in
# the actual ports on the server directly — don't commit them here.
# net.ipv4.ip_local_reserved_ports=
EOF
sysctl -p /etc/sysctl.d/99-jool-nat64.conf

install -m 755 "$SCRIPT_DIR/jool-nat64-apply.sh" /usr/local/sbin/jool-nat64-apply.sh

cat > /etc/systemd/system/jool-nat64.service <<'EOF'
[Unit]
Description=Jool stateful NAT64 (IPv6 -> IPv4)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/sbin/jool-nat64-apply.sh

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now jool-nat64.service
