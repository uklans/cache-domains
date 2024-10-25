# DNS Generation Scripts

## Introduction

The respective shell scripts contained within this directory can be utilised to generate application specific compliant
configuration which can be utilised with:

* AdGuard Home
* BIND9
* Dnsmasq/Pi-hole
* Squid
* Unbound

## Usage

1. Copy `config.example.json` to `config.json`.
2. Modify `config.json` to include your Cacheserver's IP(s) and the CDNs you plan to cache.

The following example assumes a single shared Cacheserver IP:
```json
{
    "combined_output": false,
    "ips": {
        "monolithic":   ["10.10.10.200"]
    },
    "cache_domains": {
        "blizzard":     "monolithic",
        "epicgames":    "monolithic",
        "nintendo":     "monolithic",
        "origin":       "monolithic",
        "riot":         "monolithic",
        "sony":         "monolithic",
        "steam":        "monolithic",
        "uplay":        "monolithic",
        "wsus":         "monolithic"
    }
}
```
3. Run generation script relative to your DNS implementation: `bash create-dnsmasq.sh`.
4. If `combined_output` is set to `true` this will result in a single output file: `lancache.conf` with all your enabled services (applies to Adguard Home, Dnsmasq or Unbound).
5. Copy files from `output/{adguardhome,dnsmasq,rpz,squid,unbound}/*` to the respective locations for Dnsmasq/Unbound.
6. Restart the appropriate service.

### Notes for Dnsmasq users

**This also applies to users utilising the script alongside Pi-hole.**

Multi-IP Lancache setups are only supported with Dnsmasq or Pi-hole versions >= 2.86 or 2021.09 respectively.

### Notes for AdGuard Home users

1. Utilising `"combined_output": true` is more convenient.
2. Once you have run the script and uploaded the file to the appropriate location, you should navigate to Adguard Home -> Filters -> DNS blocklists -> Add blocklist -> Add a custom list.
