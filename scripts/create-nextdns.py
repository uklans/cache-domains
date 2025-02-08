#!/usr/bin/env python3

import json
import os
import random
import sys
import time
import urllib.error
import urllib.request

# Configuration
CACHE_DOMAINS_JSON = "cache_domains.json"

# Timing / Retry configuration
DELAY_SECONDS = 1  # delay between requests
MAX_RETRIES = 5  # maximum retries if rate limited
BACKOFF_FACTOR = 2  # exponential backoff multiplier
USER_AGENT = "python-requests/2.31.0"  # for some reason, Cloudflare will block urllib's default user-agent


def post_redirect(base_url, api_key, payload):
    """Post a redirect entry using urllib.request. Implements retry logic if rate limited (429) is encountered."""
    headers = {
        "X-Api-Key": api_key,
        "Content-Type": "application/json",
        "User-Agent": USER_AGENT,
    }
    data = json.dumps(payload).encode("utf-8")
    retries = 0
    current_delay = DELAY_SECONDS

    while retries <= MAX_RETRIES:
        req = urllib.request.Request(
            url=base_url, data=data, headers=headers, method="POST"
        )
        try:
            with urllib.request.urlopen(req) as response:
                status_code = response.getcode()
                if status_code in [200, 201]:
                    return True, response.read().decode("utf-8")
                else:
                    # For non-success status codes (other than 429)
                    return False, f"Unexpected status code: {status_code}"
        except urllib.error.HTTPError as e:
            if e.code == 429:
                print(f"[*] Rate limited, waiting for {current_delay} seconds ...")
                time.sleep(current_delay)
                retries += 1
                current_delay *= BACKOFF_FACTOR
            else:
                try:
                    error_body = e.read().decode("utf-8")
                except Exception:
                    error_body = "No response body"
                return False, f"HTTPError {e.code}, response: {error_body}"
        except urllib.error.URLError as e:
            return False, f"URLError: {e.reason}"

    return False, "Max retries exceeded"


def run(profile_id, api_key, redirect_ip):
    base_url = f"https://api.nextdns.io/profiles/{profile_id}/rewrites/"

    # Read cache_domains.json
    try:
        with open(CACHE_DOMAINS_JSON, "r") as f:
            cache_data = json.load(f)
    except Exception as e:
        print(f"[-] Failed to load {CACHE_DOMAINS_JSON}: {e}")
        return

    # Set to deduplicate domains
    all_domains = set()

    # Process each CDN entry in the JSON
    for entry in cache_data.get("cache_domains", []):
        domain_files = entry.get("domain_files", [])
        for file_name in domain_files:
            if os.path.exists(file_name):
                with open(file_name, "r") as file:
                    # Read each line; ignore blank lines or comment lines
                    for line in file:
                        line = line.strip()
                        if not line or line.startswith("#") or line.startswith("//"):
                            continue
                        all_domains.add(line.lstrip("*."))
            else:
                print(f"[-] File '{file_name}' not found, skipping ...")

    print("[*] Collected domains:")
    for domain in sorted(all_domains):
        print(f"  - {domain}")

    # Retrieve the existing rewrite entries from NextDNS API
    headers = {
        "X-Api-Key": api_key,
        "User-Agent": USER_AGENT,
    }
    req = urllib.request.Request(url=base_url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req) as response:
            if response.getcode() != 200:
                resp_body = response.read().decode("utf-8")
                print(
                    f"[-] Failed to get existing redirects, status code: {response.getcode()}, response: {resp_body}"
                )
                return
            resp_data = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        try:
            error_body = e.read().decode("utf-8")
        except Exception:
            error_body = "No response body"
        print(
            f"[-] Failed to get existing redirects, status code: {e.code}, response: {error_body}"
        )
        return
    except urllib.error.URLError as e:
        print(f"[-] Failed to get existing redirects, URLError: {e.reason}")
        return

    data = resp_data.get("data", [])
    existing_domains = {entry.get("name") for entry in data}
    print("\n[*] Existing domains:")
    for domain in sorted(existing_domains):
        print(f"  - {domain}")

    # For each domain, if missing in NextDNS, post a new redirect
    for domain in all_domains:
        if domain in existing_domains:
            print(f"[*] Domain '{domain}' already exists, skipping...")
            continue

        payload = {
            "name": domain,
            "content": redirect_ip,
        }

        print(f"[+] Adding '{domain}'...")
        success, post_resp = post_redirect(base_url, api_key, payload)
        if not success:
            print(f"[-] Failed to add redirect for '{domain}', response: {post_resp}")

        # Delay between API calls to prevent triggering rate limits
        time.sleep(DELAY_SECONDS + random.uniform(0, 1))

    print("\n[+] Done!")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: create-nextdns.py <profile_id> <api_key> <redirect_ip>")
        sys.exit(1)

    profile_id = sys.argv[1]
    api_key = sys.argv[2]
    redirect_ip = sys.argv[3]

    run(profile_id, api_key, redirect_ip)
