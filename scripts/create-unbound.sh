#!/bin/bash
basedir=".."
outputdir="output/unbound"
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

while read line; do
	linecount=$(jq -r ".ips[\"${line}\"]" config.json |wc -l)
	if [[ $linecount -eq 1 ]]; then
		ip=$(jq -r ".ips[\"${line}\"]" config.json)
	else
		ip=$(jq -r ".ips[\"${line}\"][]" config.json |tr '\n' ' ')
	fi
	declare "cacheip$line"="$ip"
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
	key=$(jq -r ".cache_domains[$entry].name" $path)
	cachename="cachename${key}"
	if [ -z "${!cachename}" ]; then
		cachename="cachenamedefault"
	fi
	if [[ ${!cachename} == "disabled" ]]; then
		continue;
	fi
	cacheipname="cacheip${!cachename}"
	cacheip=${!cacheipname}
	while read fileid; do
		while read filename; do
			destfilename=$(echo $filename | sed -e 's/txt/conf/')
			outputfile=${outputdir}/${destfilename}
			touch $outputfile
			echo "server:" >> $outputfile
			while read fileentry; do
				# Ignore comments
				if [[ $fileentry == \#* ]]; then
					continue
				fi
				parsed=$(echo $fileentry | sed -e "s/^\*\.//")
				if grep -q "$parsed" $outputfile; then
					continue
				fi
				echo "  local-zone: \"${parsed}\" redirect" >> $outputfile
				cacheiplist=($cacheip)
				for i in "${cacheiplist[@]}"; do
					echo "  local-data: \"${parsed} 30 IN A ${i}\"" >> $outputfile
				done
			done <<< $(cat ${basedir}/$filename);
		done <<< $(jq -r ".cache_domains[$entry].domain_files[$fileid]" $path)
	done <<< $(jq -r ".cache_domains[$entry].domain_files | to_entries[] | .key" $path)
done <<< $(jq -r '.cache_domains | to_entries[] | .key' $path)
