#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
	echo "must run as root" >&2
	exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

apt-get update
apt-get install -y nftables conntrack

install -m 644 "$SCRIPT_DIR/nftables.conf" /etc/nftables.conf

cat > /etc/sysctl.d/99-nat.conf <<'EOF'
net.ipv4.ip_forward=1
net.ipv4.ip_local_port_range=1024 32767
# fill in on the server, don't commit real prod ports
# net.ipv4.ip_local_reserved_ports=,
EOF
sysctl -p /etc/sysctl.d/99-nat.conf

nft -f /etc/nftables.conf
systemctl enable --now nftables
