# nistaran

A single Vultr VM acting as a fixed-destination relay: IPv4 clients get DNAT+masquerade via `nftables`, IPv6 clients get NAT64 via Jool. Both paths forward only TCP/UDP 443 to one hardcoded `DEST_IP` — not a general-purpose proxy or open NAT64 relay.

## Layout

- `vultr/` — OpenTofu (`tofu`) config provisioning the instance.
- `configs/` — provisioning + runtime scripts, see below.
- `configs/PORTS.md` — why the port ranges are split the way they are, and what breaks if they're not.

## Usage

On the server, as root:

```
./configs/setup-nft.sh    # v4 DNAT/masquerade - must run before setup-jool.sh
./configs/setup-jool.sh   # v6 NAT64 via Jool, installs + starts jool-nat64.service
```

`apply-jool.sh` reapplies on every boot via the systemd unit; it's not meant to be edited-and-run standalone without `setup-jool.sh` having installed it.

To tear down:

```
./configs/revert-nft.sh
./configs/revert-jool.sh
```
