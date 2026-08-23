# Port ranges

Three independent consumers share this box's v4 identity. Each gets a disjoint band so their port allocators never fight over the same number.

| Range | Owner | Sysctl / config |
|---|---|---|
| `1-1023` | Listening services (ssh, etc.) | untouched |
| `1024-32767` | Host outbound **and** nftables `masquerade` | `net.ipv4.ip_local_port_range=1024 32767` (`setup-nft.sh`) |
| `32768-65535` | Jool's `pool4` (NAT64 NAPT) | `jool pool4 add --tcp/--udp <addr> 32768-65535` (`apply-jool.sh`) |

To exclude specific prod ports from the `1024-32767` band without committing them: `net.ipv4.ip_local_reserved_ports=` in `/etc/sysctl.d/99-nat.conf` (fill in on the server, not in git).

**Run order matters:** `setup-nft.sh` must run before `setup-jool.sh` (which starts `jool-nat64.service` immediately). Until `ip_local_port_range` is narrowed to `1024-32767`, the host's own ephemeral ports overlap `pool4` and local v4 connections break the moment Jool is active — see below.

## Why host outbound and masquerade can share a range

Port uniqueness in Linux is per **4-tuple** (local addr, local port, remote addr, remote port), not per local port alone — the same reason one ephemeral port already serves many simultaneous connections to different destinations. Masquerade's port allocator checks conntrack for exact-tuple collisions the same way the kernel's own ephemeral-port picker does. They coexist safely as long as nothing statically `bind()`s inside the shared range — which is exactly why listening services are kept out of it (`1-1023` only).

## Why Jool's pool4 can NOT share that range

A Jool `--netfilter` instance registers **two** kernel hooks, not one — for both `PF_INET6` and `PF_INET`, both on `NF_INET_PRE_ROUTING`:

```c
// src/mod/common/xlator.c, NICMx/Jool
static struct nf_hook_ops netfilter_hooks[] = {
	{ .hook = hook_ipv6, .pf = PF_INET6, .hooknum = NF_INET_PRE_ROUTING, .priority = NF_IP6_PRI_NAT_DST + 25 },
	{ .hook = hook_ipv4, .pf = PF_INET,  .hooknum = NF_INET_PRE_ROUTING, .priority = NF_IP_PRI_NAT_DST + 25 },
};
```

`NF_IP_PRI_NAT_DST` is `-100`, so the v4 hook runs at priority `-75` — ahead of ordinary input processing, on **every** incoming v4 packet, unconditionally. It exists to catch NAT64 return traffic (replies to `pool4`-assigned ports) and translate them back to v6.

This hook doesn't consult the kernel's socket/bind table — it only checks its own BIB/session table. If the host's own ephemeral ports overlap `pool4`, a reply to a genuinely local connection (e.g. `curl -4`) gets intercepted by this hook first, doesn't match any NAT64 session, and never reaches the local socket. Symptom: local outbound v4 connections hang/fail as soon as Jool is active, with nothing in the nftables ruleset to blame.

## References

- Jool hook registration: [`src/mod/common/xlator.c`](https://github.com/NICMx/Jool/blob/main/src/mod/common/xlator.c)
- `jool pool4 add` syntax: [jool.mx/en/usr-flags-pool4.html](https://www.jool.mx/en/usr-flags-pool4.html)
- nftables `nat`-type chains require priority `> -200` (kernel-enforced; unrelated to hook ordering)
- nftables `dnat`/`snat` are conntrack-based; a packet with no conntrack entry (e.g. Jool's own `dst_output()`-injected replies) won't get translated by them — use stateless `<field> set <value>` in a `filter`-type chain instead when the packet may be untracked
