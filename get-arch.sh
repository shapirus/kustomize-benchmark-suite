#!/bin/bash

ARCH=$(uname -m)
if [[ $ARCH == "arm64" || $ARCH == "aarch64" ]]; then
	URI_ARCH="arm64"
	VERSIONS="$VERSIONS_ARM64"
else
	URI_ARCH="amd64"
	VERSIONS="$VERSIONS_X86_64"
fi
