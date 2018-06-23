#!/bin/bash
basedir=".."
outputdir="output/squid"
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
	ip=$(jq -r ".ips[\"${line}\"]" config.json)
	declare "cacheip$line"="$ip"
done <<< $(jq -r '.ips | to_entries[] | .key' config.json)

while read line; do 
	name=$(jq -r ".cache_domains[\"${line}\"]" config.json)
	declare "cachename$line"="$name"
done <<< $(jq -r '.cache_domains | to_entries[] | .key' config.json)

pareintid=0
rm -rf ${outputdir}
mkdir -p ${outputdir}
while read entry; do 
	unset cacheip
	unset cachename
	conffile=${outputdir}/cache-domains.conf
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
			destfilename=$(echo $filename | sed -e 's/txt/list/')
			destlistname=$(echo $filename | sed -e 's/\.txt//')
			outputfile=${outputdir}/${destfilename}
			touch $outputfile
			while read fileentry; do
				# Ignore comments
				if [[ $fileentry == \#* ]]; then
					continue
				fi
				parsed=$(echo $fileentry | sed -e "s/^\*\././")
				if grep -q "$parsed" $outputfile; then
					continue
				fi
				echo "${parsed}" >> $outputfile
			done <<< $(cat ${basedir}/$filename);

			echo "# ${destlistname}" >> $conffile
			echo "acl ${destlistname}_servers dstdomain \"${destlistname}.list\"" >> $conffile
			echo "cache_peer ${cacheip} parent ${parentid} 0 no-query originserver no-digest no-netdb-exchange name=${destlistname}-cache" >> $conffile
			echo "cache_peer_access ${destlistname}-cache allow ${destlistname}_servers" >> $conffile
			echo "cache_peer_access ${destlistname}-cache deny all" >> $conffile
			echo "" >> $conffile
			((parentid+=1))
		done <<< $(jq -r ".cache_domains[$entry].domain_files[$fileid]" $path)
	done <<< $(jq -r ".cache_domains[$entry].domain_files | to_entries[] | .key" $path)
done <<< $(jq -r '.cache_domains | to_entries[] | .key' $path)
