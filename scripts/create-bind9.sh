#!/bin/bash
basedir=".."
outputdir="output/bind9"
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
	ip=$(jq ".ips[\"${line}\"]" config.json)
	declare "cacheip$line"="$ip"
done <<< $(jq -r '.ips | to_entries[] | .key' config.json)

while read line; do 
	name=$(jq -r ".cache_domains[\"${line}\"]" config.json)
	declare "cachename$line"="$name"
done <<< $(jq -r '.cache_domains | to_entries[] | .key' config.json)

rm -rf ${outputdir}
mkdir -p ${outputdir}

outputfile=${outputdir}/db.rpz

cat <<"EOF" >${outputfile}
;
; BIND response policy zone
;
$TTL 60
@   IN  SOA localhost.  root.localhost. (
                  1     ; Serial
                 60     ; Refresh
                 60     ; Retry
            2419200     ; Expire
             604800 )   ; Negative Cache TTL
;
@   IN  NS  localhost.
;
EOF

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
	cacheip=$(jq -r 'if type == "array" then .[] else . end' <<< ${!cacheipname} | xargs)

	echo "; ${key}" >> ${outputfile}
	while read fileid; do
		while read filename; do
			#echo "${basedir}/$filename"
			while read fileentry; do
				# Ignore comments and newlines
				if [[ $fileentry == \#* ]] || [[ -z $fileentry ]]; then
					continue
				fi
				for i in ${cacheip}; do
					echo "${fileentry} A ${i}" >> ${outputfile}
				done
			done <<< $(cat ${basedir}/$filename | sort);
		done <<< $(jq -r ".cache_domains[$entry].domain_files[$fileid]" $path)
	done <<< $(jq -r ".cache_domains[$entry].domain_files | to_entries[] | .key" $path)
done <<< $(jq -r '.cache_domains | to_entries[] | .key' $path)

cat << EOF
Configuration generation completed.

Please copy the following files, and enable Response Policy Zone
- ./${outputdir}/db.rpz
EOF
