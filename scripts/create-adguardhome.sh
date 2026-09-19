#!/bin/bash

basedir=".."
outputdir="output/adguardhome"
cachedomainspath="${basedir}/cache_domains.json"
configfile="config.json"
defaulthomepage="https://github.com/uklans/cache-domains"

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------
if ! command -v jq >/dev/null; then
    echo "This script requires jq to be installed."
    echo "Your package manager should be able to find it."
    exit 1
fi

if ! command -v git >/dev/null; then
    echo "This script requires git to be installed."
    echo "Your package manager should be able to find it."
    exit 1
fi

if ! command -v awk >/dev/null; then
    echo "This script requires awk to be installed."
    echo "Your package manager should be able to find it."
    exit 1
fi

# ---------------------------------------------------------------------------
# Validate required files
# ---------------------------------------------------------------------------
if [[ ! -f ${configfile} ]]; then
    echo "${configfile} not found."
    echo "Copy config.example.json to config.json and adjust it for your environment."
    exit 1
fi

if [[ ! -f ${cachedomainspath} ]]; then
    echo "${cachedomainspath} does not exist."
    exit 1
fi

# ---------------------------------------------------------------------------
# Validate every IPv4 address declared under config.json's "ips" object
# before generating any rules, so a typo doesn't silently end up in output.
# ---------------------------------------------------------------------------
validate_ipv4() {
    local ip="$1"
    if [[ ! ${ip} =~ ^([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})\.([0-9]{1,3})$ ]]; then
        return 1
    fi
    local octet
    for octet in "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}"; do
        if ((octet > 255)); then
            return 1
        fi
    done
    return 0
}

while IFS= read -r ip; do
    if ! validate_ipv4 "${ip}"; then
        echo "Invalid IPv4 address in ${configfile}: ${ip}"
        exit 1
    fi
done < <(jq -r '.ips[] | if type == "array" then .[] else . end' "${configfile}")

# ---------------------------------------------------------------------------
# Header metadata, derived from the repo's latest git commit and remote URL.
# ---------------------------------------------------------------------------
lastmodified=$(git -C "${basedir}" log -1 --date=iso8601-strict --format=%cd)

if [[ -z ${lastmodified} ]]; then
    echo "Unable to determine last modified date from git."
    exit 1
fi

# Resolve the Homepage URL from the cache-domains repo's "origin" remote,
# normalizing SSH-style URLs (git@host:path.git, ssh://git@host/path.git) to
# HTTPS, and stripping a trailing ".git". Falls back to the known upstream
# URL if no remote is configured.
homepage=$(git -C "${basedir}" remote get-url origin 2>/dev/null)
if [[ -z ${homepage} ]]; then
    homepage="${defaulthomepage}"
else
    homepage="${homepage%.git}"
    if [[ ${homepage} =~ ^git@([^:]+):(.+)$ ]]; then
        homepage="https://${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    elif [[ ${homepage} =~ ^ssh://git@([^/]+)/(.+)$ ]]; then
        homepage="https://${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    fi
fi

# Writes the AdGuard comment header to a freshly created output file.
write_header() {
    {
        echo "!"
				echo "! Title: LanCache DNS rewrite"
        echo "! Description: AdGuard DNS filtering rules for redirecting download requests to LanCache caching proxy server."
        echo "! Version: ${lastmodified}"
        echo "! Homepage: ${homepage}"
        echo "! Last modified: ${lastmodified}"
        echo "!"
    } >"$1"
}

# ---------------------------------------------------------------------------
# Determine combined vs. per-file output mode ONCE, up front, so the main
# loop can pick its write target without re-checking this every iteration.
# ---------------------------------------------------------------------------
combinedoutput=$(jq -r ".combined_output" "${configfile}")
combinedfile="${outputdir}/lancache.txt"

# ---------------------------------------------------------------------------
# Reset output directory
# ---------------------------------------------------------------------------

rm -rf "${outputdir}"
mkdir -p "${outputdir}"

if [[ ${combinedoutput} == "true" ]]; then
    write_header "${combinedfile}"
fi

# awk program shared by both output modes. Handles wildcard ("*.") prefixing,
# skips comments/blank lines, trims trailing \r (CRLF domain files), expands
# one or more cache-server IPs per domain, AND de-duplicates rules generated
# WITHIN THIS SINGLE INVOCATION (i.e. duplicate lines inside one domain
# file) - all in one pass, at no extra I/O cost. This is sufficient for
# non-combined mode, where each output file is written by exactly one such
# invocation. Combined mode additionally needs a cross-invocation dedup pass
# (see dedup_file below), since multiple domain files are appended into the
# same shared lancache.txt.
#
# Example transformation (ips="10.0.0.1"):
#   input line:  *.blizzard.com
#   -> ||blizzard.com^$dnsrewrite=10.0.0.1
#   -> ||blizzard.com^$dnstype=AAAA
#
#   input line:  eu.actual.battle.net
#   -> |eu.actual.battle.net^$dnsrewrite=10.0.0.1
#   -> |eu.actual.battle.net^$dnstype=AAAA
read -r -d '' RULE_AWK << 'AWK'
BEGIN {
    n = split(ips, iplist, ",")
}
/^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
{
    line = $0
    # Trim leading/trailing whitespace AND trailing \r (CRLF line endings),
    # otherwise the stray \r ends up embedded in the generated rule and can
    # make output look "split" across lines when viewed in a terminal.
    gsub(/^[ \t]+|[ \t\r]+$/, "", line)
    # "*.example.com" -> "||example.com" (matches the domain AND all of its
    # subdomains). Anything without a leading "*." is treated as an exact
    # host and gets the narrower "|example.com" (exact match only) prefix.
    prefix = "|"
    if (line ~ /^\*\./) {
        prefix = "||"
        sub(/^\*\./, "", line)
    }
    rewritekey = prefix line "^$dnsrewrite"
    if (rewritekey in seen) next
    seen[rewritekey] = 1
    for (i = 1; i <= n; i++) {
        print prefix line "^$dnsrewrite=" iplist[i]
        print prefix line "^$dnstype=AAAA"
    }
}
AWK

# Removes exact duplicate lines from a file in a single linear pass.
# Only needed for combined mode - see comment on RULE_AWK above.
# Usage: dedup_file <file>
dedup_file() {
    awk '!seen[$0]++' "$1" >"$1.tmp" && mv "$1.tmp" "$1"
}

# ---------------------------------------------------------------------------
# Generate rules: a single jq call joins cache_domains.json with config.json
# (via --slurpfile) and streams "name<TAB>ips<TAB>comma-joined domain_files<TAB>description"
# for every domain that resolves to an enabled group.
# ---------------------------------------------------------------------------
while IFS=$'\t' read -r name ips domainfilescsv description; do
    IFS=',' read -r -a files <<<"${domainfilescsv}"
    for filename in "${files[@]}"; do
        domainfile="${basedir}/${filename}"

        if [[ ! -f ${domainfile} ]]; then
            echo "${domainfile} doesn't exist."
            continue
        fi

        # Section separator, e.g.:
        #   ! === Blizzard ===
        #   ! CDN for Blizzard/Battle.net
        f=${filename%.txt}
        section="! === ${f^} ==="
        if [[ -n ${description} ]]; then
            section+=$'\n'"! ${description}"
        fi

        if [[ ${combinedoutput} == "true" ]]; then
            # Write straight into the shared combined file - no intermediate
            # per-domain-file .txt files, no later merge/delete pass.
            echo "${section}" >>"${combinedfile}"
            sort "${domainfile}" | awk -v ips="${ips}" "${RULE_AWK}" >>"${combinedfile}"
        else
            outputfile="${outputdir}/${filename}"

            if [[ ! -f ${outputfile} ]]; then
                write_header "${outputfile}"
            fi

            echo "${section}" >>"${outputfile}"
            sort "${domainfile}" | awk -v ips="${ips}" "${RULE_AWK}" >>"${outputfile}"
        fi
    done
done < <(jq -r --slurpfile config "${configfile}" '
    ($config[0].ips) as $ips |
    ($config[0].cache_domains) as $groups |
    .cache_domains[] |
    ( $groups[.name] // $groups.default // empty ) as $group |
    select($group != null and $group != "" and $group != "disabled") |
    ( $ips[$group] // empty ) as $iplist |
    select($iplist != null and $iplist != "") |
    [
        .name,
        (if ($iplist | type) == "array" then ($iplist | join(",")) else $iplist end),
        (.domain_files | join(",")),
        (.description // "")
    ] | @tsv
' "${cachedomainspath}")

# ---------------------------------------------------------------------------
# Cross-file de-duplication, ONLY for combined mode (see RULE_AWK comment).
# ---------------------------------------------------------------------------
if [[ ${combinedoutput} == "true" ]]; then
    dedup_file "${combinedfile}"
fi

echo "Configuration generation completed."
echo ""
echo "Please copy the following files:"
echo "- ./${outputdir}/*.txt to /opt/adguardhome/work/userfilters/"
echo "- Navigate to Adguard Home -> Filters -> DNS blocklists -> Add blocklist -> Add a custom list"
