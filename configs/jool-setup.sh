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

# Leaves 32768-65535 for Jool's own NAPT allocator (jool-nat64-apply.sh).
cat > /etc/sysctl.d/99-jool-nat64.conf <<'EOF'
net.ipv6.conf.all.forwarding=1
net.ipv4.ip_local_port_range=1024 32767
# fill in on the server, don't commit real prod ports
# net.ipv4.ip_local_reserved_ports=,
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
