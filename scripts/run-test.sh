#!/bin/bash

set -e

. get-arch.sh

iterations=${ITERATIONS:-200}

function get_version
{
	local binary=$1

	local version=
	local raw=$($binary version)
	if [[ "$raw" =~ '{Version:kustomize/' ]]; then
		version=$(echo "$raw"|sed -r 's/\{Version:kustomize\/([^ ]+).*$/\1/')
	elif [[ "$raw" =~ '{Version:' ]]; then
		version=$(echo "$raw"|sed -r 's/\{Version:([^ ]+).*$/\1/')
	else
		version="$raw"
	fi
	echo $version
}

TESTS=$(ls tests | sort | while read test; do echo -n "$test ";done)

echo -e "\033[1;35mStarting kustomize benchmark on \033[0;32m$(uname -s -m)"
echo -e "\033[1;35mkustomize versions: \033[0;36m$(echo;for v in $VERSIONS;do printf '  %s\n' $v;done)"
echo -e "\033[1;35miterations per test: \033[0;32m$iterations"
echo -e "\033[1;35mtests: \033[0;36m$(echo;for t in $TESTS;do printf '  %s\n' $t;done)"
echo -e "\033[1;35mtime unit: \033[0;32mseconds"
echo -e "\033[0m"

printf "\033[1;35m%10s"
i=0
for t in $TESTS; do
	let i=i+1
	printf "%10s" "test: $i"
done
echo -e "\033[0m"

EXIT_REQ=0
trap EXIT_REQ=1 INT

for ver in $VERSIONS; do
	ver=$(echo "$ver" | sed 's@^kustomize/@@')
	binary=binaries/kustomize-$ver
	version=$(get_version $binary)
	printf "\033[1;35m%10s\033[0m" $version
	for test in $TESTS; do
		TIMEFORMAT=%2R
		set +e
		duration=$(
			(time for ((i = 0; i < $iterations && $? == 0; i++)) \
			do
				$binary build tests/$test &>/dev/null
			done) 2>&1
		)
		if [ $? != 0 ]; then
			duration="(fail)"
		fi
		if [ $EXIT_REQ == 1 ]; then
			echo -e "\033[0mExiting on SIGINT"
			exit 1
		fi
		set -e
		printf "\033[0;36m%10s\033[0m" $duration
	done
	echo
done
echo
