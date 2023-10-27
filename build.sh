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
	git checkout $revision
	revision=$(echo "$revision" | sed 's@^kustomize/@@')
	cd kustomize
	go mod tidy
	CGO_ENABLED=0 GO111MODULE=on go build -ldflags="-s -X sigs.k8s.io/kustomize/api/provenance.version=$revision -X sigs.k8s.io/kustomize/api/provenance.buildDate=$(date -Iseconds)"
	mv kustomize $BINDIR/kustomize-$revision
	rm -rf $BUILDDIR
}

BINDIR=$PWD/binaries
mkdir $BINDIR

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
