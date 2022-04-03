#!/bin/bash
basedir=".."
outputdir="output/rpz"
path="${basedir}/cache_domains.json"
basedomain=${1:-lancache.net}

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
outputfile=${outputdir}/db.rpz.$basedomain
cat > $outputfile << EOF
\$TTL 60 ; default TTL
\$ORIGIN rpz.$basedomain.
@       SOA     ns1.$basedomain. admin.$basedomain. (
		$(date +%Y%m%d01) ; serial
                604800     ; refresh (1 week)
                600      ; retry (10 mins)
                600      ; expire (10 mins)
                600      ; minimum (10 mins)
                )
        NS      ns1.$basedomain.
        NS      ns2.$basedomain.

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
	while read fileid; do
		while read filename; do
			echo "" >> $outputfile
			echo "; $(echo $filename | sed -e 's/.txt$//')" >> $outputfile
			destfilename=$(echo $filename | sed -e 's/txt/conf/')
			while read fileentry; do
				# Ignore comments and newlines
				if [[ $fileentry == \#* ]] || [[ -z $fileentry ]]; then
					continue
				fi
				parsed=$(echo $fileentry)
				if grep -qx "^\"${parsed}\". " $outputfile; then
					continue
				fi
				t=""
				for i in ${cacheip}; do
					# only one cname per domain is allowed
					if [[ ${t} = "CNAME" ]]; then
						continue
					fi
					# for cnames you must use a fqdn with trailing dot
					t="CNAME"
					if [[ ${i} =~ ^[0-9\.]+$ ]] ; then
						t="A"
					elif [[ ! ${i} =~ \.$ ]] ; then
						i="${i}."
					fi
					printf "%-50s IN %s %s\n" \
						"${parsed}" \
						"${t}" \
						"${i}" \
						>> $outputfile
				done
			done <<< $(cat ${basedir}/$filename | sort);
		done <<< $(jq -r ".cache_domains[$entry].domain_files[$fileid]" $path)
	done <<< $(jq -r ".cache_domains[$entry].domain_files | to_entries[] | .key" $path)
done <<< $(jq -r '.cache_domains | to_entries[] | .key' $path)

cat << EOF
Configuration generation completed.

Please include the rpz zone in your bind configuration"
- cp $outputfile /etc/bind
- configure the zone and use it

options {
    [...]
    response-policy {zone "rpz.$basedomain";};
    [...]
}
zone "rpz.$basedomain" {
    type master;
    file "/etc/bind/db.rpz.$basedomain";
};
EOF
