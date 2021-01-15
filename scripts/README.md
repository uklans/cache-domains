# DNS Generation Scripts

## Introduction

The respective shell scripts contained within this directory can be utilised to generate application specific compliant
configuration which can be utilised with:

* Dnsmasq
* Unbound

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

If utilising the `create-dnsmasq.sh` the generation script will create a `lancache.conf` which also loads in the respective `*.hosts` files.

The `lancache.conf` should be copied into the `/etc/dnsmasq.d/` location but also will need to be modified to point to the respective location of the `*.hosts` files.

You can copy the `*.hosts` file to any location other than `/etc/dnsmasq.d/` as this location is utilised only for `*.conf` files.

For example if utilising Pi-hole a user can copy the `*.hosts` files to `/etc/pihole/` and modify the `lancache.conf` with the following command, prior to copying it to `/etc/dnsmasq.d/`:
`sed -i 's/dnsmasq\/hosts/pihole/g' output/dnsmasq/lancache.conf`