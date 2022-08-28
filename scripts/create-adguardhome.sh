#!/bin/bash
basedir=".."
outputdir="output/adguardhome"
path="${basedir}/cache_domains.json"

export IFS=' '

test=$(which jq);
out=$?
if [ $out -gt 0 ] ; then
        echo "This script requires jq to be installed."
        echo "Your package manager should be able to find it"
        exit 1
fi

cachenamedefault="disabled"

while read -r line; do
        ip=$(jq ".ips[\"${line}\"]" config.json)
        declare "cacheip${line}"="${ip}"
done <<< $(jq -r '.ips | to_entries[] | .key' config.json)

agh_upstreams=$(jq -r ".ips[\"adguardhome_upstream\"] | .[]" config.json)

while read -r line; do
        name=$(jq -r ".cache_domains[\"${line}\"]" config.json)
        declare "cachename${line}"="${name}"
done <<< $(jq -r '.cache_domains | to_entries[] | .key' config.json)

rm -rf ${outputdir}
mkdir -p ${outputdir}

# add upstreams
echo "${agh_upstreams}" >> "${outputdir}/cache-domains.txt"

while read -r entry; do
        unset cacheip
        unset cachename
        key=$(jq -r ".cache_domains[$entry].name" $path)
        cachename="cachename${key}"
        if [ -z "${!cachename}" ]; then
                cachename="cachenamedefault"
        fi
        if [[ ${!cachename} == "disabled" ]]; then
                continue;
        fi
        cacheipname="cacheip${!cachename}"
        cacheip=$(jq -r 'if type == "array" then .[] else . end' <<< ${!cacheipname} | xargs)
        while read -r fileid; do
                while read -r filename; do
                        destfilename="cache-domains.txt"  #$(echo $filename | sed -e 's/txt/conf/')
                        outputfile=${outputdir}/${destfilename}
                        touch ${outputfile}
                        while read -r fileentry; do
                                # Ignore comments, newlines and wildcards
                                if [[ ${fileentry} == \#* ]] || [[ -z ${fileentry} ]]; then
                                        continue
                                fi
                                parsed=$(echo ${fileentry} | sed -e "s/^\*\.//")
                                for i in ${cacheip}; do
                                        if grep -qx "\[/${parsed}/\]${i}" "${outputfile}"; then
                                                continue
                                        fi
                                        echo "[/${parsed}/]${i}" >> "${outputfile}"
                                done
                        done <<< $(cat ${basedir}/${filename} | sort);
                done <<< $(jq -r ".cache_domains[${entry}].domain_files[$fileid]" ${path})
        done <<< $(jq -r ".cache_domains[${entry}].domain_files | to_entries[] | .key" ${path})
done <<< $(jq -r '.cache_domains | to_entries[] | .key' ${path})

cat << EOF
Configuration generation completed.

Please point the setting upstream_dns_file in AdGuardHome.yaml to the generated file.
For example:
upstream_dns_file: "/root/cache-domains/scripts/output/adguardhome/cache-domains.txt"
EOF