# DNS Generation Scripts

## Introduction

The respective shell scripts contained within this directory can be utilised to generate application specific compliant
configuration which can be utilised with:

* Dnsmasq
* Unbound
* AdGuard Home

## Usage

1. Copy `config.example.json` to `config.json`.
2. Modify `config.json` to include your Cacheserver's IP(s) and the CDNs you plan to cache.
   The following example assumes a single shared Cacheserver IP:
```json
{
  "ips": {
    "generic":	["10.10.10.200"]
  },
  "cache_domains": {
    "blizzard":     "generic",
    "epicgames":    "generic",
    "nintendo":     "generic",
    "origin":       "generic",
    "riot":         "generic",
    "sony":         "generic",
    "steam":        "generic",
    "uplay":        "generic",
    "wsus":         "generic"
  }
}
```
3. Run generation script relative to your DNS implementation: `bash create-dnsmasq.sh`.
4. Copy files from `output/{dnsmasq,unbound}/*` to the respective locations for Dnsmasq/Unbound.
5. Restart Dnsmasq or Unbound.

### Notes for Dnsmasq users

**This also applies to users utilising the script alongside Pi-hole.**

Multi-IP Lancache setups are only supported with Dnsmasq or Pi-hole versions >= 2.86 or 2021.09 respectively.

### Notes for AdGuard Home users

1. In the `config.json`, you may want to add an entry for your non-cached DNS upstreams. You can input this in `ip.adguardhome_upstream` as an array.
2. Once you have ran the script, you can point the upstream list to the text file generated. For example: `upstream_dns_file: "/root/cache-domains/scripts/output/adguardhome/cache-domains.txt"`