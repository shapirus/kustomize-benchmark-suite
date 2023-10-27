#!/bin/bash

set -euxo pipefail

. get-arch.sh

export HOME=$(mktemp -d)

function download
{
	local ver=$1

	temp=$(mktemp -d) \
	&& (
		cd $temp \
		&& wget -nv https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv$ver/kustomize_v${ver}_linux_${URI_ARCH}.tar.gz -O tmp.tar.gz \
		&& tar xzf tmp.tar.gz \
		&& rm tmp.tar.gz \
		&& if [ -f output/kustomize ]; then path=output; else path='.'; fi && mv $path/kustomize $BINDIR/kustomize-$ver \
	) \
	&& rm -rf $temp
}

function install_gh_cli
{
	mkdir -p $HOME/bin
	local TMPDIR=$(mktemp -d)
	(
		cd $TMPDIR
		wget -nv https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/gh_${GH_CLI_VERSION}_linux_${URI_ARCH}.tar.gz -O gh_${GH_CLI_VERSION}_linux_${URI_ARCH}.tar.gz
		tar xzf gh_${GH_CLI_VERSION}_linux_${URI_ARCH}.tar.gz
		mv gh_${GH_CLI_VERSION}_linux_${URI_ARCH}/bin/gh $HOME/bin
		chmod a+x $HOME/bin/gh
	)
	rm -rf $TMPDIR
}

function build
{
	local revision=$1
	if [ ! -v GITDIR ]; then
		apk add go git
		GITDIR=$(mktemp -d)
		git clone https://github.com/kubernetes-sigs/kustomize.git $GITDIR
	fi
	BUILDDIR=$(mktemp -d)
	cp -a $GITDIR/. $BUILDDIR
	cd $BUILDDIR

	# support building pull requests: requires installing the github cli utility
	if [[ $revision =~ ^PR-[0-9] ]]; then
		if [ ! -v GH_CLI_INSTALLED ]; then
			install_gh_cli
		fi
		$HOME/bin/gh pr checkout $(echo "$revision" | sed 's/^PR-//')
	else
		git checkout $revision
	fi

	revision=$(echo "$revision" | sed 's@^kustomize/@@')
	cd kustomize
	go mod tidy
	CGO_ENABLED=0 GO111MODULE=on go build -ldflags="-s -X sigs.k8s.io/kustomize/api/provenance.version=$revision -X sigs.k8s.io/kustomize/api/provenance.buildDate=$(date -Iseconds)"
	mv kustomize $BINDIR/kustomize-$revision
	rm -rf $BUILDDIR
}

BINDIR=$PWD/binaries
mkdir $BINDIR

if [ -z "${VERSIONS:-}" ] ; then
	echo "ERROR: build variable VERSIONS must be defined" >&2
	exit 1
fi

for ver in $VERSIONS; do \
	if [[ $ver =~ ^[0-9]\.[0-9]\.[0-9] ]]; then
		download $ver
	else
		build $ver
	fi
done

if [ -v GITDIR ]; then
	cd /
	apk del go git
	apk cache --purge || true
	rm -rf $HOME
fi
