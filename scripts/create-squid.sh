#!/bin/bash
basedir=".."
outputdir="output/squid"
path="${basedir}/cache_domains.json"
REGEX="^\\*\\.(.*)$"

export IFS=" "

if ! command -v jq >/dev/null; then
	cat <<-EOF
		This script requires jq to be installed.
		Your package manager should be able to find it
	EOF
	exit 1
fi

while read -r line; do
	name=$(jq -r ".cache_domains[\"${line}\"]" config.json)
	declare "cachename${line}"="${name}"
done <<<"$(jq -r ".cache_domains | to_entries[] | .key" config.json)"

rm -rf ${outputdir}
mkdir -p ${outputdir}
while read -r entry; do
	unset cachename
	key=$(jq -r ".cache_domains[$entry].name" ${path})
	cachename="cachename${key}"
	if [ -z "${!cachename}" ]; then
		cachename="cachenamedefault"
	fi
	if [[ ${cachename} == "disabled" ]]; then
		continue
	fi
	while read -r fileid; do
		while read -r filename; do
			destfilename=${!cachename}.txt
			outputfile=${outputdir}/${destfilename}
			touch "${outputfile}"
			while read -r fileentry; do
				# Ignore comments
				if [[ ${fileentry} == \#* ]] || [[ -z ${fileentry} ]]; then
					continue
				fi
				# Ha wildcards to squid wildcards
				parsed="${fileentry#\*}"
				# If we have cdn.thing and *.cdn.thing in cache_domains
				# Squid requires ONLY cdn.thing
				#
				# If the fileentry starts with *.cdn.thing
				if [[ ${fileentry} =~ $REGEX ]]; then
					# Does the cache_domains file also contain cdn.thing
					if grep "${BASH_REMATCH[1]}" ${basedir}/"${filename}" | grep -v "${fileentry}" >/dev/null; then
						# Skip *.cdn.thing as cdn.thing will be collected earlier/later
						continue
					fi
				fi
				echo "${parsed}" >>"${outputfile}"
			done <<<"$(cat ${basedir}/"${filename}" | sort)"
		done <<<"$(jq -r ".cache_domains[${entry}].domain_files[${fileid}]" ${path})"
	done <<<"$(jq -r ".cache_domains[${entry}].domain_files | to_entries[] | .key" ${path})"
done <<<"$(jq -r ".cache_domains | to_entries[] | .key" ${path})"

cat <<EOF
Configuration generation completed.

Please copy the following files:
- ./${outputdir}/*.txt to /etc/squid/domains/
EOF
