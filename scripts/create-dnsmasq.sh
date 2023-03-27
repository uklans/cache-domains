#!/bin/bash
basedir=".."
outputdir="output/dnsmasq"
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

while read -r line; do
        name=$(jq -r ".cache_domains[\"${line}\"]" config.json)
        declare "cachename${line}"="${name}"
done <<< $(jq -r '.cache_domains | to_entries[] | .key' config.json)

rm -rf ${outputdir}
mkdir -p ${outputdir}
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
                        destfilename=$(echo $filename | sed -e 's/txt/conf/')
                        outputfile=${outputdir}/${destfilename}
                        touch ${outputfile}
                        while read -r fileentry; do
                                # Ignore comments, newlines and wildcards
                                if [[ ${fileentry} == \#* ]] || [[ -z ${fileentry} ]]; then
                                        continue
                                fi
                                parsed=$(echo ${fileentry} | sed -e "s/^\*\.//")
                                for i in ${cacheip}; do
                                        if ! grep -qx "address=/${parsed}/${i}" "${outputfile}"; then
                                                echo "address=/${parsed}/${i}" >> "${outputfile}"
                                        fi
                                        if ! grep -qx "local=/${parsed}/" "${outputfile}"; then
                                                echo "local=/${parsed}/" >> "${outputfile}"
                                        fi
                                done
                        done <<< $(cat ${basedir}/${filename} | sort);
                done <<< $(jq -r ".cache_domains[${entry}].domain_files[$fileid]" ${path})
        done <<< $(jq -r ".cache_domains[${entry}].domain_files | to_entries[] | .key" ${path})
done <<< $(jq -r '.cache_domains | to_entries[] | .key' ${path})

cat << EOF
Configuration generation completed.

Please copy the following files:
- ./${outputdir}/*.conf to /etc/dnsmasq/dnsmasq.d/
EOF
