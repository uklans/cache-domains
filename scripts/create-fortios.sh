#!/bin/bash
basedir=".."
outputdir="output/fortios"
path="${basedir}/cache_domains.json"

export IFS=' '

test=$(which jq);
if [ $? -gt 0 ] ; then
    echo "This script requires jq to be installed."
    echo "Your package manager should be able to find it"
    exit 1
fi

cachenamedefault="disabled"
combinedoutput=$(jq -r ".combined_output" config.json)

while read line; do
    ip=$(jq ".ips[\"${line}\"]" config.json)
    declare "cacheip${line}"="${ip}"
done <<< $(jq -r '.ips | to_entries[] | .key' config.json)

while read line; do
    name=$(jq -r ".cache_domains[\"${line}\"]" config.json)
    declare "cachename$line"="$name"
done <<< $(jq -r '.cache_domains | to_entries[] | .key' config.json)

rm -rf ${outputdir}
mkdir -p ${outputdir}
while read entry; do
    unset cacheip
    unset cachename
    key=$(jq -r ".cache_domains[$entry].name" ${path})
    cachename="cachename${key}"
    if [ -z "${!cachename}" ]; then
        cachename="cachenamedefault"
    fi
    if [[ ${!cachename} == "disabled" ]]; then
        continue;
    fi
    cacheipname="cacheip${!cachename}"
    cacheip=$(jq -r 'if type == "array" then .[] else . end' <<< ${!cacheipname} | xargs)
    while read fileid; do
        while read filename; do
            destfilename=$(echo ${filename} | sed -e 's/txt/conf/')
            outputfile=${outputdir}/${destfilename}
            touch ${outputfile}
            tab="    "
            echo "config system dns-database" >> ${outputfile}
            while read fileentry; do
                # Ignore comments and newlines
                if [[ ${fileentry} == \#* ]] || [[ -z ${fileentry} ]]; then
                    continue
                fi
                parsed=$(echo ${fileentry} | sed -e "s/^\*\.//")
                echo -e "${tab}edit \"${parsed}\"\n${tab}${tab}set domain \"${parsed}\"\n${tab}${tab}set authoritative disable\n${tab}${tab}config dns-entry" >> ${outputfile}
                j=1
                for i in ${cacheip}; do
                    echo -e "${tab}${tab}${tab}edit ${j}\n${tab}${tab}${tab}${tab}set hostname \"@\"\n${tab}${tab}${tab}${tab}set ip ${i}\n${tab}${tab}${tab}next" >> ${outputfile}
                    j=$((j+1))
                done
                echo -e "${tab}${tab}end\n${tab}next" >> ${outputfile}
            done <<< $(cat ${basedir}/$filename | sort);
        done <<< $(jq -r ".cache_domains[${entry}].domain_files[${fileid}]" ${path})
    done <<< $(jq -r ".cache_domains[${entry}].domain_files | to_entries[] | .key" ${path})
    echo "end" >> ${outputfile}
done <<< $(jq -r '.cache_domains | to_entries[] | .key' ${path})
if [[ ${combinedoutput} == "true" ]]; then
    for file in ${outputdir}/*; do f=${file//${outputdir}\/} && f=${f//.conf} && echo -e "# ${f}" >> ${outputdir}/lancache.conf && cat ${file} >> ${outputdir}/lancache.conf && rm ${file}; done
fi

cat << EOF
Configuration generation completed.

Please paste the contents of the following files:
- ./${outputdir}/*.conf to the FortiOS CLI
- Paste the configuration of each service or utilise the combined output for a single list
EOF
